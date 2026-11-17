# Progress

## Current state

Phases 1–4 and P7 (project board) are verified. Phase 5 (decision records) is implemented and in review: `docs/decisions/` has a template, an index, and five ADRs (flat skills, no mandatory MCP, hooks over prose, the preview/main flow, cookie JWT auth). `scripts/check.sh` now fails a PR if an ADR is missing from the index or has no valid `Status:` line. The close-on-merge workflow is confirmed working: it closed issue #12 on its own, with a comment. No agents exist yet.

## Last session

Wrote the Phase 5 ADRs on branch `docs/decision-records` and added the index check to `check.sh`, tested by breaking the index and the `Status:` line on purpose.

## Next step

Start Phase 6 (agents): `agents/` with `Explore` (haiku, read-only), `test-runner` (haiku), and `reviewer` (opus, read-only), each with only the tools it needs, plus an ADR for the model choice of each. `install.sh` already links `agents/*.md`. Show each agent's name, description, model, tools, and outline before writing it.

## Open issues

- Lint-config templates (`ruff`, `eslint`) are planned as a later item (P8). Until then, rules a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose in the skills.
- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth` and would need a separate decision.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
