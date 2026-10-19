#!/usr/bin/env bash
# The sminos org a scenario runs in: two machines enrolled in one desk-hub org,
# simulated on one host as doperpowers' own suites do (tests/sminos/test-address.sh):
# a hub stand-in (tests/sminos/hub_standin.py) on 127.0.0.1, and for each machine
# its own HOME and SMINOS_HOME, enrolled through the stand-in, with its sminos
# daemon running. The session under test runs on `macbook`; the peers are live
# sessions whose inboxes write every frame they receive to $WORLD/inbox/<alias>.
#
#   source world.sh; world_up <world-dir> <plugin-root>
#
# Everything lives under the world directory: nothing reads or writes the real
# ~/.claude, and nothing reaches a network beyond 127.0.0.1. `claude`,
# `launchctl`, `systemctl` and `loginctl` are stubs on the PATH every machine
# and the session under test see, so no verb starts a real session or loads a
# real service; the stubs log their calls to $WORLD/calls.
#
# The org (projects and who works where):
#   doperpowers  hub   macbook: parser (in charge of sminos list's rows and the --state filter)
#                      mini:    executor (ticket #93: the org directory)
#   ci-kit       hub   mini:    gate-keeper (the CI gate: the runner image and ci-gate),
#                               docs (ci-kit's README and adoption docs)
#   MAWS         hub   mini:    desk-web (the desk's org view), executor (ticket #212: desk deploys)
#   mini         machine (the mini's strays): mini-7c, in the mini's home directory (the devcloud image build)
#   macbook      machine (the macbook's strays)
# On macbook, checkouts of doperpowers, ci-kit and MAWS (each with its committed .smns), cua (none), and
# maws-scratch (a copy of MAWS's desk-web sources without .smns) under ~/src.
set -euo pipefail

world_gitq() { git -c user.name=t -c user.email=t@t -c init.defaultBranch=main "$@"; }
world_until() { local end=$((SECONDS + 60)); until "$@"; do [ "$SECONDS" -ge "$end" ] && return 1; sleep 0.1; done; }

world_as() { # machine — this shell speaks as that machine
  export HOME="$WORLD/$1/home" SMINOS_HOME="$WORLD/$1/s" STUB_STATE="$WORLD/$1/stub" DAEMON_HOST="$1"
  mkdir -p "$HOME/.claude/sessions" "$STUB_STATE"
}

world_stubs() {
  mkdir -p "$WORLD/bin" "$WORLD/calls"
  cat > "$WORLD/bin/claude" <<'STUB'
#!/usr/bin/env bash
# The eval world's `claude` for sminos's own calls: no session is ever started.
echo "claude $*" >> "$WORLD_CALLS/claude"
case "${1:-}" in agents) echo "[]" ;; esac
exit 0
STUB
  for tool in launchctl systemctl loginctl; do
    printf '#!/usr/bin/env bash\necho "%s $*" >> "$WORLD_CALLS/%s"\nexit 0\n' "$tool" "$tool" > "$WORLD/bin/$tool"
  done
  chmod +x "$WORLD/bin/"*
}

world_inbox_server() {
  cat > "$WORLD/inbox.py" <<'PY'
# A peer's inbox, as Claude Code serves one: each frame (one JSON line) is
# recorded as it arrives, nothing is ever written back, and the connection is
# closed once the sender has ended its side. The engine's own SendMessage client
# never reads its socket: a byte written back keeps that socket from closing, and
# the send is reported failed ("Failed to send to <peer>.") at its 5 s timeout
# although the frame arrived — the model then sends again (doperpowers #100). A
# connection that sends nothing (the engine's liveness probe) records nothing.
import socket, sys, threading
srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
srv.bind(sys.argv[1])
srv.listen(8)
lock = threading.Lock()

def record(line):
    with lock, open(sys.argv[2], "ab") as f:
        f.write(line + b"\n\n")

def serve(c):
    buf = b""
    try:
        while True:
            chunk = c.recv(65536)
            if not chunk:
                break
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                if line.strip():
                    record(line)
        if buf.strip():
            record(buf)
    except OSError:
        pass
    finally:
        c.close()

while True:
    c, _ = srv.accept()
    threading.Thread(target=serve, args=(c,), daemon=True).start()
PY
}

world_ctl() { # token | code <machine>
  python3 - "$WORLD/hub.port" "$@" <<'PY'
import base64, http.client, json, sys
port = int(open(sys.argv[1]).read())
def call(method, path, body=None):
    c = http.client.HTTPConnection("127.0.0.1", port, timeout=30)
    c.request(method, path, body=None if body is None else json.dumps(body), headers={"Content-Type": "application/json"})
    r = c.getresponse()
    return r.status, json.loads(r.read() or b"{}")
cmd = sys.argv[2]
token = call("POST", "/control/enrollment", {})[1]["token"]
if cmd == "token":
    print(token)
elif cmd == "code":
    key = base64.urlsafe_b64encode(bytes(range(32))).rstrip(b"=").decode()
    body = json.dumps({"hub": "http://127.0.0.1:%d" % port, "org": "org-1", "token": token,
                       "machine": sys.argv[3], "key": key}, separators=(",", ":")).encode()
    print("smns-enroll-v1." + base64.urlsafe_b64encode(body).rstrip(b"=").decode())
PY
}

world_smns() { # dir name id — a committed hub .smns naming only the org
  printf '{"project": "%s", "name": "%s", "remote": "", "hub": {"org": "org-1"}}\n' "$3" "$2" > "$1/.smns"
}

world_repo() { # dir name [id] — a git repository with a README, and a .smns when an id is given
  mkdir -p "$1"
  world_gitq init -q "$1"
  printf '# %s\n' "$2" > "$1/README.md"
  [ -n "${3:-}" ] && world_smns "$1" "$2" "$3"
  world_gitq -C "$1" add -A
  world_gitq -C "$1" commit -qm "initial"
}

world_peer() { # alias session dir [status] [key] — a live session on this machine, its inbox recording frames
  local alias=$1 sid=$2 dir=$3 status=${4:-idle} key=${5:-$1}
  local sock="$WORLD/socks/$key.sock"
  mkdir -p "$WORLD/socks" "$WORLD/inbox"
  : > "$WORLD/inbox/$key"
  python3 "$WORLD/inbox.py" "$sock" "$WORLD/inbox/$key" &
  local pid=$!
  echo "$pid" >> "$WORLD/pids"
  world_until test -S "$sock"
  printf '{"pid":%s,"sessionId":"%s","name":"%s","nameSource":"user","kind":"interactive","status":"%s","cwd":"%s","messagingSocketPath":"%s","entrypoint":"cli"}\n' \
    "$pid" "$sid" "$alias" "$status" "$dir" "$sock" > "$HOME/.claude/sessions/$pid.json"
  local tx="$HOME/.claude/projects/p-$sid/$sid.jsonl"
  mkdir -p "$(dirname "$tx")"
  printf '{"type":"user","uuid":"%s-u1","isSidechain":false,"sessionId":"%s","cwd":"%s","origin":{"kind":"human"},"message":{"role":"user","content":"go"}}\n' \
    "${sid:0:8}" "$sid" "$dir" > "$tx"
  printf '%s=%s\n' "$(printf '%s' "$key" | tr 'a-z-' 'A-Z_')_SID" "$sid" >> "$WORLD/ids.env"
}

world_charge() { # session dir line — the session sets its own in-charge line
  (cd "$2" && CLAUDE_CODE_SESSION_ID="$1" "$SMINOS" charge "$3" >/dev/null)
}

world_daemon() {
  "$SMINOS" daemon run --interval 1 >> "$SMINOS_HOME/daemon.out" 2>&1 &
  echo "$!" >> "$WORLD/pids"
  echo "$!" > "$WORLD/$DAEMON_HOST.daemon-pid"
}

world_enroll() { # machine
  "$SMINOS" hub enroll <<<"$(world_ctl code "$1")" >/dev/null
}

world_up() { # world-dir plugin-root
  # The world itself lives at a short path, the world-dir a link to it: a unix
  # socket's path (an inbox, a session's bridge under SMINOS_HOME) is bounded
  # at about 104 bytes.
  [ -e "$1" ] || ln -s "$(mktemp -d /tmp/sw.XXXXXX)" "$1"
  WORLD="$(cd "$1" && pwd -P)"
  PLUGIN="$(cd "$2" && pwd -P)"
  export WORLD PLUGIN WORLD_CALLS="$WORLD/calls"
  SMINOS="$PLUGIN/skills/sminos/scripts/sminos"
  : > "$WORLD/pids"
  : > "$WORLD/ids.env"
  world_stubs
  world_inbox_server
  unset CLAUDE_CODE_SESSION_ID SMNS_INTERNAL DAEMON_HOME CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR
  export PATH="$WORLD/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" SMINOS_DERIVE_EVERY=0

  python3 "$PLUGIN/tests/sminos/hub_standin.py" "$WORLD/hub.port" cid-0 secret-0 1000 >> "$WORLD/hub.out" 2>&1 &
  echo "$!" >> "$WORLD/pids"
  world_until test -s "$WORLD/hub.port"

  local DP CK MW
  DP=4e1d0c4a-6f62-4f0e-9a51-0d0e0e0e0001   # doperpowers
  CK=4e1d0c4a-6f62-4f0e-9a51-0d0e0e0e0002   # ci-kit
  MW=4e1d0c4a-6f62-4f0e-9a51-0d0e0e0e0003   # MAWS
  printf 'DOPERPOWERS_ID=%s\nCIKIT_ID=%s\nMAWS_ID=%s\n' "$DP" "$CK" "$MW" >> "$WORLD/ids.env"

  # ---- the mini: ci-kit and MAWS checkouts, a doperpowers one, a stray in its home
  world_as mini
  world_enroll mini
  world_repo "$HOME/src/ci-kit" ci-kit "$CK"
  world_repo "$HOME/src/MAWS" MAWS "$MW"
  world_repo "$HOME/src/doperpowers" doperpowers "$DP"
  world_peer gate-keeper 7a11ce01-0000-4000-8000-00000000c101 "$HOME/src/ci-kit"
  world_peer docs 7a11ce02-0000-4000-8000-00000000c102 "$HOME/src/ci-kit"
  world_peer desk-web 7a11ce03-0000-4000-8000-00000000a103 "$HOME/src/MAWS"
  world_peer executor 7a11ce04-0000-4000-8000-00000000a104 "$HOME/src/MAWS" idle executor-maws
  world_peer mini-7c 7a11ce05-0000-4000-8000-00000000e105 "$HOME"
  world_peer executor 7a11ce06-0000-4000-8000-00000000d106 "$HOME/src/doperpowers" idle executor-doperpowers
  "$SMINOS" daemon tick >/dev/null 2>&1 || true
  world_charge 7a11ce01-0000-4000-8000-00000000c101 "$HOME/src/ci-kit" "the CI gate: the runner image and ci-gate"
  world_charge 7a11ce02-0000-4000-8000-00000000c102 "$HOME/src/ci-kit" "ci-kit README and adoption docs"
  world_charge 7a11ce03-0000-4000-8000-00000000a103 "$HOME/src/MAWS" "desk-web: the org view"
  world_charge 7a11ce04-0000-4000-8000-00000000a104 "$HOME/src/MAWS" "ticket #212: desk deploys"
  world_charge 7a11ce05-0000-4000-8000-00000000e105 "$HOME" "the devcloud image build"
  world_charge 7a11ce06-0000-4000-8000-00000000d106 "$HOME/src/doperpowers" "ticket #93: the org directory"
  world_daemon

  # ---- the macbook: the session under test's machine
  world_as macbook
  world_enroll macbook
  world_repo "$HOME/src/doperpowers" doperpowers "$DP"
  world_repo "$HOME/src/ci-kit" ci-kit "$CK"
  world_repo "$HOME/src/MAWS" MAWS "$MW"
  world_repo "$HOME/src/cua" cua
  mkdir -p "$HOME/src/maws-scratch/apps/desk-web/src"
  printf '# MAWS (scratch copy)\n\nThe desk: apps/desk-hub (the hub), apps/desk-web (the web desk).\n' > "$HOME/src/maws-scratch/README.md"
  printf 'export const orgView = () => null;\n' > "$HOME/src/maws-scratch/apps/desk-web/src/org-view.ts"
  world_peer parser 7a11ce07-0000-4000-8000-00000000d107 "$HOME/src/doperpowers" "${PARSER_STATUS:-idle}"
  "$SMINOS" daemon tick >/dev/null 2>&1 || true
  world_charge 7a11ce07-0000-4000-8000-00000000d107 "$HOME/src/doperpowers" "sminos list's rows and the --state filter"
  (cd "$HOME/src/doperpowers" && "$SMINOS" status parser "rewriting the --state filter to take comma lists" >/dev/null)
  world_daemon

  # Both machines see every org project and each other's sessions.
  local seen
  seen() { (cd "$WORLD/macbook/home" && "$SMINOS" list --org --json 2>/dev/null) | grep -q 7a11ce05; }
  world_until seen || echo "world: the mini's sessions did not reach the macbook" >&2

  # What the session under test runs with.
  cat > "$WORLD/env.sh" <<ENV
export HOME="$WORLD/macbook/home" SMINOS_HOME="$WORLD/macbook/s" DAEMON_HOST=macbook
export PATH="$WORLD/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" WORLD_CALLS="$WORLD/calls"
ENV
}

world_down() { # world-dir
  local w=$1
  [ -f "$w/pids" ] || return 0
  while read -r pid; do kill "$pid" 2>/dev/null || true; done < "$w/pids"
}
