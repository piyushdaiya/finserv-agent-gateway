#!/bin/bash
# HAEP FinServ P1D-PRE-000 source binding verifier.
# This script never chooses a repository/ref. The workflow acquires the exact
# trusted-event SHA first, verifies it, then invokes this script as a second,
# local fail-closed binding gate.

EXPECTED_REPOSITORY="${HAEP_EXPECTED_REPOSITORY:-}"
EXPECTED_HEAD_SHA="${HAEP_EXPECTED_HEAD_SHA:-}"
EXPECTED_BASE_SHA="${HAEP_EXPECTED_BASE_SHA:-}"
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

fail() {
  echo "SOURCE_BOOTSTRAP_BINDING=FAIL"
  echo "SOURCE_BOOTSTRAP_FAILURE=$1"
  return 7
}

if [ "$EXPECTED_REPOSITORY" != "piyushdaiya/finserv-agent-gateway" ]; then
  fail "UNEXPECTED_REPOSITORY"
  exit $?
fi

case "$EXPECTED_HEAD_SHA" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
  *) fail "INVALID_EXPECTED_HEAD_SHA"; exit $? ;;
esac

case "$EXPECTED_BASE_SHA" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
  *) fail "INVALID_EXPECTED_BASE_SHA"; exit $? ;;
esac

if [ ! -d "$ROOT/.git" ]; then
  fail "GIT_METADATA_MISSING"
  exit $?
fi

cd "$ROOT" || { fail "WORKSPACE_CD_FAILED"; exit $?; }

ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
RC=$?
if [ "$RC" -ne 0 ]; then
  fail "HEAD_READ_FAILED"
  exit $?
fi

if [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD_SHA" ]; then
  echo "EXPECTED_HEAD_SHA=$EXPECTED_HEAD_SHA"
  echo "ACTUAL_HEAD_SHA=$ACTUAL_HEAD"
  fail "HEAD_SHA_MISMATCH"
  exit $?
fi

git cat-file -e "${EXPECTED_BASE_SHA}^{commit}" >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then
  fail "EXPECTED_BASE_OBJECT_MISSING"
  exit $?
fi

REMOTE_URL="$(git remote get-url origin 2>/dev/null)"
RC=$?
if [ "$RC" -ne 0 ]; then
  fail "ORIGIN_READ_FAILED"
  exit $?
fi

if [ "$REMOTE_URL" != "https://github.com/piyushdaiya/finserv-agent-gateway.git" ]; then
  echo "ACTUAL_ORIGIN_URL=$REMOTE_URL"
  fail "ORIGIN_URL_NOT_EXACT"
  exit $?
fi

REMOTE_COUNT="$(git remote | wc -l | tr -d ' ')"
if [ "$REMOTE_COUNT" != "1" ]; then
  echo "REMOTE_COUNT=$REMOTE_COUNT"
  fail "UNEXPECTED_REMOTE_COUNT"
  exit $?
fi

if [ -e .gitmodules ]; then
  fail "SUBMODULE_CONFIGURATION_NOT_QUALIFIED"
  exit $?
fi

echo "SOURCE_BOOTSTRAP_REPOSITORY=$EXPECTED_REPOSITORY"
echo "SOURCE_BOOTSTRAP_EXPECTED_HEAD=$EXPECTED_HEAD_SHA"
echo "SOURCE_BOOTSTRAP_ACTUAL_HEAD=$ACTUAL_HEAD"
echo "SOURCE_BOOTSTRAP_EXPECTED_BASE=$EXPECTED_BASE_SHA"
echo "SOURCE_BOOTSTRAP_BINDING=PASS"
exit 0
