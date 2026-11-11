---
name: wf-session-handoff
description: Reads and writes the cross-session state kept in `feature_list.json`, `progress.md`, and git history. Use when resuming earlier work or when stopping before a task is finished.
---

# Session handoff

## Resuming

1. Read `progress.md`, `feature_list.json`, and the recent `git log`.
2. The next feature is the first one whose `status` is not `implemented` or `verified`.
3. If `progress.md` and the git history disagree, trust the git history and say so.

## Stopping

Update `progress.md`, keeping its four sections:

- **Current state:** what works now.
- **Last session:** what was done, and the commit or PR it landed in.
- **Next step:** one action, specific enough to start without asking.
- **Open issues:** blockers and decisions waiting on the user.

Change a feature's `status` only as `wf-verify-done` allows. Add no new fields to `feature_list.json`.
