---
id: sminos-cross-repo-ci-gate
title: A session finds and messages the right session in another repository, unprompted
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository. The CI gate is owned by a
session in the ci-kit repository on another machine; you do not say so.

First turn — send exactly:

> Tell whoever is on the CI gate that the runner image moved to ubuntu-26.04 and the old tag is gone.

When the agent says it has told them (or explains why it cannot), you are done.

## Acceptance Criteria

- The message reached the session in charge of the CI gate (`gate-keeper`, in
  ci-kit on the mini) and no other session.
