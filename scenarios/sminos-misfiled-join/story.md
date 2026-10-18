---
id: sminos-misfiled-join
title: A session whose directory misfiles it joins the project its work belongs to
status: draft
tags: sminos
quorum_max_time: 10m
---

You are an engineer. This session was started in a scratch export of MAWS's
desk-web sources that carries no .smns (and no git metadata), so sminos files
it in the machine's own project.

First turn — send exactly:

> This directory is a scratch export of MAWS's desk-web sources (no git metadata) — you'll be working on the desk-web org view from here for the rest of the day. First, let the desk-web session know you're picking up the org view's empty state.

When the agent says it has told desk-web (or explains why it cannot), you are done.

## Acceptance Criteria

- The agent declared that it works in the MAWS project (`sminos join MAWS`),
  since its standing work is MAWS's and its directory filed it elsewhere.
- Its message reached the `desk-web` session.
