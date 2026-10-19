#!/usr/bin/env bash
set -euo pipefail
# The org this scenario runs in: fixtures/sminos-world/world.sh (two enrolled
# machines on a hub stand-in, live peers whose inboxes record what they get),
# grown toward an org of the owner's size: 30 more live sessions across the
# projects and both machines, each in charge of work unrelated to CI.
# shellcheck source=/dev/null
source "${SMINOS_WORLD_LIB:-$QUORUM_REPO_ROOT/fixtures/sminos-world/world.sh}"
world_up "$QUORUM_WORKDIR/.world" "$SUPERPOWERS_ROOT"
echo "$WORLD/macbook/home/src/doperpowers" > "$WORLD/launch"

work=("the desk's push notices" "ticket #301: hub storage quotas" "the org view's sort order" "desk-web's settings page"
      "ticket #77: board labels" "the to-human plugin's band" "kairos mode's footer button" "the appeal judge's prompt"
      "ticket #412: enrollment codes" "the bridge's resync" "sminos chat's paging" "the archive's schedule"
      "ticket #95: the devenv skill" "the journal's Telegram outlet" "cua's remote relay" "the playwright profile tokens")
n=0
for machine in mini macbook; do
  world_as "$machine"
  for repo in MAWS doperpowers ci-kit; do
    [ "$machine" = macbook ] && [ "$repo" = ci-kit ] && continue
    for _ in 1 2 3 4 5 6; do
      [ "$n" -ge 32 ] && break
      i=$(printf '%02x' $((n + 16)))
      sid="7b0000$i-0000-4000-8000-0000000000$i"
      world_peer "w$i" "$sid" "$HOME/src/$repo" idle "w$i"
      n=$((n + 1))
    done
  done
  "$SMINOS" daemon tick >/dev/null 2>&1 || true
done
n=0
for machine in mini macbook; do
  world_as "$machine"
  for repo in MAWS doperpowers ci-kit; do
    [ "$machine" = macbook ] && [ "$repo" = ci-kit ] && continue
    for _ in 1 2 3 4 5 6; do
      [ "$n" -ge 32 ] && break
      i=$(printf '%02x' $((n + 16)))
      world_charge "7b0000$i-0000-4000-8000-0000000000$i" "$HOME/src/$repo" "${work[$((n % 16))]}"
      n=$((n + 1))
    done
  done
done
world_as macbook
grown() { [ "$(cd "$WORLD/macbook/home" && "$SMINOS" list --org --json 2>/dev/null | grep -o '"session": *"7b' | wc -l)" -ge 30 ]; }
world_until grown
