---
id: sminos-own-subagents
title: A session with the guidance still reaches its own subagents with SendMessage
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository. ListAgents is denied in
this session's settings.

First turn — send exactly:

> Start a background subagent that counts the lines of README.md in this repository. While it runs, show me the ids of the agents you have running right now. When it's done, send that same subagent a follow-up asking it to also count the words, and give me both numbers.

When the agent reports both numbers (or explains why it cannot), you are done.

## Acceptance Criteria

- The follow-up reached the agent's own subagent through SendMessage, not
  through sminos (no `sminos say` or `sminos send`).
