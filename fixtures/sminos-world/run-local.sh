#!/usr/bin/env bash
# Run one sminos scenario on this host against a real, interactive Claude Code
# session, and grade it with the scenario's own post() checks.
#
#   run-local.sh <scenario-dir> <plugin-root> <out-dir>
#
# The scenario's setup.sh builds the org (world.sh) under <out-dir>/work/.world
# with <plugin-root> as the doperpowers plugin; the session under test then
# starts in tmux (its own server, -L sminos-eval) from the directory setup.sh
# wrote to .world/launch, with the world's HOME, SMINOS_HOME and PATH, the
# plugin loaded from <plugin-root> (--plugin-dir), --dangerously-skip-permissions
# (stubs stand in for claude, launchctl, systemctl and loginctl), and any
# flags setup.sh wrote to .world/claude-args. The story's first turn (the
# blockquote after "First turn") is typed in; the run ends when the session's
# engine record says it is idle again, or after QUORUM_MAX (default 600 s).
# Auth: the host's ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN (or ANTHROPIC_API_KEY),
# passed through, never written down. CLAUDE_BIN overrides the engine binary.
set -euo pipefail
SCEN="$(cd "$1" && pwd -P)"
ROOT="$(cd "$2" && pwd -P)"
OUT="$3"
HERE="$(cd "$(dirname "$0")" && pwd -P)"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude-bin 2>/dev/null || readlink -f "$HOME/.local/bin/claude")}"
MAX="${QUORUM_MAX:-600}"
NAME="$(basename "$SCEN")-$$"
TM=(tmux -L sminos-eval)

rm -rf "$OUT"
mkdir -p "$OUT/work"
OUT="$(cd "$OUT" && pwd -P)"
WORK="$OUT/work"

W="$WORK/.world"
cleanup() {
  "${TM[@]}" kill-session -t "$NAME" 2>/dev/null || true
  # shellcheck source=/dev/null
  source "$HERE/world.sh"; world_down "$W"
}
trap cleanup EXIT

# Setup, as quorum runs it: from the workdir, QUORUM_* and SUPERPOWERS_ROOT set.
if ! (cd "$WORK" && env QUORUM_WORKDIR="$WORK" QUORUM_SCENARIO_DIR="$SCEN" SUPERPOWERS_ROOT="$ROOT" \
  SMINOS_WORLD_LIB="$HERE/world.sh" bash "$SCEN/setup.sh") > "$OUT/setup.log" 2>&1; then
  echo indeterminate > "$OUT/verdict"
  echo "$(basename "$SCEN") indeterminate (setup failed: $OUT/setup.log)"
  exit 2
fi

# shellcheck source=/dev/null
source "$W/env.sh"
LAUNCH="$(cat "$W/launch")"
EXTRA="$(cat "$W/claude-args" 2>/dev/null || true)"
mkdir -p "$HOME/.claude"
python3 - "$LAUNCH" "$HOME" <<'PY'
import json, os, sys
launch, home = sys.argv[1], sys.argv[2]
trust = {"hasTrustDialogAccepted": True, "projectOnboardingSeenCount": 1}
path = os.path.join(home, ".claude.json")
d = json.load(open(path)) if os.path.exists(path) else {}
d["hasCompletedOnboarding"] = True
d.setdefault("projects", {})[launch] = trust
json.dump(d, open(path, "w"))
sp = os.path.join(home, ".claude", "settings.json")
s = json.load(open(sp)) if os.path.exists(sp) else {}
s["skipDangerousModePermissionPrompt"] = True
json.dump(s, open(sp, "w"))
PY

# The first turn: the story's blockquote after "First turn".
# {{NAME}} is filled from .world/vars (NAME=value lines setup.sh wrote).
PROMPT="$(python3 - "$SCEN/story.md" "$W/vars" <<'PY'
import os, re, sys
text = open(sys.argv[1]).read().split("## Acceptance Criteria")[0]
after = text[text.index("First turn"):]
quote = re.search(r"((?:^>.*\n?)+)", after, re.M).group(1)
prompt = " ".join(line[1:].strip() for line in quote.splitlines()).strip()
if os.path.exists(sys.argv[2]):
    for line in open(sys.argv[2]):
        k, _, v = line.rstrip("\n").partition("=")
        prompt = prompt.replace("{{%s}}" % k, v)
print(prompt)
PY
)"
printf '%s\n' "$PROMPT" > "$OUT/prompt.txt"

cat > "$OUT/launch.sh" <<SH
#!/usr/bin/env bash
exec env -i HOME="$HOME" SMINOS_HOME="$SMINOS_HOME" DAEMON_HOST="$DAEMON_HOST" PATH="$PATH" \\
  WORLD_CALLS="$WORLD_CALLS" TERM=xterm-256color LANG=en_US.UTF-8 \\
  ANTHROPIC_BASE_URL="\${ANTHROPIC_BASE_URL:-}" ANTHROPIC_AUTH_TOKEN="\${ANTHROPIC_AUTH_TOKEN:-}" \\
  ANTHROPIC_API_KEY="\${ANTHROPIC_API_KEY:-}" \\
  ANTHROPIC_DEFAULT_OPUS_MODEL="\${ANTHROPIC_DEFAULT_OPUS_MODEL:-}" ANTHROPIC_DEFAULT_SONNET_MODEL="\${ANTHROPIC_DEFAULT_SONNET_MODEL:-}" \\
  ANTHROPIC_DEFAULT_HAIKU_MODEL="\${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}" ANTHROPIC_DEFAULT_FABLE_MODEL="\${ANTHROPIC_DEFAULT_FABLE_MODEL:-}" \\
  "$CLAUDE_BIN" --dangerously-skip-permissions --plugin-dir "$ROOT" --model "\${EVAL_MODEL:-opus}" $EXTRA
SH
chmod +x "$OUT/launch.sh"

record() { # → the engine record of the session under test, as JSON, or nothing
  python3 - "$HOME/.claude/sessions" <<'PY'
import glob, json, os, sys
best = None
for p in glob.glob(os.path.join(sys.argv[1], "*.json")):
    try:
        d = json.load(open(p))
    except Exception:
        continue
    if d.get("version") and d.get("entrypoint") == "cli":   # the real engine's record (the world's peers carry no version)
        if best is None or d.get("startedAt", 0) > best.get("startedAt", 0):
            best = d
print(json.dumps(best) if best else "")
PY
}
status() { record | python3 -c 'import json, sys; t = sys.stdin.read().strip(); print(json.loads(t).get("status", "") if t else "")'; }

"${TM[@]}" new-session -d -s "$NAME" -x 220 -y 60 -c "$LAUNCH" "$OUT/launch.sh"
end=$((SECONDS + 90))
until [ "$(status)" = idle ] && "${TM[@]}" capture-pane -p -t "$NAME" | grep -q '❯'; do
  [ "$SECONDS" -ge "$end" ] && { echo "the session never became ready" >&2; "${TM[@]}" capture-pane -p -t "$NAME" > "$OUT/pane.txt"; exit 2; }
  sleep 1
done
"${TM[@]}" send-keys -t "$NAME" -l "$PROMPT"
sleep 1
"${TM[@]}" send-keys -t "$NAME" Enter
# An Enter the terminal swallowed leaves the prompt typed and unsent (seen once:
# a run timed out idle): one more, if no turn has started within 20 s.
for _ in $(seq 1 20); do [ "$(status)" = busy ] && break; sleep 1; done
[ "$(status)" = busy ] || "${TM[@]}" send-keys -t "$NAME" Enter
started=$SECONDS
seen_busy=0
quiet=0
while :; do
  sleep 3
  s="$(status)"
  [ "$s" = busy ] && seen_busy=1
  if [ "$seen_busy" = 1 ] && [ "$s" != busy ]; then quiet=$((quiet + 1)); else quiet=0; fi
  [ "$quiet" -ge 3 ] && break
  [ $((SECONDS - started)) -ge "$MAX" ] && { echo "timed out after ${MAX}s" > "$OUT/timeout"; break; }
done
"${TM[@]}" capture-pane -p -S -400 -t "$NAME" > "$OUT/pane.txt"
SID="$(record | python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["sessionId"])')"
echo "$SID" > "$OUT/session"
# The session's transcript and its subagents', as the checks read them.
mkdir -p "$OUT/transcript"
find "$HOME/.claude/projects" -path "*$SID*" -name '*.jsonl' -exec cp {} "$OUT/transcript/" \;
cp -R "$W/calls" "$OUT/calls" 2>/dev/null || true
cp -R "$W/inbox" "$OUT/inbox" 2>/dev/null || true

# Grade: the scenario's post() under a minimal prelude (quorum's verbs it uses).
(
  cd "$WORK"
  export QUORUM_WORKDIR="$WORK" QUORUM_SCENARIO_DIR="$SCEN" SMINOS_TRANSCRIPTS="$OUT/transcript" SMINOS_SESSION="$SID"
  command-succeeds() { if bash -c "$1" >/dev/null 2>&1; then echo "PASS $1"; else echo "FAIL $1"; fi; }
  # shellcheck source=/dev/null
  source "$SCEN/checks.sh"
  post
) > "$OUT/checks.txt" 2>&1 || true
if grep -q '^FAIL' "$OUT/checks.txt"; then verdict=fail; else verdict=pass; fi
[ -e "$OUT/timeout" ] && verdict=indeterminate
echo "$verdict" > "$OUT/verdict"
echo "$(basename "$SCEN") $verdict ($(grep -c '^PASS' "$OUT/checks.txt") pass, $(grep -c '^FAIL' "$OUT/checks.txt") fail) $OUT"
