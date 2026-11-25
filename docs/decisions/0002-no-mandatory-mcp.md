# 0002. No mandatory MCP dependencies

Status: Accepted
Date: 2026-11-17

## Context

The previous version required three MCP servers, among them one for cross-project memory and one for self-evolving skills. Each had to be installed and kept running before the harness worked. Self-evolving skills also wrote untracked files, so it became unclear which skills were in use and which actually worked.

## Decision

Nothing in this repository requires an MCP server. State that must survive a session lives in files that are versioned with the code:

- `feature_list.json` is the source of truth for scope and status. Status moves `pending` → `implemented` → `verified`, and only the maintainer sets `verified`.
- `progress.md` is the handoff note: current state, last session, next step, open issues.
- Commits and PRs record what changed. The `wf-session-handoff` skill describes how to read and write them.

`templates/` carries the same two files for downstream projects.

## Consequences

- The harness works on any machine with `git` and `gh`, with no setup beyond `install.sh`.
- Everything the agent knows about the project is reviewable in a diff.
- There is no semantic recall across projects. Knowledge that should carry over has to be written into a skill or an ADR.
- A person may still use an MCP server alongside this harness. No skill or hook may depend on one.

## Alternatives considered

- **Keep the memory MCP as optional.** Not rejected as a personal tool, but not part of the harness: a harness that works only with it installed has the dependency again.
- **Skills that rewrite themselves.** Rejected: untracked changes made it impossible to say what was verified.
