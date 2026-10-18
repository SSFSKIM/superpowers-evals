# coding-agents: claude
# Runs through fixtures/sminos-world/run-local.sh (see its README).

pre() {
    command-succeeds 'test -s .world/env.sh && test -s .world/launch'
}

post() {
    command-succeeds 'grep -q '\''"machine": *"studio"'\'' .world/studio/s/daemon/hub.json'
    command-succeeds '! python3 "$QUORUM_SCENARIO_DIR/../../fixtures/sminos-world/transcript.py" bash '\''hub enroll[^|<]*smns-enroll-v1'\'''
    command-succeeds 'grep -q '\''"org": *"org-1"'\'' .world/studio/home/src/tools/.smns && ! grep -q '\''"url"'\'' .world/studio/home/src/tools/.smns'
    command-succeeds 'test -f .world/studio/home/Library/LaunchAgents/com.doperpowers.sminos-daemon.plist'
}
