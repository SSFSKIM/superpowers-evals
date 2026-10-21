"""How a run's session named the sminos CLI: the measure of a round that
changes how the guide names it (arms.py).

    python3 naming.py <run-dir>...           one JSON line per run
    python3 naming.py --table <run-dir>...   passes and naming per scenario per arm

A run dir is one run-local.sh run, <...>/<arm>/<scenario>-<n>. From its
transcript (the main loop only) it reads every Bash call that runs the CLI,
in command position, by any name: the path, a bare `sminos`, `sminos.py`, or
a shell variable (`S=…; $S list`, `$S list` with S never set in that
command). A call fails for its naming when its output says the shell could
not find what it named (`command not found`, `no such file or directory`,
exit 126/127) for the CLI or a verb, or when it names the CLI through a
variable the command never sets. Reported per run: the calls, the naming
failures (each with its command), the tool calls up to and including the
first CLI call that ran (all tools, the main loop's order), whether the
sminos skill was loaded, the guide's text as the session read it, and the
verdict."""
import glob
import json
import os
import re
import sys

VERBS = (r"(?:list|who|say|join|charge|find|watch|steer|interrupt|stop|status|guide|send|projects|machines|"
         r"daemon|hub|chat|read|log|model|compact|decide|answer|spawn|retire|seat|project|sync|meta|remove|migrate|"
         r"chart|tui|record|bridge|tag|help|--help|-h)")
HEAD = r"(?:^|[;&|(\n`]|\$\(|\b(?:then|do|else|exec|time|command|python3?|bash|sh)\s)\s*(?:[A-Za-z_]\w*=\S*\s+)*"
PATH_CALL = re.compile(HEAD + r"""["']?(?P<name>[^\s=(`"';|&$]*sminos(?:\.py)?)["']?(?=\s|$|[;)|&])""")
WRAPPED = re.compile(r"""(?<![\w/=.-])["']?(?P<name>[^\s=(`"';|&$]*sminos(?:\.py)?)["']?\s+""" + VERBS + r"\b")   # timeout …, perl … exec @ARGV
VAR_CALL = re.compile(HEAD + r"""["']?\$\{?(?P<var>[A-Za-z_]\w*)\}?["']?\s+""" + VERBS + r"\b")
ASSIGN = re.compile(r"""(?:^|[\s;&|(])(?:export\s+)?([A-Za-z_]\w*)=["']?(\S*sminos)["']?""")
NOT_FOUND = re.compile(r"command not found|no such file or directory|not a directory|permission denied|"
                       r"exit code 12[67]\b", re.I)


def rows(path):
    with open(path) as f:
        for line in f:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(text_of(c.get("text", c.get("content", ""))) if isinstance(c, dict) else str(c)
                         for c in content)
    return str(content or "")


def calls(cmd):
    """The CLI calls in one Bash command: [(how, name)], how one of path, bare, var, unbound."""
    bound = {m.group(1) for m in ASSIGN.finditer(cmd)}
    out = []
    spans = set()
    for rx in (PATH_CALL, WRAPPED):
        for m in rx.finditer(cmd):
            name = m.group("name").lstrip("$(`\"'")
            if "=" in name or m.end("name") in spans:
                continue   # an assignment, S=/…/sminos, not a call; or a call already counted
            spans.add(m.end("name"))
            out.append(("bare" if name.lstrip("./") in ("sminos", "sminos.py") else "path", name))
    for v in bound:
        for m in re.finditer(r"""\$\{?%s\}?(?![A-Za-z0-9_])""" % v, cmd):
            out.append(("var", "$" + v))
    for m in VAR_CALL.finditer(cmd):
        if m.group("var") not in bound:
            out.append(("unbound", "$" + m.group("var")))
    return out


def analyse(run):
    sid = open(os.path.join(run, "session")).read().strip() if os.path.exists(os.path.join(run, "session")) else ""
    tx = os.path.join(run, "transcript", sid + ".jsonl")
    res = {"run": run, "arm": os.path.basename(os.path.dirname(run)),
           "scenario": re.sub(r"-\d+$", "", os.path.basename(run)),
           "verdict": open(os.path.join(run, "verdict")).read().strip() if os.path.exists(os.path.join(run, "verdict")) else "",
           "checks": "", "calls": 0, "failures": [], "first_ok": None, "tools": 0, "skill": False, "guide": ""}
    ck = os.path.join(run, "checks.txt")
    if os.path.exists(ck):
        t = open(ck).read()
        ls = t.splitlines()
        res["checks"] = "%d/%d" % (sum(l.startswith("PASS") for l in ls), sum(l.startswith(("PASS", "FAIL")) for l in ls))
    if not sid or not os.path.exists(tx):
        return res
    uses, results = [], {}
    for r in rows(tx):
        if r.get("isSidechain"):
            continue
        content = (r.get("message") or {}).get("content")
        if not res["guide"] and "sminos: you are" in json.dumps(r):
            s = json.dumps(r)
            i = s.index("sminos: you are")
            res["guide"] = json.loads('"%s"' % re.match(r'((?:[^"\\]|\\.)*)', s[i:]).group(1))
        if not isinstance(content, list):
            continue
        for b in content:
            if not isinstance(b, dict):
                continue
            if r.get("type") == "assistant" and b.get("type") == "tool_use":
                uses.append(b)
            elif b.get("type") == "tool_result":
                results[b.get("tool_use_id")] = (text_of(b.get("content")), bool(b.get("is_error")))
    res["tools"] = len(uses)
    for n, u in enumerate(uses, 1):
        name, inp = u.get("name", ""), u.get("input") or {}
        if name == "Skill" and "sminos" in str(inp.get("skill", "")):
            res["skill"] = True
        if name != "Bash":
            continue
        cmd = str(inp.get("command", ""))
        cs = calls(cmd)
        if not cs:
            continue
        res["calls"] += 1
        out, err = results.get(u.get("id"), ("", False))
        lines = [l for l in out.splitlines() if NOT_FOUND.search(l)]
        named = [l for l in lines if re.search(r"sminos|\b" + VERBS + r"\b", l)
                 or re.search(r"exit code 12[67]", l, re.I)]
        failed = bool(named) or any(how == "unbound" for how, _ in cs)
        if failed:
            res["failures"].append({"tool": n, "how": sorted({h for h, _ in cs}), "command": cmd[:300],
                                    "output": "\n".join(named)[:300]})
        elif res["first_ok"] is None:
            res["first_ok"] = n
    return res


def table(results):
    cells = {}
    for r in results:
        c = cells.setdefault((r["scenario"], r["arm"]), {"runs": 0, "pass": 0, "fail": 0, "first": [], "skill": 0})
        c["runs"] += 1
        c["pass"] += r["verdict"] == "pass"
        c["fail"] += len(r["failures"])
        c["skill"] += r["skill"]
        if r["first_ok"] is not None:
            c["first"].append(r["first_ok"])
    arms = sorted({a for _, a in cells}, key=lambda a: (a != "current", a))
    scens = sorted({s for s, _ in cells})
    print("%-36s" % "scenario" + "".join("%-26s" % a for a in arms))
    tot = {a: {"runs": 0, "pass": 0, "fail": 0, "first": []} for a in arms}
    for s in scens:
        line = "%-36s" % s.replace("sminos-", "")
        for a in arms:
            c = cells.get((s, a))
            if not c:
                line += "%-26s" % "—"
                continue
            f = sum(c["first"]) / len(c["first"]) if c["first"] else float("nan")
            line += "%-26s" % ("%d/%d nf=%d first=%.1f sk=%d" % (c["pass"], c["runs"], c["fail"], f, c["skill"]))
            for k in ("runs", "pass", "fail"):
                tot[a][k] += c[k]
            tot[a]["first"] += c["first"]
        print(line)
    line = "%-36s" % "total"
    for a in arms:
        t = tot[a]
        f = sum(t["first"]) / len(t["first"]) if t["first"] else float("nan")
        line += "%-26s" % ("%d/%d nf=%d first=%.2f" % (t["pass"], t["runs"], t["fail"], f))
    print(line)


def main(argv):
    want_table = argv[:1] == ["--table"]
    runs = [r for a in (argv[1:] if want_table else argv) for r in sorted(glob.glob(a))]
    results = [analyse(r) for r in runs if os.path.isdir(r)]
    if want_table:
        table(results)
    else:
        for r in results:
            print(json.dumps(r))


if __name__ == "__main__":
    main(sys.argv[1:])
