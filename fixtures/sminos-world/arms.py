"""Build the plugin roots of an eval round's arms: an export of a doperpowers
commit, then each arm's edits to the session-start guide (`guide_text` in
the sminos plugin's skills/sminos/scripts/sminos.py) or its hook.

    python3 arms.py <doperpowers-checkout> <commit> <dest-dir> [arm ...]

Each arm lands in <dest-dir>/<arm>, a doperpowers tree with the sminos plugin
at its sminos/, ready to pass to run-local.sh as its <plugin-root>. The texts
below are the guide's at the round they were written for; a later guide needs
them updated, and an arm whose text is not found exactly once stops the build.

The round this file carries: how the guide names the CLI (doperpowers
8d719909, sminos 1.4.0; spec docs/doperpowers/specs/2026-10-18-smns-org-directory-design.md,
Surprises & Discoveries). Every verb line named the CLI by its installed
absolute path; the arms name it once.

    current  the commit as it is: the path on every verb line
    once     the path once, on a line of its own after the frame line; the verb lines say `sminos`
    var      the path once, as a shell assignment `S=<path>`; the verb lines say `$S`
    noguide  the hook prints nothing

Board #98's arms (line ablations against doperpowers 999bd3ee, when sminos
lived inside the doperpowers plugin) are this file at superpowers-evals
3d8df79d."""
import os
import shutil
import subprocess
import sys

REL = "sminos/skills/sminos/scripts/sminos.py"
CLI = '    cli = os.path.join(SCRIPT_DIR, "sminos")\n'
FRAME = '        "To find one or tell it something, use sminos (not on PATH):",\n'

ARMS = {
    "current": [],
    "once": [
        (CLI, '    path, cli = os.path.join(SCRIPT_DIR, "sminos"), "sminos"\n'),
        (FRAME, '        "To find one or tell it something, use sminos. It is not on PATH; run it as",\n'
                '        "  %s" % path,\n'),
    ],
    "var": [
        (CLI, '    path, cli = os.path.join(SCRIPT_DIR, "sminos"), "$S"\n'),
        (FRAME, '        "To find one or tell it something, use sminos, which is not on PATH;'
                ' set S in each command that calls it:",\n'
                '        "  S=%s" % path,\n'),
    ],
}


def main(checkout, commit, dest, arms):
    base = os.path.join(dest, "_base")
    if not os.path.isdir(base):
        os.makedirs(base)
        tar = subprocess.run(["git", "-C", checkout, "archive", "--format=tar", commit],
                             check=True, capture_output=True).stdout
        subprocess.run(["tar", "-x", "-C", base], input=tar, check=True)
    for arm in arms or list(ARMS):
        root = os.path.join(dest, arm)
        shutil.rmtree(root, ignore_errors=True)
        shutil.copytree(base, root, symlinks=True)
        if arm == "noguide":
            with open(os.path.join(root, "sminos/hooks/smns-guide.sh"), "w") as f:
                f.write("#!/usr/bin/env bash\n# eval arm: no SessionStart guide at all\nexit 0\n")
            print(arm, root)
            continue
        if arm not in ARMS:
            sys.exit("unknown arm: %s" % arm)
        p = os.path.join(root, REL)
        src = open(p).read()
        for old, new in ARMS[arm]:
            if src.count(old) != 1:
                sys.exit("%s: a text to edit is not in sminos.py exactly once: %r" % (arm, old))
            src = src.replace(old, new)
        open(p, "w").write(src)
        print(arm, root)


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:])
