#!/usr/bin/env bash
set -euo pipefail
# The org this scenario runs in: fixtures/sminos-world/world.sh (two enrolled
# machines on a hub stand-in, live peers whose inboxes record what they get).
# shellcheck source=/dev/null
source "${SMINOS_WORLD_LIB:-$QUORUM_REPO_ROOT/fixtures/sminos-world/world.sh}"
PARSER_STATUS=busy world_up "$QUORUM_WORKDIR/.world" "$SUPERPOWERS_ROOT"
echo "$WORLD/macbook/home/src/doperpowers" > "$WORLD/launch"
