# Progress

## Current state

Phases 1 and 2 are verified. Phase 3 (Enforcement) is implemented and in review: `block-main-push.sh`, `lint-on-edit.sh`, `settings.example.json`, and a CI job `check` that runs `scripts/check.sh`. No stack skills or agents exist yet.

## Last session

Wrote the Phase 3 files on branch `feat/enforcement-hooks-ci` and opened its PR into `preview`.

## Next step

Once the `check` job has run on the Phase 3 PR, propose a `required_status_checks` rule for `check` on `protect-preview` and `protect-main`. Then start Phase 4 (Stack skills): show each skill's name, description, and outline before writing it.

## Open issues

- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
- Not yet decided: what the agent should do with the GitHub Project (Kanban) board mentioned in `notes.md`.
