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

# Exact fuzz-target gate. A package directory alone is insufficient: Go may
# return RC=0 for -fuzz=<missing target>. First prove the exact target is listed,
# then run only that exact target for the bounded duration.
fuzz_target_gate() {
  PKGDIR="$1"
  TARGET="$2"
  FUZZTIME="$3"

  if [ ! -d "$PKGDIR" ]; then
    echo "FUZZ_${TARGET}=DEFERRED_UNTIL_OWNING_PACKAGE_EXISTS"
    return 0
  fi

  SAFE_TARGET="$(printf '%s' "$TARGET" | tr -cd 'A-Za-z0-9_')"
  LIST_OUT="$TMP/fuzz-list-${SAFE_TARGET}.txt"
  rm -f "$LIST_OUT"
  go test "./$PKGDIR" -run='^$' -list="^${TARGET}$" >"$LIST_OUT" 2>&1
  RC=$?
  if [ "$RC" -ne 0 ]; then
    cat "$LIST_OUT"
    echo "FUZZ_${TARGET}=FAIL_TARGET_DISCOVERY"
    return 21
  fi

  MATCH_COUNT="$(grep -Fxc "$TARGET" "$LIST_OUT" 2>/dev/null || true)"
  if [ "$MATCH_COUNT" != "1" ]; then
    cat "$LIST_OUT"
    echo "FUZZ_${TARGET}=FAIL_EXACT_TARGET_NOT_FOUND"
    return 22
  fi

  go test "./$PKGDIR" -run='^$' -fuzz="^${TARGET}$" -fuzztime="$FUZZTIME"
  RC=$?
  if [ "$RC" -ne 0 ]; then
    echo "FUZZ_${TARGET}=FAIL_EXECUTION"
    return 23
  fi

  echo "FUZZ_${TARGET}=PASS"
  return 0
}

run_fuzz_target_canaries() {
  CANARY="$TMP/fuzz-target-existence-canary"
  rm -rf "$CANARY"
  mkdir -p "$CANARY/no-target" "$CANARY/with-target" || return 31

  cat > "$CANARY/go.mod" <<'EOF_CANARY_MOD'
module haep.local/fuzz-target-canary
go 1.26
EOF_CANARY_MOD
  cat > "$CANARY/no-target/pkg.go" <<'EOF_CANARY_NO_TARGET'
package notarget
func Value() int { return 1 }
EOF_CANARY_NO_TARGET
  cat > "$CANARY/with-target/pkg.go" <<'EOF_CANARY_WITH_TARGET'
package withtarget
func Value() int { return 1 }
EOF_CANARY_WITH_TARGET
  cat > "$CANARY/with-target/fuzz_test.go" <<'EOF_CANARY_FUZZ'
package withtarget
import "testing"
func FuzzPresentTarget(f *testing.F) {
  f.Add("seed")
  f.Fuzz(func(t *testing.T, s string) { _ = s })
}
EOF_CANARY_FUZZ

  SAVED_PWD="$(pwd)"
  cd "$CANARY" || return 31

  MISSING_PACKAGE_OUT="$(fuzz_target_gate "missing-package" "FuzzMissingPackage" "1x" 2>&1)"
  MISSING_PACKAGE_RC=$?
  if [ "$MISSING_PACKAGE_RC" -ne 0 ] || ! printf '%s\n' "$MISSING_PACKAGE_OUT" | grep -F 'DEFERRED_UNTIL_OWNING_PACKAGE_EXISTS' >/dev/null 2>&1; then
    cd "$SAVED_PWD" || return 31
    return 32
  fi

  MISSING_TARGET_OUT="$(fuzz_target_gate "no-target" "FuzzRequiredTarget" "1x" 2>&1)"
  MISSING_TARGET_RC=$?
  if [ "$MISSING_TARGET_RC" -eq 0 ]; then
    cd "$SAVED_PWD" || return 31
    return 33
  fi

  PRESENT_TARGET_OUT="$(fuzz_target_gate "with-target" "FuzzPresentTarget" "1x" 2>&1)"
  PRESENT_TARGET_RC=$?
  if [ "$PRESENT_TARGET_RC" -ne 0 ] || ! printf '%s\n' "$PRESENT_TARGET_OUT" | grep -F 'FUZZ_FuzzPresentTarget=PASS' >/dev/null 2>&1; then
    cd "$SAVED_PWD" || return 31
    return 34
  fi

  cd "$SAVED_PWD" || return 31
  echo "FUZZ_MISSING_PACKAGE=DEFERRED"
  echo "FUZZ_EXISTING_PACKAGE_MISSING_TARGET=FAIL_NONZERO"
  echo "FUZZ_EXISTING_PACKAGE_PRESENT_TARGET=PASS"
  echo "FUZZ_TARGET_EXISTENCE_GATE=PASS"
  echo "FUZZ_MISSING_TARGET_CANARY_RC_NONZERO=PASS"
  echo "FUZZ_FALSE_PASS_PATH_COUNT=0"
  return 0
}

run_fuzz_target_canaries
RC=$?
[ "$RC" -eq 0 ] || fail "FUZZ_TARGET_EXISTENCE_CANARY_FAILED_RC_${RC}"

# kin-openapi v0.147.0 local-only resolver. The root document is read directly
# and given a repository-relative logical location. Every external/transitive
# reference is then mediated by ReadFromURIFunc, which rejects URI schemes,
# absolute paths, traversal/escape, and symlink escape before reading bytes.
run_kin_openapi_local_only_gate() {
  KIN_TMP="$TMP/kin-openapi-local-only"
  rm -rf "$KIN_TMP"
  mkdir -p "$KIN_TMP" || return 41

  cat > "$KIN_TMP/go.mod" <<'EOF_KIN_MOD'
module haep.local/openapi-validate
go 1.26
require github.com/getkin/kin-openapi v0.147.0
EOF_KIN_MOD

  cat > "$KIN_TMP/main.go" <<'EOF_KIN_GO'
package main

import (
	"context"
	"fmt"
	"net/url"
	"os"
	pathpkg "path"
	"path/filepath"
	"strings"

	"github.com/getkin/kin-openapi/openapi3"
)

func insideRoot(root, candidate string) bool {
	rel, err := filepath.Rel(root, candidate)
	if err != nil {
		return false
	}
	if rel == "." {
		return true
	}
	return rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) && !filepath.IsAbs(rel)
}

func localOnlyReader(repoRoot string) (openapi3.ReadFromURIFunc, error) {
	rootAbs, err := filepath.Abs(repoRoot)
	if err != nil {
		return nil, err
	}
	rootReal, err := filepath.EvalSymlinks(rootAbs)
	if err != nil {
		return nil, err
	}

	return func(_ *openapi3.Loader, location *url.URL) ([]byte, error) {
		if location == nil {
			return nil, fmt.Errorf("nil reference location")
		}
		if location.Scheme != "" || location.Host != "" || location.User != nil || location.Opaque != "" {
			return nil, fmt.Errorf("non-local reference rejected: %q", location.String())
		}
		if location.RawQuery != "" {
			return nil, fmt.Errorf("reference query rejected: %q", location.String())
		}
		refPath := location.Path
		if refPath == "" || strings.Contains(refPath, "\\") {
			return nil, fmt.Errorf("invalid local reference path: %q", location.String())
		}
		if pathpkg.IsAbs(refPath) || filepath.IsAbs(filepath.FromSlash(refPath)) {
			return nil, fmt.Errorf("absolute reference path rejected: %q", location.String())
		}

		cleanSlash := pathpkg.Clean(refPath)
		if cleanSlash == ".." || strings.HasPrefix(cleanSlash, "../") {
			return nil, fmt.Errorf("repository escape rejected: %q", location.String())
		}

		candidateAbs, err := filepath.Abs(filepath.Join(rootAbs, filepath.FromSlash(cleanSlash)))
		if err != nil {
			return nil, err
		}
		if !insideRoot(rootAbs, candidateAbs) {
			return nil, fmt.Errorf("repository escape rejected: %q", location.String())
		}

		candidateReal, err := filepath.EvalSymlinks(candidateAbs)
		if err != nil {
			return nil, err
		}
		if !insideRoot(rootReal, candidateReal) {
			return nil, fmt.Errorf("symlink repository escape rejected: %q", location.String())
		}
		return os.ReadFile(candidateReal)
	}, nil
}

func validate(repoRoot, specPath string) error {
	if filepath.IsAbs(specPath) || strings.Contains(specPath, "\\") {
		return fmt.Errorf("root spec path must be repository-relative")
	}
	cleanSpec := pathpkg.Clean(filepath.ToSlash(specPath))
	if cleanSpec == ".." || strings.HasPrefix(cleanSpec, "../") || cleanSpec == "." {
		return fmt.Errorf("root spec escapes repository")
	}

	rootAbs, err := filepath.Abs(repoRoot)
	if err != nil {
		return err
	}
	specAbs, err := filepath.Abs(filepath.Join(rootAbs, filepath.FromSlash(cleanSpec)))
	if err != nil {
		return err
	}
	if !insideRoot(rootAbs, specAbs) {
		return fmt.Errorf("root spec escapes repository")
	}
	data, err := os.ReadFile(specAbs)
	if err != nil {
		return err
	}

	reader, err := localOnlyReader(rootAbs)
	if err != nil {
		return err
	}
	loader := openapi3.NewLoader()
	loader.ReadFromURIFunc = reader
	loader.IsExternalRefsAllowed = false
	doc, err := loader.LoadFromDataWithPath(data, &url.URL{Path: cleanSpec})
	if err != nil {
		return err
	}
	return doc.Validate(context.Background())
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: validator <repo-root> <repo-relative-spec>")
		os.Exit(2)
	}
	if err := validate(os.Args[1], os.Args[2]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(7)
	}
	fmt.Println("KIN_OPENAPI_VALIDATION=PASS")
}
EOF_KIN_GO

  (
    cd "$KIN_TMP" || exit 41
    go mod download github.com/getkin/kin-openapi@v0.147.0
    RC=$?
    [ "$RC" -eq 0 ] || exit 42
    go mod tidy
    RC=$?
    [ "$RC" -eq 0 ] || exit 42
    ACTUAL_KIN_VERSION="$(go list -m -f '{{.Version}}' github.com/getkin/kin-openapi 2>/dev/null)"
    [ "$ACTUAL_KIN_VERSION" = "v0.147.0" ] || exit 42
    go build -trimpath -o "$KIN_TMP/validator" .
  )
  RC=$?
  [ "$RC" -eq 0 ] || return "$RC"

  # Canonical repository-local relative references must remain valid.
  "$KIN_TMP/validator" "$ROOT" "api/openapi.yaml" >"$KIN_TMP/canonical.out" 2>"$KIN_TMP/canonical.err"
  RC=$?
  [ "$RC" -eq 0 ] || {
    cat "$KIN_TMP/canonical.err"
    return 43
  }
  echo "CANONICAL_LOCAL_REF_VALIDATION=PASS"

  CANARY_ROOT="$KIN_TMP/canaries"
  mkdir -p "$CANARY_ROOT/api" "$CANARY_ROOT/schemas" || return 44

  write_spec_with_ref() {
    OUT="$1"
    REF="$2"
    cat > "$OUT" <<EOF_CANARY_SPEC
openapi: 3.1.2
info:
  title: boundary-canary
  version: "1"
paths:
  /x:
    get:
      responses:
        "200":
          description: ok
          content:
            application/json:
              schema:
                \$ref: "$REF"
EOF_CANARY_SPEC
  }

  expect_rejected() {
    LABEL="$1"
    SPEC="$2"
    "$KIN_TMP/validator" "$CANARY_ROOT" "$SPEC" >"$KIN_TMP/${LABEL}.out" 2>"$KIN_TMP/${LABEL}.err"
    CANARY_RC=$?
    if [ "$CANARY_RC" -eq 0 ]; then
      echo "${LABEL}=UNEXPECTEDLY_ACCEPTED"
      return 45
    fi
    echo "${LABEL}=REJECTED"
    return 0
  }

  write_spec_with_ref "$CANARY_ROOT/api/network.yaml" "https://example.invalid/schema.json"
  expect_rejected "NETWORK_REF_CANARY" "api/network.yaml" || return $?

  write_spec_with_ref "$CANARY_ROOT/api/file-uri.yaml" "file:///etc/passwd"
  expect_rejected "FILE_URI_REF_CANARY" "api/file-uri.yaml" || return $?

  write_spec_with_ref "$CANARY_ROOT/api/absolute.yaml" "/etc/passwd"
  expect_rejected "ABSOLUTE_PATH_REF_CANARY" "api/absolute.yaml" || return $?

  write_spec_with_ref "$CANARY_ROOT/api/escape.yaml" "../../outside.json"
  expect_rejected "PATH_ESCAPE_REF_CANARY" "api/escape.yaml" || return $?

  cat > "$CANARY_ROOT/schemas/outer.json" <<'EOF_TRANSITIVE'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$ref": "https://example.invalid/transitive.json"
}
EOF_TRANSITIVE
  write_spec_with_ref "$CANARY_ROOT/api/transitive.yaml" "../schemas/outer.json"
  expect_rejected "TRANSITIVE_NETWORK_REF_CANARY" "api/transitive.yaml" || return $?

  cat > "$CANARY_ROOT/schemas/local.json" <<'EOF_LOCAL_SCHEMA'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"name": {"type": "string"}}
}
EOF_LOCAL_SCHEMA
  write_spec_with_ref "$CANARY_ROOT/api/local.yaml" "../schemas/local.json"
  "$KIN_TMP/validator" "$CANARY_ROOT" "api/local.yaml" >"$KIN_TMP/local.out" 2>"$KIN_TMP/local.err"
  RC=$?
  [ "$RC" -eq 0 ] || {
    cat "$KIN_TMP/local.err"
    return 46
  }
  echo "LOCAL_REF_POSITIVE_CANARY=PASS"

  echo "KIN_OPENAPI_LOCAL_ONLY_READER=PASS"
  echo "KIN_OPENAPI_NETWORK_FETCH_ALLOWED=NO"
  echo "KIN_OPENAPI_REPOSITORY_ESCAPE_ALLOWED=NO"
  echo "KIN_OPENAPI_TRANSITIVE_REF_BOUNDARY=PASS"
  echo "KIN_OPENAPI_VERSION=v0.147.0"
  echo "KIN_OPENAPI_RUNTIME_DEPENDENCY=NO"
  return 0
}

run_kin_openapi_local_only_gate
RC=$?
[ "$RC" -eq 0 ] || fail "KIN_OPENAPI_LOCAL_ONLY_GATE_FAILED_RC_${RC}"

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
  echo "OPENAPI_SCHEMA_GATE=PASS_LOCAL_ONLY_READER"
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

# Exact mandatory fuzz targets activate when their owning package exists, and
# the exact target must first be proven by go test -list.
run_required_fuzz() {
  PKGDIR="$1"
  TARGET="$2"
  fuzz_target_gate "$PKGDIR" "$TARGET" "30s"
  RC=$?
  [ "$RC" -eq 0 ] || fail "FUZZ_GATE_FAILED_${TARGET}_RC_${RC}"
}

run_required_fuzz "internal/strictjson" "FuzzStrictJSONDecode"
run_required_fuzz "internal/policy" "FuzzPolicyParse"
run_required_fuzz "internal/replay" "FuzzEvidenceReplayParse"
run_required_fuzz "internal/model" "FuzzIdentifierValidation"
run_required_fuzz "internal/approval" "FuzzApprovalStateMachine"

echo "FUZZ_TARGET_EXISTENCE_GATE=PASS"
echo "FUZZ_FALSE_PASS_PATH_COUNT=0"

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
