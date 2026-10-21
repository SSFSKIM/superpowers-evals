# sminos scenarios: the org they run in, and how they run

The `scenarios/sminos-*` scenarios pin how a Claude Code session with the
sminos plugin finds and reaches the other sessions of a sminos org: the
guidance sminos injects at session start on a machine enrolled at a desk hub
(`hooks/smns-guide.sh`, `sminos guide`), and the `sminos` skill split by its
reader (the member's `SKILL.md`, the machine's `references/setup.md`). sminos
was part of the doperpowers plugin until it became a plugin of its own, at
`sminos/` in the doperpowers repository. Design: doperpowers
`docs/doperpowers/specs/2026-10-18-smns-org-directory-design.md` §9.

`world.sh` builds the org a scenario needs: two machines, `macbook` (the
session under test's) and `mini`, simulated on one host as sminos's own
suites do — each with its own HOME and SMINOS_HOME, enrolled through
sminos's hub stand-in (`sminos/tests/hub_standin.py`), each running its
sminos daemon — with live peer sessions whose inboxes record every frame they
receive (`.world/inbox/<alias>`). Nothing touches the real `~/.claude` or any
network beyond 127.0.0.1; `claude`, `launchctl`, `systemctl` and `loginctl`
are stubs that log their calls.

`run-local.sh <scenario> <plugin-root> <out>` runs one scenario on the host:
setup, then a real interactive Claude Code session in tmux (its own server,
`-L sminos-eval`) with the world's HOME, the plugins a session on the owner's
machines has, and the story's first turn typed in. `<plugin-root>` is a
doperpowers tree: its `sminos/` is copied to where the marketplace installs
it, the world HOME's `.claude/plugins/cache/doperpowers/sminos/<version>`, so
the guide names the CLI by a path of the installed shape, and both it and
doperpowers load by `--plugin-dir`. Runs in separate out-dirs can go in
parallel (each world has its own HOME, hub port and tmux session). The run ends when the
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
root per arm, each the commit with its edits to the guide (a line removed, the
hook silenced, a line reworded); its texts are the guide's at the round it was
written for, and it stops when a text is not found exactly once. The round it
carries now is how the guide names the CLI; #98's line ablations are the file
at 3d8df79d. `naming.py --table <run-dir-glob>...` reads how each run's session
named the CLI: its calls, those that failed for the name (a bare `sminos`,
command not found, a wrong path, a variable never set), and the tool calls up
to the first call that ran, per scenario per arm, beside the verdicts.
`regrade.sh <out-dir>...` re-runs finished runs' checks after a check or
`transcript.py` changes. A check that reads Bash commands sees a shell
variable bound to the CLI (`S=…/sminos; $S say …`) as the CLI itself.
