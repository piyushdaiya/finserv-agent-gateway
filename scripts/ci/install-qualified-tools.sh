#!/bin/bash
# Install the exact P1B/P1C-qualified CLI toolchain into runner-temporary storage.
# No floating versions. No GitHub Actions are used for tool installation.

GO_VERSION="go1.26.7"
STATICCHECK_VERSION="2026.1"
STATICCHECK_MODULE_VERSION="v0.7.0"
GOVULNCHECK_VERSION="v1.7.0"
GOSEC_VERSION="v2.28.0"
GITLEAKS_VERSION="v8.30.1"
SYFT_VERSION="v1.51.0"
KIN_OPENAPI_VERSION="v0.147.0"

GO_ARCHIVE="go1.26.7.linux-amd64.tar.gz"
GO_ARCHIVE_SHA256="ffb5f8de10c62550dfddab66b36b57030721e0a44a3218e9e1181d7b59f121ca"
GITLEAKS_ARCHIVE="gitleaks_8.30.1_linux_x64.tar.gz"
GITLEAKS_ARCHIVE_SHA256="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
SYFT_ARCHIVE="syft_1.51.0_linux_amd64.tar.gz"
SYFT_ARCHIVE_SHA256="2a2e837a2c8d59ec9af5472ee22d3b04ee463c4e44476ecf993fd1e5ab6ebc7f"

ROOT="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/haep-qualified-tools"
BIN="$ROOT/bin"
DL="$ROOT/downloads"
GOROOT="$ROOT/go"

fail() {
  echo "QUALIFIED_TOOL_INSTALL=FAIL"
  echo "QUALIFIED_TOOL_INSTALL_FAILURE=$1"
  exit 7
}

need_host_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "HOST_TOOL_MISSING_$1"
}

need_host_tool curl
need_host_tool tar
need_host_tool sha256sum
need_host_tool grep

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64|Linux-amd64) ;;
  *) fail "UNQUALIFIED_RUNNER_PLATFORM_$(uname -s)_$(uname -m)" ;;
esac

rm -rf "$ROOT"
mkdir -p "$BIN" "$DL" || fail "TOOL_ROOT_CREATE_FAILED"

download_and_verify() {
  URL="$1"
  OUT="$2"
  SHA="$3"
  curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$URL" -o "$OUT"
  RC=$?
  [ "$RC" -eq 0 ] || fail "DOWNLOAD_FAILED_$(basename "$OUT")"
  ACTUAL="$(sha256sum "$OUT" | awk '{print $1}')"
  [ "$ACTUAL" = "$SHA" ] || {
    echo "EXPECTED_SHA256=$SHA"
    echo "ACTUAL_SHA256=$ACTUAL"
    fail "ARCHIVE_SHA256_MISMATCH_$(basename "$OUT")"
  }
}

download_and_verify   "https://go.dev/dl/$GO_ARCHIVE"   "$DL/$GO_ARCHIVE"   "$GO_ARCHIVE_SHA256"

tar -C "$ROOT" -xzf "$DL/$GO_ARCHIVE"
RC=$?
[ "$RC" -eq 0 ] || fail "GO_EXTRACT_FAILED"

export PATH="$GOROOT/bin:$BIN:$PATH"
export GOROOT="$GOROOT"
export GOBIN="$BIN"
export GOTOOLCHAIN=local
export GOPROXY="https://proxy.golang.org,direct"
export GOSUMDB="sum.golang.org"

ACTUAL_GO="$("$GOROOT/bin/go" version | awk '{print $3}')"
[ "$ACTUAL_GO" = "$GO_VERSION" ] || fail "GO_VERSION_MISMATCH"

"$GOROOT/bin/go" install "honnef.co/go/tools/cmd/staticcheck@$STATICCHECK_MODULE_VERSION"
RC=$?
[ "$RC" -eq 0 ] || fail "STATICCHECK_INSTALL_FAILED"

"$GOROOT/bin/go" install "golang.org/x/vuln/cmd/govulncheck@$GOVULNCHECK_VERSION"
RC=$?
[ "$RC" -eq 0 ] || fail "GOVULNCHECK_INSTALL_FAILED"

"$GOROOT/bin/go" install "github.com/securego/gosec/v2/cmd/gosec@$GOSEC_VERSION"
RC=$?
[ "$RC" -eq 0 ] || fail "GOSEC_INSTALL_FAILED"

download_and_verify   "https://github.com/gitleaks/gitleaks/releases/download/$GITLEAKS_VERSION/$GITLEAKS_ARCHIVE"   "$DL/$GITLEAKS_ARCHIVE"   "$GITLEAKS_ARCHIVE_SHA256"

tar -C "$BIN" -xzf "$DL/$GITLEAKS_ARCHIVE" gitleaks
RC=$?
[ "$RC" -eq 0 ] || fail "GITLEAKS_EXTRACT_FAILED"
chmod 0755 "$BIN/gitleaks"

download_and_verify   "https://github.com/anchore/syft/releases/download/$SYFT_VERSION/$SYFT_ARCHIVE"   "$DL/$SYFT_ARCHIVE"   "$SYFT_ARCHIVE_SHA256"

tar -C "$BIN" -xzf "$DL/$SYFT_ARCHIVE" syft
RC=$?
[ "$RC" -eq 0 ] || fail "SYFT_EXTRACT_FAILED"
chmod 0755 "$BIN/syft"

STATICCHECK_OUT="$("$BIN/staticcheck" -version 2>&1)"
echo "$STATICCHECK_OUT" | grep -F "$STATICCHECK_VERSION" >/dev/null 2>&1 || fail "STATICCHECK_VERSION_MISMATCH"
"$GOROOT/bin/go" version -m "$BIN/staticcheck" | grep -F "honnef.co/go/tools $STATICCHECK_MODULE_VERSION" >/dev/null 2>&1 || fail "STATICCHECK_MODULE_BINDING_MISMATCH"

"$GOROOT/bin/go" version -m "$BIN/govulncheck" | grep -F "golang.org/x/vuln $GOVULNCHECK_VERSION" >/dev/null 2>&1 || fail "GOVULNCHECK_MODULE_BINDING_MISMATCH"

"$GOROOT/bin/go" version -m "$BIN/gosec" | grep -F "github.com/securego/gosec/v2 $GOSEC_VERSION" >/dev/null 2>&1 || fail "GOSEC_MODULE_BINDING_MISMATCH"

GITLEAKS_OUT="$("$BIN/gitleaks" version 2>&1)"
echo "$GITLEAKS_OUT" | grep -F "8.30.1" >/dev/null 2>&1 || fail "GITLEAKS_VERSION_MISMATCH"

SYFT_OUT="$("$BIN/syft" version 2>&1)"
echo "$SYFT_OUT" | grep -F "1.51.0" >/dev/null 2>&1 || fail "SYFT_VERSION_MISMATCH"

if [ -n "${GITHUB_PATH:-}" ]; then
  printf '%s\n' "$GOROOT/bin" >> "$GITHUB_PATH"
  printf '%s\n' "$BIN" >> "$GITHUB_PATH"
fi
if [ -n "${GITHUB_ENV:-}" ]; then
  printf 'GOROOT=%s\n' "$GOROOT" >> "$GITHUB_ENV"
  printf 'GOTOOLCHAIN=local\n' >> "$GITHUB_ENV"
  printf 'GOPROXY=https://proxy.golang.org,direct\n' >> "$GITHUB_ENV"
  printf 'GOSUMDB=sum.golang.org\n' >> "$GITHUB_ENV"
  printf 'HAEP_KIN_OPENAPI_VERSION=%s\n' "$KIN_OPENAPI_VERSION" >> "$GITHUB_ENV"
fi

cat <<EOF
QUALIFIED_TOOL_INSTALL=PASS
GO_TOOLCHAIN=$GO_VERSION
STATICCHECK=$STATICCHECK_VERSION
STATICCHECK_MODULE=$STATICCHECK_MODULE_VERSION
GOVULNCHECK=$GOVULNCHECK_VERSION
GOSEC=$GOSEC_VERSION
GITLEAKS=$GITLEAKS_VERSION
SYFT=$SYFT_VERSION
KIN_OPENAPI=$KIN_OPENAPI_VERSION
GO_ARCHIVE_SHA256=$GO_ARCHIVE_SHA256
GITLEAKS_ARCHIVE_SHA256=$GITLEAKS_ARCHIVE_SHA256
SYFT_ARCHIVE_SHA256=$SYFT_ARCHIVE_SHA256
EOF

exit 0
