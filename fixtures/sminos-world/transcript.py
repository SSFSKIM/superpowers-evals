"""Questions a sminos scenario's checks ask of the session under test's transcript.

    python3 transcript.py <query> [args...]      exit 0 when the answer is yes

The transcript is $SMINOS_TRANSCRIPTS/$SMINOS_SESSION.jsonl (the main loop only;
a subagent's tool calls are its own). Queries:

    bash <regex>             a Bash command matches (re.search)
    bash-count <regex> <n>   exactly n Bash commands match
    bash-at-most <regex> <n> at most n Bash commands match
    tool <name>              a tool of that name was called (Skill's skill name counts as "Skill:<name>")
    read <regex>             a Read's file_path, or a Bash command reading a file, matches
    final <regex>            the session's last assistant text matches (case-insensitive)
"""
import json
import os
import re
import sys


def rows():
    path = os.path.join(os.environ["SMINOS_TRANSCRIPTS"], os.environ["SMINOS_SESSION"] + ".jsonl")
    with open(path) as f:
        for line in f:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def tool_uses():
    for r in rows():
        if r.get("type") != "assistant" or r.get("isSidechain"):
            continue
        for block in (r.get("message") or {}).get("content") or []:
            if isinstance(block, dict) and block.get("type") == "tool_use":
                yield block.get("name", ""), block.get("input") or {}


def bash_commands():
    return [str(i.get("command", "")) for n, i in tool_uses() if n == "Bash"]


def last_text():
    text = ""
    for r in rows():
        if r.get("type") != "assistant" or r.get("isSidechain"):
            continue
        parts = [b.get("text", "") for b in (r.get("message") or {}).get("content") or []
                 if isinstance(b, dict) and b.get("type") == "text"]
        if any(p.strip() for p in parts):
            text = "\n".join(parts)
    return text


def main(argv):
    q, args = argv[0], argv[1:]
    if q == "bash":
        return any(re.search(args[0], c) for c in bash_commands())
    if q == "bash-count":
        return sum(1 for c in bash_commands() if re.search(args[0], c)) == int(args[1])
    if q == "bash-at-most":
        return sum(1 for c in bash_commands() if re.search(args[0], c)) <= int(args[1])
    if q == "tool":
        names = set()
        for n, i in tool_uses():
            names.add(n)
            if n == "Skill":
                names.add("Skill:" + str(i.get("skill", "")))
        return args[0] in names
    if q == "read":
        paths = [str(i.get("file_path", "")) for n, i in tool_uses() if n == "Read"] + bash_commands()
        return any(re.search(args[0], p) for p in paths)
    if q == "final":
        return re.search(args[0], last_text(), re.I) is not None
    raise SystemExit("unknown query: %s" % q)


if __name__ == "__main__":
    sys.exit(0 if main(sys.argv[1:]) else 1)
