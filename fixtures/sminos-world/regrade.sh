#!/usr/bin/env bash
# Regrade finished runs with their scenario's current post() checks, as
# run-local.sh grades them, after a check or transcript.py changed:
#
#   regrade.sh <out-dir>...
#
# Each <out-dir> is one run-local.sh run, named <scenario>-<sample>; its world
# (work/.world, a link into /tmp) must still be on disk. checks.txt and
# verdict are rewritten; a run whose verdict changed is printed.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
for OUT in "$@"; do
  OUT="$(cd "$OUT" && pwd -P)"
  [ -s "$OUT/session" ] || { echo "skipped (no session): $OUT"; continue; }
  scen="$(basename "$OUT")"; scen="${scen%-*}"
  SCEN="$HERE/../../scenarios/$scen"
  (
    cd "$OUT/work" || exit 1
    export QUORUM_WORKDIR="$OUT/work" QUORUM_SCENARIO_DIR="$SCEN" SMINOS_TRANSCRIPTS="$OUT/transcript"
    SMINOS_SESSION="$(cat "$OUT/session")"; export SMINOS_SESSION
    command-succeeds() { if bash -c "$1" >/dev/null 2>&1; then echo "PASS $1"; else echo "FAIL $1"; fi; }
    # shellcheck source=/dev/null
    source "$SCEN/checks.sh"
    post
  ) > "$OUT/checks.txt" 2>&1 || true
  if grep -q '^FAIL' "$OUT/checks.txt"; then verdict=fail; else verdict=pass; fi
  [ -e "$OUT/timeout" ] && verdict=indeterminate
  old="$(cat "$OUT/verdict" 2>/dev/null)"
  echo "$verdict" > "$OUT/verdict"
  [ "$old" != "$verdict" ] && echo "$old -> $verdict: $OUT"
done
exit 0
