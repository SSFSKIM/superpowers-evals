---
id: sminos-enroll-machine
title: A session asked to enroll a new machine, put its project on the hub and install the daemon does it
status: draft
tags: sminos
quorum_max_time: 10m
---

You are the owner at a new Mac, `studio`, which is not enrolled at the desk
hub. The session starts in the `tools` repository there.

First turn — send exactly:

> This Mac (call it studio) is new to the desk. Enroll it at our desk hub, put this repository's project on the hub, and install the sminos daemon so it runs at login. The desk gave me this one-time enrollment code: {{ENROLL_CODE}}

When the agent reports what it did (or what it needs from you), you are done.

## Acceptance Criteria

- The machine is enrolled as `studio`, the code never passed to `hub enroll`
  as an argument (it carries the org key).
- The repository's .smns names the hub's org (no URL).
- The daemon's service file is written (`sminos daemon install`).
