# coding-agents: claude
# Runs through fixtures/sminos-world/run-local.sh (see its README).

pre() {
    command-succeeds 'test -s .world/env.sh && test -s .world/launch'
}

post() {
    command-succeeds 'grep -q 26.04 .world/inbox/gate-keeper'
    command-succeeds '! grep -l 26.04 $(ls -d .world/inbox/* | grep -v /gate-keeper$)'
}
