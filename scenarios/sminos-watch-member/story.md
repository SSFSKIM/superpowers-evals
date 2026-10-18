---
id: sminos-watch-member
title: A session asked what another member is doing right now looks it up
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository.

First turn — send exactly:

> What is the parser session doing right now?

When the agent answers, you are done.

## Acceptance Criteria

- The answer gives the parser session's current activity as sminos publishes
  it (rewriting the --state filter to take comma lists), not a guess.
