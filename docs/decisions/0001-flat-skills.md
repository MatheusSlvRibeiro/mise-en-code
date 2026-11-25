# 0001. Keep skills flat

Status: Accepted
Date: 2026-11-17

## Context

Claude Code discovers a skill only at `skills/<name>/SKILL.md`. The previous version of this harness grouped skills by domain (`skills/frontend/react/SKILL.md`, `skills/backend/django-drf/SKILL.md`) and kept long reference files in subfolders. Skills nested that way are not found, so a skill could exist in the repository and never load.

## Decision

`skills/` holds one directory per skill, one level deep, each with a `SKILL.md`. The domain moves into the name as a prefix: `wf-` (workflow), `be-` (backend), `fe-` (frontend), `test-`. The `name` in the frontmatter equals the directory name.

## Consequences

- Every skill is discoverable, and `install.sh` links each directory into `~/.claude/skills/` without special cases.
- The structure is checked, not remembered: `scripts/check.sh` fails the PR on a nested `SKILL.md`, a stray file in `skills/`, a missing `description`, a `name` that differs from its directory, or a prefix outside the four above. See 0003.
- A skill that needs a helper script keeps it inside its own directory (`skills/wf-project-board/move-card.sh`).
- Long reference material no longer has a home next to a skill. A skill stays one file, so every line has to justify itself.

## Alternatives considered

- **Domain folders with a `SKILL.md` at each leaf.** This is what the old version did. Rejected: it does not load.
- **One large skill per domain.** Rejected: it loads everything whenever any part is relevant, which wastes context.
