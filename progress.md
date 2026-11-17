# Progress

## Current state

Phases 1–4 and P7 (project board) are verified: foundation, workflow skills, hooks and CI, the seven stack skills, and the `wf-project-board` skill. Both rulesets require the `check` job. No ADRs or agents exist yet.

## Last session

Fixed the close-on-merge workflow in two steps. Its `pull_request_target` trigger never fired, so it now runs on `push` to `preview`. On its first run it matched keywords written in prose (and tried to close a PR number), so it now accepts only a line that is exactly `Closes #N`, and a failure on one issue no longer hides the others.

## Next step

Confirm the fix: when this PR merges into `preview`, issue #12 should close with a comment from the workflow, and not by hand. Commenting on an issue with `issues: write` is also untested until then. Then start Phase 5 (ADRs): `docs/decisions/` with a template and the initial ADRs. Then Phase 6 (agents).

## Open issues

- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Lint-config templates (`ruff`, `eslint`) are planned as a later item (P8). Until then, rules a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose in the skills.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth` and would need a separate decision.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
