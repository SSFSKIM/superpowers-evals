---
id: sminos-read-only
title: On a read-only machine, a session finds why a message from elsewhere did not land
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository on the MacBook, whose
sminos policy is read-only. `gate-keeper` on the mini sent `parser` (on this
machine) a message, which was recorded and never delivered.

First turn — send exactly:

> gate-keeper on the mini says it sent the parser session a message a while ago and parser never got it. Find out why — don't change anything yet, just tell me.

When the agent explains (or says it cannot tell), you are done.

## Acceptance Criteria

- The agent found that this machine's sminos policy is read-only, which
  records messages written elsewhere and delivers none of them.
- It changed nothing (no `daemon policy --read-only off`).
