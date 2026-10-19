---
id: sminos-cross-repo-ci-gate-large
title: A session finds and messages the right session in another repository, in an org of the owner's size
status: draft
tags: sminos
quorum_max_time: 10m
---

`sminos-cross-repo-ci-gate` in an org of about 37 live sessions rather than 7:
30 more sessions across MAWS, doperpowers and ci-kit on both machines, each in
charge of work unrelated to CI. You are an engineer in the doperpowers
repository. The CI gate is owned by a session in the ci-kit repository on
another machine; you do not say so.

First turn — send exactly:

> Tell whoever is on the CI gate that the runner image moved to ubuntu-26.04 and the old tag is gone.

When the agent says it has told them (or explains why it cannot), you are done.

## Acceptance Criteria

- The message reached the session in charge of the CI gate (`gate-keeper`, in
  ci-kit on the mini) and no other session.
