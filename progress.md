# Progress

## Current state

Phases 1–3 are verified. P7 (project board) is implemented and in review: the `wf-project-board` skill with `move-card.sh`, and a workflow that closes issues when a PR merges into `preview`. The GitHub Project `mise-en-code` (private, linked to this repo) has the Status columns Backlog, Ready, In progress, In Review, Done, and a `Sprint` iteration field with no iterations yet. Both rulesets require the `check` job. No stack skills or agents exist yet.

## Last session

Created the Project, the skill, and the close-on-merge workflow on branch `feat/project-board-skill`.

## Next step

Start Phase 4 (Stack skills) on a branch from `preview`. Show each skill's name, description, and outline before writing it.

## Open issues

- The close-on-merge workflow only runs once it is on `preview`, so it is untested until the next PR merges into `preview`.
- In the Project settings (Workflows), enable "Item closed → Done". The API cannot set this.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
