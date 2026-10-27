#!/bin/bash
# The acceptance check of the project: plugin validation, shell lint and hook tests.
# Usage: scripts/check.sh

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

run() {
  local name="$1"
  shift
  if "$@"; then
    echo "$name: PASS"
  else
    echo "$name: FAIL"
    FAILED=1
  fi
}

run Validate claude plugin validate --strict "$ROOT"
run Lint shellcheck "$ROOT"/hooks/*.sh "$ROOT"/scripts/*.sh "$ROOT"/tests/*.sh
run "Hook tests" "$ROOT/tests/hooks.sh"

exit "$FAILED"
