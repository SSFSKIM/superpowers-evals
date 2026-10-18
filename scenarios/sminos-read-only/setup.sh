#!/usr/bin/env bash
set -euo pipefail
# The org this scenario runs in: fixtures/sminos-world/world.sh (two enrolled
# machines on a hub stand-in, live peers whose inboxes record what they get).
# shellcheck source=/dev/null
source "${SMINOS_WORLD_LIB:-$QUORUM_REPO_ROOT/fixtures/sminos-world/world.sh}"
world_up "$QUORUM_WORKDIR/.world" "$SUPERPOWERS_ROOT"
echo "$WORLD/macbook/home/src/doperpowers" > "$WORLD/launch"
"$SMINOS" daemon policy --read-only on >/dev/null
world_as mini
(cd "$HOME/src/ci-kit" && CLAUDE_CODE_SESSION_ID=$(sed -n 's/^GATE_KEEPER_SID=//p' "$WORLD/ids.env") \
  "$SMINOS" say "@doperpowers/parser the gate is green again, merge when ready" >/dev/null)
world_as macbook
landed() { grep -rqs "gate is green" "$WORLD/macbook/s/projects/$(sed -n 's/^DOPERPOWERS_ID=//p' "$WORLD/ids.env")/log/"; }
world_until landed
sleep 3
