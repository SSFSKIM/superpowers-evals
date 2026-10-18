# coding-agents: claude
# Runs through fixtures/sminos-world/run-local.sh (see its README).

pre() {
    command-succeeds 'test -s .world/env.sh && test -s .world/launch'
}

post() {
    command-succeeds 'grep -qi '\''flag names'\'' .world/inbox/parser'
    command-succeeds 'python3 "$QUORUM_SCENARIO_DIR/../../fixtures/sminos-world/transcript.py" bash '\''sminos[^|;&]* (steer|interrupt|say|send) '\'''
    command-succeeds '! python3 "$QUORUM_SCENARIO_DIR/../../fixtures/sminos-world/transcript.py" tool SendMessage'
}
