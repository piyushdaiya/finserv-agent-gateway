#!/bin/bash
# Deterministic P1 security baseline. PRE-000 executes before production Go code
# exists, so future gates are deferred only until their owning implementation
# target exists. They are never declared permanently NOT_REQUIRED.

EXPECTED_REPOSITORY="${HAEP_EXPECTED_REPOSITORY:-}"
EXPECTED_HEAD_SHA="${HAEP_EXPECTED_HEAD_SHA:-}"
EXPECTED_BASE_SHA="${HAEP_EXPECTED_BASE_SHA:-}"
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
TMP="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/p1-security-baseline"
mkdir -p "$TMP"

fail() {
  echo "P1_SECURITY_BASELINE=FAIL"
  echo "P1_SECURITY_BASELINE_FAILURE=$1"
  exit 7
}

need_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "MANDATORY_TOOL_MISSING_$1"
}

need_tool git
need_tool python3
need_tool go
need_tool gofmt
need_tool staticcheck
need_tool govulncheck
need_tool gosec
need_tool gitleaks
need_tool syft
need_tool sha256sum

cd "$ROOT" || fail "WORKSPACE_CD_FAILED"

/bin/bash scripts/ci/bootstrap-source.sh
RC=$?
[ "$RC" -eq 0 ] || fail "SOURCE_BOOTSTRAP_BINDING_FAILED"

# Exact qualified tool versions remain mandatory even in pre-code mode.
[ "$(go version | awk '{print $3}')" = "go1.26.7" ] || fail "GO_VERSION_MISMATCH"
staticcheck -version 2>&1 | grep -F "2026.1" >/dev/null 2>&1 || fail "STATICCHECK_VERSION_MISMATCH"
verify_go_module_binding() {
  BINARY="$1"
  MODULE="$2"
  VERSION="$3"
  go version -m "$BINARY" | awk -v module="$MODULE" -v version="$VERSION" '
    $1 == "mod" && $2 == module && $3 == version { found=1 }
    END { exit found ? 0 : 1 }
  '
}

verify_go_module_binding "$(command -v staticcheck)" "honnef.co/go/tools" "v0.7.0" || fail "STATICCHECK_MODULE_BINDING_MISMATCH"
verify_go_module_binding "$(command -v govulncheck)" "golang.org/x/vuln" "v1.7.0" || fail "GOVULNCHECK_MODULE_BINDING_MISMATCH"
verify_go_module_binding "$(command -v gosec)" "github.com/securego/gosec/v2" "v2.28.0" || fail "GOSEC_MODULE_BINDING_MISMATCH"
gitleaks version 2>&1 | grep -F "8.30.1" >/dev/null 2>&1 || fail "GITLEAKS_VERSION_MISMATCH"
syft version 2>&1 | grep -F "1.51.0" >/dev/null 2>&1 || fail "SYFT_VERSION_MISMATCH"

# Repository hygiene. Metadata artifacts are never accepted as source.
BAD_META="$(find . -type f \( -name '.DS_Store' -o -name '._*' \) -print 2>/dev/null; find . -type d -name '__MACOSX' -print 2>/dev/null)"
[ -z "$BAD_META" ] || {
  echo "$BAD_META"
  fail "MACOS_METADATA_PRESENT"
}

# Bootstrap file set and executable-action freeze self-check.
for P in \
  ".github/workflows/p1-security-baseline.yml" \
  "scripts/ci/bootstrap-source.sh" \
  "scripts/ci/install-qualified-tools.sh" \
  "scripts/ci/run-security-baseline.sh" \
  "docs/security/P1D_REPOSITORY_SECURITY_BASELINE.md"
do
  [ -f "$P" ] || fail "BOOTSTRAP_FILE_MISSING_$P"
done

USES_COUNT="$(grep -R '^[[:space:]]*uses:' .github/workflows/p1-security-baseline.yml 2>/dev/null | wc -l | tr -d ' ')"
[ "$USES_COUNT" = "0" ] || fail "UNQUALIFIED_USES_ACTION_PRESENT"

grep -F 'name: p1-security-baseline' .github/workflows/p1-security-baseline.yml >/dev/null 2>&1 || fail "WORKFLOW_NAME_MISMATCH"
grep -F 'contents: read' .github/workflows/p1-security-baseline.yml >/dev/null 2>&1 || fail "WORKFLOW_PERMISSION_NOT_READ_ONLY"
grep -F 'pull_request:' .github/workflows/p1-security-baseline.yml >/dev/null 2>&1 || fail "PULL_REQUEST_TRIGGER_MISSING"
if grep -F 'pull_request_target:' .github/workflows/p1-security-baseline.yml >/dev/null 2>&1; then
  fail "PULL_REQUEST_TARGET_PROHIBITED"
fi

# Qualified secret scan. No exit-code override is allowed.
GITLEAKS_REPORT="$TMP/gitleaks.json"
rm -f "$GITLEAKS_REPORT"
gitleaks dir --no-banner --redact --report-format json --report-path "$GITLEAKS_REPORT" .
GITLEAKS_RC=$?
[ "$GITLEAKS_RC" -eq 0 ] || fail "GITLEAKS_FINDING_OR_EXECUTION_FAILURE"
if [ ! -f "$GITLEAKS_REPORT" ]; then
  printf '[]\n' > "$GITLEAKS_REPORT"
fi

python3 - "$GITLEAKS_REPORT" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
if not p.exists():
    raise SystemExit(7)
text = p.read_text(errors="replace").strip()
if not text:
    raise SystemExit(0)
data = json.loads(text)
if not isinstance(data, list) or data:
    raise SystemExit(7)
PY
RC=$?
[ "$RC" -eq 0 ] || fail "GITLEAKS_REPORT_SEMANTICS_FAILED"
echo "SECRET_SCAN_RESULT=PASS"

tree_has_go() {
  COMMIT="$1"
  git ls-tree -r --name-only "$COMMIT" 2>/dev/null | grep -E '(^|/)go\.(mod|sum)$|\.go$' >/dev/null 2>&1
}

HEAD_HAS_GO=NO
BASE_HAS_GO=NO
tree_has_go "$EXPECTED_HEAD_SHA" && HEAD_HAS_GO=YES
tree_has_go "$EXPECTED_BASE_SHA" && BASE_HAS_GO=YES

if [ "$HEAD_HAS_GO" = "NO" ] && [ "$BASE_HAS_GO" = "NO" ]; then
  echo "P1_SECURITY_BASELINE_MODE=PRE_CODE"
  echo "PRODUCTION_GO_STATE=ABSENT_IN_BASE_AND_HEAD"
  echo "GOFMT_ZERO_DIFF_GATE=DEFERRED_UNTIL_GO_SOURCE_EXISTS"
  echo "GO_VET=DEFERRED_UNTIL_GO_SOURCE_EXISTS"
  echo "STATICCHECK_GATE=DEFERRED_UNTIL_GO_SOURCE_EXISTS"
  echo "GO_TEST=DEFERRED_UNTIL_GO_SOURCE_EXISTS"
  echo "RACE_GATE=DEFERRED_UNTIL_GO_SOURCE_EXISTS"
  echo "GOVULNCHECK_GATE=DEFERRED_UNTIL_GO_SOURCE_EXISTS"
  echo "GOSEC_GATE=DEFERRED_UNTIL_GO_SOURCE_EXISTS"
  echo "FUZZ_GATES=DEFERRED_UNTIL_OWNING_PACKAGES_EXIST"
  echo "OPENAPI_SCHEMA_GATE=DEFERRED_UNTIL_PRODUCTION_GO_STATE_EXISTS"
  echo "ACCEPTANCE_GATE=DEFERRED_UNTIL_OWNING_P1D_TESTS_EXIST"
  echo "SBOM_GATE=DEFERRED_UNTIL_PRODUCTION_BUILD_STATE_EXISTS"
  echo "BUILD_GATE=DEFERRED_UNTIL_CMD_FINSERV_GATEWAY_EXISTS"
  echo "P1_SECURITY_BASELINE=PASS"
  exit 0
fi

echo "P1_SECURITY_BASELINE_MODE=IMPLEMENTATION"

# Formatting gate: process must fail if any Go file needs formatting.
UNFORMATTED="$(gofmt -l .)"
RC=$?
[ "$RC" -eq 0 ] || fail "GOFMT_EXECUTION_FAILED"
[ -z "$UNFORMATTED" ] || {
  echo "$UNFORMATTED"
  fail "GOFMT_ZERO_DIFF_GATE_FAILED"
}
echo "GOFMT_ZERO_DIFF_GATE=PASS"

go vet ./...
RC=$?
[ "$RC" -eq 0 ] || fail "GO_VET_FAILED"

staticcheck ./...
RC=$?
[ "$RC" -eq 0 ] || fail "STATICCHECK_FAILED"

go test ./...
RC=$?
[ "$RC" -eq 0 ] || fail "GO_TEST_FAILED"

go test -race ./...
RC=$?
[ "$RC" -eq 0 ] || fail "GO_RACE_FAILED"

if [ -d test/integration ]; then
  go test ./test/integration/...
  RC=$?
  [ "$RC" -eq 0 ] || fail "POSTGRES_INTEGRATION_TEST_FAILED"
  echo "POSTGRES_INTEGRATION_GATE=PASS"
else
  echo "POSTGRES_INTEGRATION_GATE=DEFERRED_UNTIL_OWNING_TEST_PACKAGE_EXISTS"
fi

# Exact mandatory fuzz targets activate when their owning package exists.
run_fuzz_if_package_exists() {
  PKGDIR="$1"
  TARGET="$2"
  if [ -d "$PKGDIR" ]; then
    go test "./$PKGDIR" -run='^$' -fuzz="^${TARGET}$" -fuzztime=30s
    RC=$?
    [ "$RC" -eq 0 ] || fail "FUZZ_FAILED_$TARGET"
    echo "FUZZ_${TARGET}=PASS"
  else
    echo "FUZZ_${TARGET}=DEFERRED_UNTIL_OWNING_PACKAGE_EXISTS"
  fi
}

run_fuzz_if_package_exists "internal/strictjson" "FuzzStrictJSONDecode"
run_fuzz_if_package_exists "internal/policy" "FuzzPolicyParse"
run_fuzz_if_package_exists "internal/replay" "FuzzEvidenceReplayParse"
run_fuzz_if_package_exists "internal/model" "FuzzIdentifierValidation"
run_fuzz_if_package_exists "internal/approval" "FuzzApprovalStateMachine"

GOVULN_JSON="$TMP/govulncheck.json"
GOVULN_ERR="$TMP/govulncheck.stderr"
rm -f "$GOVULN_JSON" "$GOVULN_ERR"
govulncheck -json ./... >"$GOVULN_JSON" 2>"$GOVULN_ERR"
GOVULN_RC=$?

python3 - "$GOVULN_JSON" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
findings = 0
for raw in p.read_text(errors="replace").splitlines():
    if not raw.strip():
        continue
    obj = json.loads(raw)
    if "finding" in obj:
        findings += 1
print("GOVULNCHECK_STRUCTURED_FINDING_COUNT=%d" % findings)
raise SystemExit(0 if findings == 0 else 7)
PY
PARSE_RC=$?
[ "$GOVULN_RC" -eq 0 ] || fail "GOVULNCHECK_EXIT_NONZERO"
[ "$PARSE_RC" -eq 0 ] || fail "GOVULNCHECK_FINDINGS_PRESENT"
echo "GOVULNCHECK_GATE=PASS"

GOSEC_JSON="$TMP/gosec.json"
rm -f "$GOSEC_JSON"
gosec -fmt=json -out="$GOSEC_JSON" ./...
GOSEC_RC=$?
[ "$GOSEC_RC" -eq 0 ] || fail "GOSEC_EXIT_NONZERO"

python3 - "$GOSEC_JSON" <<'PY'
import json, pathlib, sys
obj=json.loads(pathlib.Path(sys.argv[1]).read_text())
issues=obj.get("Issues", [])
print("GOSEC_ISSUE_COUNT=%d" % len(issues))
raise SystemExit(0 if len(issues)==0 else 7)
PY
RC=$?
[ "$RC" -eq 0 ] || fail "GOSEC_FINDINGS_PRESENT"
echo "GOSEC_GATE=PASS"

# Contract gate: JSON schemas must parse and preserve the accepted 2020-12 dialect.
python3 - <<'PY'
import json, pathlib, sys
root=pathlib.Path(".").resolve()
schemas=sorted((root/"schemas").glob("*.json"))
if len(schemas) != 15:
    print("JSON_SCHEMA_COUNT=%d" % len(schemas))
    raise SystemExit(7)
for p in schemas:
    obj=json.loads(p.read_text())
    if obj.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        print("BAD_SCHEMA_DIALECT="+str(p))
        raise SystemExit(7)
print("JSON_SCHEMA_COUNT=15")
print("JSON_SCHEMA_DIALECT=DRAFT_2020_12")
PY
RC=$?
[ "$RC" -eq 0 ] || fail "JSON_SCHEMA_CONTRACT_FAILED"

# Reject network refs and refs that escape the repository before kin-openapi runs.
python3 - <<'PY'
import pathlib, re, sys
root=pathlib.Path(".").resolve()
p=root/"api/openapi.yaml"
text=p.read_text()
if not re.search(r"(?m)^openapi:\s*3\.1\.2\s*$", text):
    raise SystemExit(7)
for m in re.finditer(r"(?m)^\s*\$ref:\s*['\"]?([^'\"\s]+)", text):
    ref=m.group(1)
    if ref.startswith(("http://","https://","file://")):
        raise SystemExit(7)
    target=ref.split("#",1)[0]
    if target:
        resolved=(p.parent/target).resolve()
        if root not in resolved.parents and resolved != root:
            raise SystemExit(7)
print("OPENAPI_REFERENCE_BOUNDARY=PASS")
PY
RC=$?
[ "$RC" -eq 0 ] || fail "OPENAPI_REFERENCE_BOUNDARY_FAILED"

KIN_TMP="$TMP/kin-openapi"
rm -rf "$KIN_TMP"
mkdir -p "$KIN_TMP" || fail "KIN_TEMP_CREATE_FAILED"
cat > "$KIN_TMP/go.mod" <<'EOF'
module haep.local/openapi-validate
go 1.26
require github.com/getkin/kin-openapi v0.147.0
EOF
cat > "$KIN_TMP/main.go" <<'EOF'
package main
import (
  "context"
  "fmt"
  "os"
  "github.com/getkin/kin-openapi/openapi3"
)
func main() {
  if len(os.Args) != 2 { panic("expected path") }
  loader := openapi3.NewLoader()
  loader.IsExternalRefsAllowed = true
  doc, err := loader.LoadFromFile(os.Args[1])
  if err != nil { panic(err) }
  if err := doc.Validate(context.Background()); err != nil { panic(err) }
  fmt.Println("KIN_OPENAPI_VALIDATION=PASS")
}
EOF
(
  cd "$KIN_TMP" || exit 7
  go mod download
  RC=$?
  [ "$RC" -eq 0 ] || exit "$RC"
  go run . "$ROOT/api/openapi.yaml"
)
RC=$?
[ "$RC" -eq 0 ] || fail "KIN_OPENAPI_VALIDATION_FAILED"
echo "KIN_OPENAPI_VERSION=v0.147.0"
echo "KIN_OPENAPI_RUNTIME_DEPENDENCY=NO"

# Design manifest integrity is checked for every immutable design file it lists.
python3 - <<'PY'
import hashlib, json, pathlib, sys
root=pathlib.Path(".").resolve()
m=json.loads((root/"MANIFEST.json").read_text())
if m.get("schema_version") != "finserv-design-manifest/v1":
    raise SystemExit(7)
for row in m.get("files", []):
    p=root/row["path"]
    if not p.is_file():
        print("MANIFEST_MISSING="+row["path"])
        raise SystemExit(7)
    data=p.read_bytes()
    if len(data) != row["bytes"] or hashlib.sha256(data).hexdigest() != row["sha256"]:
        print("MANIFEST_MISMATCH="+row["path"])
        raise SystemExit(7)
print("MANIFEST_PRODUCT_CONTRACT_VALIDATION=PASS")
PY
RC=$?
[ "$RC" -eq 0 ] || fail "MANIFEST_PRODUCT_CONTRACT_FAILED"

# Acceptance is a future owning-test gate, never silently converted to NOT_REQUIRED.
if [ -x scripts/tests/run-p1-acceptance.sh ]; then
  /bin/bash scripts/tests/run-p1-acceptance.sh
  RC=$?
  [ "$RC" -eq 0 ] || fail "ACCEPTANCE_76_OF_76_FAILED"
  echo "TOTAL_ACCEPTANCE_MAPPED=76/76"
else
  echo "ACCEPTANCE_GATE=DEFERRED_UNTIL_CANONICAL_P1D_ACCEPTANCE_RUNNER_EXISTS"
fi

if [ -d cmd/finserv-gateway ]; then
  SBOM="$TMP/sbom.spdx.json"
  syft dir:. -o spdx-json > "$SBOM"
  RC=$?
  [ "$RC" -eq 0 ] || fail "SYFT_SBOM_FAILED"
  python3 - "$SBOM" <<'PY'
import json, pathlib, sys
obj=json.loads(pathlib.Path(sys.argv[1]).read_text())
if obj.get("spdxVersion") != "SPDX-2.3":
    raise SystemExit(7)
PY
  RC=$?
  [ "$RC" -eq 0 ] || fail "SBOM_SPDX_2_3_FAILED"

  BUILD_OUT="$TMP/finserv-gateway"
  go build -trimpath -o "$BUILD_OUT" ./cmd/finserv-gateway
  RC=$?
  [ "$RC" -eq 0 ] || fail "CONTROLLED_BUILD_FAILED"
  sha256sum "$BUILD_OUT"
  echo "SBOM_GATE=PASS"
  echo "CONTROLLED_BUILD=PASS"
else
  echo "SBOM_GATE=DEFERRED_UNTIL_CMD_FINSERV_GATEWAY_EXISTS"
  echo "BUILD_GATE=DEFERRED_UNTIL_CMD_FINSERV_GATEWAY_EXISTS"
fi

echo "P1_SECURITY_BASELINE=PASS"
exit 0
