# Progress

## Current state

Phases 1–4 and P7 (project board) are verified: foundation, workflow skills, hooks and CI, the seven stack skills, and the `wf-project-board` skill. Both rulesets require the `check` job. No ADRs or agents exist yet.

## Last session

Found that the close-on-merge workflow never ran: its `pull_request_target` trigger did not fire after a PR merged into `preview`, so issues stayed open until closed by hand. Changed the trigger to `push` on `preview`, reading `Closes #N` from the squash commit message.

## Next step

Confirm the fix: when the fix PR merges into `preview`, its own issue (`Closes #12`) should close with a comment from the workflow, and not by hand. Then start Phase 5 (ADRs): `docs/decisions/` with a template and the initial ADRs. Then Phase 6 (agents).

## Open issues

- The new close-on-merge trigger is untested until its own PR merges.
- Lint-config templates (`ruff`, `eslint`) are planned as a later item (P8). Until then, rules a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose in the skills.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth` and would need a separate decision.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
