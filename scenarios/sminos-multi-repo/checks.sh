# coding-agents: claude
# Runs through fixtures/sminos-world/run-local.sh (see its README).

pre() {
    command-succeeds 'test -s .world/env.sh && test -s .world/launch'
}

post() {
    command-succeeds 'python3 "$QUORUM_SCENARIO_DIR/../../fixtures/sminos-world/transcript.py" bash-at-most '\''sminos[^|;&]* join +([A-Za-z0-9]|--cwd)'\'' 1'
    command-succeeds '! python3 "$QUORUM_SCENARIO_DIR/../../fixtures/sminos-world/transcript.py" bash '\''sminos[^|;&]* join (ci-kit|cua|doperpowers)'\'''
    command-succeeds 'grep -q "$(sed -n '\''s/^MAWS_ID=//p'\'' .world/ids.env)" ".world/macbook/s/sessions/$SMINOS_SESSION.json"'
}
