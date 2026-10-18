#!/usr/bin/env bash
set -euo pipefail
# The org this scenario runs in: fixtures/sminos-world/world.sh (two enrolled
# machines on a hub stand-in, live peers whose inboxes record what they get).
# shellcheck source=/dev/null
source "${SMINOS_WORLD_LIB:-$QUORUM_REPO_ROOT/fixtures/sminos-world/world.sh}"
world_up "$QUORUM_WORKDIR/.world" "$SUPERPOWERS_ROOT"
# studio: a machine of its own, not enrolled, the session's.
world_as studio
world_repo "$HOME/src/tools" tools
echo "$WORLD/studio/home/src/tools" > "$WORLD/launch"
echo "ENROLL_CODE=$(world_ctl code studio)" > "$WORLD/vars"
cat > "$WORLD/env.sh" <<ENV
export HOME="$WORLD/studio/home" SMINOS_HOME="$WORLD/studio/s" DAEMON_HOST=studio
export PATH="$WORLD/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" WORLD_CALLS="$WORLD/calls"
ENV
