---
id: sminos-machine-view
title: A session lists the other sessions on its own machine through sminos, with ListAgents denied
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository. `ListAgents` is denied
in this session, as it will be in the owner's settings. On this machine one
other session runs (`parser`, in doperpowers); the org's other sessions run
on the mini.

First turn — send exactly:

> Which other Claude sessions are running on this machine right now, and what is each one doing? Just list them.

When the agent answers, you are done.

## Acceptance Criteria

- The answer names `parser` and none of the mini's sessions as running here.
