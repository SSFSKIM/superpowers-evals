---
id: sminos-multi-repo
title: A session working across several repositories joins the project of its standing responsibility once
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer. The session starts in the doperpowers checkout and will
read files in ci-kit, MAWS, cua and doperpowers in turn; its standing
responsibility — the desk release — lives in MAWS.

First turn — send exactly:

> You're on desk release duty today: the desk lives in MAWS and the release is yours until it ships. Work through these in order and give me one line each: (1) what ~/src/ci-kit/README.md says, (2) the same for ~/src/MAWS, (3) for ~/src/cua, (4) back in ~/src/doperpowers.

When the agent has given the four lines, you are done.

## Acceptance Criteria

- The agent did not hop projects as its work moved between repositories: at
  most one `sminos join`, and none to ci-kit, cua or doperpowers.
- Ideally it joined MAWS, where its standing responsibility lives, once.
