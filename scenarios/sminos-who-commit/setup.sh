#!/usr/bin/env bash
set -euo pipefail
# The org this scenario runs in: fixtures/sminos-world/world.sh (two enrolled
# machines on a hub stand-in, live peers whose inboxes record what they get).
# shellcheck source=/dev/null
source "${SMINOS_WORLD_LIB:-$QUORUM_REPO_ROOT/fixtures/sminos-world/world.sh}"
world_up "$QUORUM_WORKDIR/.world" "$SUPERPOWERS_ROOT"
echo "$WORLD/macbook/home/src/doperpowers" > "$WORLD/launch"

# ci-kit's docs session on the mini goes to the background, as /background
# does: its transcript names the session it goes on as, and its process ends.
OLD=7a11ce02-0000-4000-8000-00000000c102
NEW=7a11ce0a-0000-4000-8000-00000000c10a
world_as mini
rec=$(grep -l "\"$OLD\"" "$HOME"/.claude/sessions/*.json)
printf '{"type":"continued-in","continuedInSessionId":"%s"}\n' "$NEW" >> "$HOME/.claude/projects/p-$OLD/$OLD.jsonl"
kill "$(basename "$rec" .json)"
rm -f "$rec"
world_peer docs "$NEW" "$HOME/src/ci-kit" idle docs-2
"$SMINOS" daemon tick >/dev/null 2>&1 || true

# The commit, in the macbook's ci-kit checkout, carries the old session's line.
world_as macbook
printf '# ci-kit\n\nRunner image: ubuntu-24.04\n' > "$HOME/src/ci-kit/README.md"
world_gitq -C "$HOME/src/ci-kit" commit -qam "docs: the runner image in the README

Sminos-Session: docs#7a11ce02 (ci-kit on mini)"
echo "SHA=$(git -C "$HOME/src/ci-kit" rev-parse --short HEAD)" > "$WORLD/vars"
handed() { (cd "$WORLD/macbook/home" && "$SMINOS" list --org --json 2>/dev/null) | grep -q 7a11ce0a; }
world_until handed
