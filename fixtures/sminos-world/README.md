# sminos scenarios: the org they run in, and how they run

The `scenarios/sminos-*` scenarios pin how a Claude Code session with the
doperpowers plugin finds and reaches the other sessions of a sminos org: the
guidance doperpowers injects at session start on a machine enrolled at a desk
hub (`hooks/smns-guide.sh`, `sminos guide`), and the `sminos` skill split by
its reader (the member's `SKILL.md`, the machine's `references/setup.md`).
Design: doperpowers `docs/doperpowers/specs/2026-10-18-smns-org-directory-design.md` §9.

`world.sh` builds the org a scenario needs: two machines, `macbook` (the
session under test's) and `mini`, simulated on one host as doperpowers' own
suites do — each with its own HOME and SMINOS_HOME, enrolled through
doperpowers' hub stand-in (`tests/sminos/hub_standin.py`), each running its
sminos daemon — with live peer sessions whose inboxes record every frame they
receive (`.world/inbox/<alias>`). Nothing touches the real `~/.claude` or any
network beyond 127.0.0.1; `claude`, `launchctl`, `systemctl` and `loginctl`
are stubs that log their calls.

`run-local.sh <scenario> <plugin-root> <out>` runs one scenario on the host:
setup, then a real interactive Claude Code session in tmux (its own server,
`-L sminos-eval`) with the world's HOME, the plugin from `<plugin-root>`
(`--plugin-dir`), and the story's first turn typed in; the run ends when the
engine's record says the session is idle again. `post()` from the scenario's
`checks.sh` then grades it, reading `.world/` and the session's transcript
(`transcript.py`). Auth is the host's `ANTHROPIC_BASE_URL` /
`ANTHROPIC_AUTH_TOKEN` (or `ANTHROPIC_API_KEY`), passed through, never
written down.

The scenarios are `status: draft` for quorum: its launcher pins the agent's
HOME to the run's throwaway home, which setup.sh cannot see, so the world's
SMINOS_HOME and the peers' engine records cannot be put where the session
under test reads them. Running them under quorum needs that seam (an agent
home exposed to setup, or setup-provided env for the launcher).

Before/after: run each scenario with `<plugin-root>` at the doperpowers
commit before the change and at the change itself.

Ablations: `arms.py <doperpowers-checkout> <commit> <dest>` builds one plugin
root per arm, each the commit with one edit to the guide (a line removed, the
hook silenced, a line reworded); its line texts are the guide's at the round
it was written for, and it stops when a line is not found exactly once.
`regrade.sh <out-dir>...` re-runs finished runs' checks after a check or
`transcript.py` changes. A check that reads Bash commands sees a shell
variable bound to the CLI (`S=…/sminos; $S say …`) as the CLI itself.
