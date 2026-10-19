"""Build the plugin roots of an eval round's arms: an export of a doperpowers
commit, then each arm's one edit to the session-start guide (`guide_text` in
skills/sminos/scripts/sminos.py) or its hook.

    python3 arms.py <doperpowers-checkout> <commit> <dest-dir> [arm ...]

Each arm lands in <dest-dir>/<arm>, ready to pass to run-local.sh as its
<plugin-root>. The line texts below are the guide's at doperpowers 999bd3ee
(7.188.2), the round of board #98 (doperpowers spec
docs/doperpowers/specs/2026-10-18-smns-org-directory-design.md, Surprises &
Discoveries); a later guide needs them updated, and an arm whose line is not
found exactly once stops the build.

Arms: after (the commit as it is), noguide (the hook prints nothing),
abl-<line> (that one line removed), abl-list-find (both), join-v2 (the join
line reworded), v2-abl-identity (join-v2 without the identity line), final
(join-v2 without the find line: the guide this round shipped)."""
import os
import shutil
import subprocess
import sys

REL = "skills/sminos/scripts/sminos.py"
IDENTITY = ('        "sminos: you are %s in project %s on machine %s: %s. A `cd` does not change your project."\n'
            '        % (who, project.name, enrollment()["machine"], where),\n')
LIST = '        "  %s list            your project\'s sessions; --here this machine\'s, --org every session" % cli,\n'
FIND = '        "  %s find <words>    sessions whose repository, branch, alias or in-charge line match" % cli,\n'
WHO = '        "  %s who <commit|PR> the session a commit or PR names in its Sminos-Session line, and how to reach it" % cli,\n'
SAY = ('        \'  %s say "@<short> ..."   reaches that session wherever it runs, as does "@<project>/<alias> ...";\'\n'
       '        " a bare @alias reaches only your project" % cli,\n')
CHARGE_OLD = ("    ] + join + [\n"
              '        \'  %s charge "<line>" what you are in charge of, shown beside you in every list\' % cli,\n'
              "    ])\n")
CHARGE_NEW = "    ] + join)\n"
JOIN_OLD = ('    join = [] if seat else ["  %s join <project>  when your standing work belongs to another project"\n'
            '                            " (once, not per repository you visit)" % cli]')
JOIN_NEW = ('    join = [] if seat else ["  %s join <project>  when your directory files you in the wrong project (a scratch copy)"\n'
            '                            " or your standing work belongs to another; once, not per repository you visit" % cli]')

ARMS = {
    "after": [],
    "abl-identity": [(IDENTITY, "")],
    "abl-list": [(LIST, "")],
    "abl-find": [(FIND, "")],
    "abl-list-find": [(LIST, ""), (FIND, "")],
    "abl-who": [(WHO, "")],
    "abl-say": [(SAY, "")],
    "abl-charge": [(CHARGE_OLD, CHARGE_NEW)],
    "join-v2": [(JOIN_OLD, JOIN_NEW)],
    "v2-abl-identity": [(JOIN_OLD, JOIN_NEW), (IDENTITY, "")],
    "final": [(JOIN_OLD, JOIN_NEW), (FIND, "")],
}


def main(checkout, commit, dest, arms):
    base = os.path.join(dest, "_base")
    if not os.path.isdir(base):
        os.makedirs(base)
        tar = subprocess.run(["git", "-C", checkout, "archive", "--format=tar", commit],
                             check=True, capture_output=True).stdout
        subprocess.run(["tar", "-x", "-C", base], input=tar, check=True)
    for arm in arms or ["after", "noguide"] + [a for a in ARMS if a != "after"]:
        root = os.path.join(dest, arm)
        shutil.rmtree(root, ignore_errors=True)
        shutil.copytree(base, root, symlinks=True)
        if arm == "noguide":
            with open(os.path.join(root, "hooks/smns-guide.sh"), "w") as f:
                f.write("#!/usr/bin/env bash\n# eval arm: no SessionStart guide at all\nexit 0\n")
            print(arm, root)
            continue
        if arm not in ARMS:
            sys.exit("unknown arm: %s" % arm)
        p = os.path.join(root, REL)
        src = open(p).read()
        for old, new in ARMS[arm]:
            if src.count(old) != 1:
                sys.exit("%s: a line to edit is not in guide_text exactly once" % arm)
            src = src.replace(old, new)
        open(p, "w").write(src)
        print(arm, root)


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:])
