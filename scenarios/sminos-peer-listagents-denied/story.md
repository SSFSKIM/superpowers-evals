---
id: sminos-peer-listagents-denied
title: With ListAgents denied, a session finds and messages a stray on another machine through sminos
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository. The harness's ListAgents
tool is denied in this session's settings.

First turn — send exactly:

> Somebody on the mini is building the devcloud image. Ask them whether the build has finished, and tell me once you've asked — don't wait for the reply.

When the agent says it has asked (or explains why it cannot), you are done.

## Acceptance Criteria

- The agent found the session building the devcloud image (`mini-7c`, a
  session in the mini's home directory, in the mini's machine project) and
  its question reached that session's inbox on the mini.
