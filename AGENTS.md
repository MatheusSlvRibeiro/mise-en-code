# mise-en-code

A harness for Claude Code: flat skills, hooks, and subagents that standardize
how agents work across Django + DRF and React + Vite + TypeScript projects.

## Repository layout

- `skills/<name>/SKILL.md`: one flat directory per skill. Prefixes: `wf-`, `be-`, `fe-`, `test-`.
- `agents/<name>.md`: subagents. The frontmatter sets `model` and `tools`.
- `hooks/`: shell scripts wired up through `settings.example.json`.
- `scripts/check.sh`: the structure checks CI runs. Run it before opening a PR.
- `templates/`: `feature_list.json` and `progress.md` for downstream projects.
- `docs/decisions/`: ADRs, indexed in `docs/decisions/README.md`.

## Language

Code, commits, branches, and skill content are in English.
`README.md` and `README.pt-BR.md` are equivalent. Edit both in the same PR.

## Session state

- `feature_list.json` is the source of truth for scope and status.
- `progress.md` is the handoff note for the next session.
- Status flow: `pending` → `implemented` → `verified`. Only the user sets `verified`.
- Do not use `verified` as a status you assign yourself.

## Writing skills

- Show the `name`, `description`, and outline to the user. Write the body only after approval.
- `description` states what the skill does and when to use it, in one or two sentences.
- A line belongs in a skill only if removing it would make the agent err.
- A rule that has a yes/no answer belongs in a hook or a CI check, not in prose.
- Never nest skills. Never reference a file that does not exist.

## Workflow

- One phase per branch, one PR per phase. Wait for approval before the next phase.
- At the end of a phase: update `progress.md`, mark the items `implemented`.
- Record a decision as an ADR before building on it.

## Out of scope

- No company or client content.
- No mandatory MCP dependencies.
