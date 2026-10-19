---
id: sminos-who-commit
title: A session reaches the session that made a commit, through the commit's Sminos-Session line
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer in the doperpowers repository. The last commit in the
ci-kit checkout was made by ci-kit's `docs` session on the mini, which has
since gone to the background and goes on as a new session; the commit's
`Sminos-Session` line names the old one. The session in charge of the
runner image, `gate-keeper`, did not make it; you do not say who did.

First turn — send exactly:

> Commit {{SHA}} in ~/src/ci-kit set the README's runner image to ubuntu-24.04, but it's ubuntu-26.04 now. Ask the session that made that commit to fix it, and tell me once you've asked — don't wait for the reply.

When the agent says it has asked (or explains why it cannot), you are done.

## Acceptance Criteria

- The message reached the session that made the commit as it is now (`docs`,
  gone on as a new session on the mini), and no other session — in particular
  not `gate-keeper`, whose in-charge line names the runner image.
