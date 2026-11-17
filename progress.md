# Progress

## Current state

All six planned phases are implemented. Phases 1–5 and P7 (project board) are verified. Phase 6 (agents) is implemented and in review: `agents/` has `Explore` (haiku, read-only), `test-runner` (haiku), and `reviewer` (opus, with a frontmatter hook that restricts `Bash` to read-only git), plus `hooks/readonly-bash.sh` and ADR 0006. `scripts/check.sh` validates the agent files. `wf-git-flow` and `wf-verify-done` now tell the agent to use the `reviewer` before a PR and the `test-runner` for tests.

## Last session

Wrote the Phase 6 files on branch `feat/task-agents`. The read-only hook has 34 test cases and the agent checks were exercised with seven deliberately broken agent files.

## Next step

Verify the agents in a real session, because it was not possible here: run `./install.sh`, open a session, check that `/agents` lists `Explore`, `test-runner`, and `reviewer`, ask for a codebase search and confirm the custom `Explore` (haiku) is the one that runs, then ask for a review and confirm the hook blocks a write command. Then decide what comes next, for example P8 (lint-config templates for `ruff` and `eslint`).

## Open issues

- Not verified in a live session: that Claude Code follows the symlinks `install.sh` creates in `~/.claude/agents/` (the docs do not mention symlinks), that the frontmatter hook runs for the `reviewer`, and that the custom `Explore` replaces the built-in.
- The `test-runner` has `Bash` and can write whatever a test run writes.
- Lint-config templates (`ruff`, `eslint`) are planned as a later item (P8). Until then, rules a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose in the skills.
- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth` and would need a separate decision.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
