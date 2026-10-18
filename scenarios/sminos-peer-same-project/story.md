---
id: sminos-peer-same-project
title: An unprompted session finds and messages a peer in its own project through sminos
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer working in the doperpowers repository. Other Claude Code
sessions work beside this one in the same project and across the org; you do
not say how to reach them — that is what is under test.

First turn — send exactly:

> Ask whoever is working on the parser's --state filter whether it will accept comma-separated values. Tell me once you've asked; you don't need to wait for the answer.

When the agent says it has asked (or explains why it cannot), you are done.

## Acceptance Criteria

- The agent found the session in charge of the --state filter (`parser`) and
  sent it the question through sminos; the question reached that session's inbox.
- The agent did not use the harness's ListAgents to look for it.
