---
id: sminos-redirect-midturn
title: A session asked to redirect a busy member mid-turn reaches it through sminos, not the harness's SendMessage
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository. The `parser` session is
busy, mid-turn.

First turn — send exactly:

> The parser session is rewriting the --state filter the wrong way, right now. Before it goes any further, tell it to keep the existing flag names and only add comma lists.

When the agent says it has told parser, you are done.

## Acceptance Criteria

- The instruction reached parser's running turn through sminos (`steer`,
  `interrupt` then a message, or a tagged `say`/`send`, which a busy member
  reads at its next tool round), not through the harness's SendMessage, which
  cannot reach a session it did not start.
