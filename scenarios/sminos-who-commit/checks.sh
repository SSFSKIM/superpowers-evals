# coding-agents: claude
# Runs through fixtures/sminos-world/run-local.sh (see its README).

pre() {
    command-succeeds 'test -s .world/env.sh && test -s .world/launch'
}

post() {
    command-succeeds 'grep -q 26.04 .world/inbox/docs-2'
    command-succeeds '! grep -l 26.04 .world/inbox/gate-keeper .world/inbox/desk-web .world/inbox/executor-maws .world/inbox/executor-doperpowers .world/inbox/mini-7c .world/inbox/parser'
}
