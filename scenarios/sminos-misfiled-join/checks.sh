# coding-agents: claude
# Runs through fixtures/sminos-world/run-local.sh (see its README).

pre() {
    command-succeeds 'test -s .world/env.sh && test -s .world/launch'
}

post() {
    command-succeeds 'grep -qi '\''empty state'\'' .world/inbox/desk-web'
    command-succeeds 'grep -q "$(sed -n '\''s/^MAWS_ID=//p'\'' .world/ids.env)" ".world/macbook/s/sessions/$SMINOS_SESSION.json"'
}
