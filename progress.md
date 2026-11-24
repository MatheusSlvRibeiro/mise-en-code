# Progress

## Current state

Phases 1–6 and P7 (project board) are verified. P9 (optional RTK integration) is implemented and in review: ADR 0007, an `rtk` prefix in `readonly-bash.sh`, a guided `install-all.sh` that installs missing dependencies and RTK only on request, and a note in the READMEs and in `wf-verify-done`. `install-all.sh` is tested against stub tools by `scripts/test-install-all.sh`, which `check.sh` runs.

## Last session

Built `install-all.sh` and its tests (30 cases), and mutation-checked the two riskiest rules: `--yes` never installs RTK, and no input counts as no. A real `--dry-run` on the maintainer's machine listed only `shellcheck` as missing and found RTK already present.

## Next step

Start P10, versioning: SemVer computed from Conventional Commits, a workflow on push to `main` that tags and creates a GitHub Release, first version `v0.1.0` at the promotion of `preview` into `main`. Rule to apply: a change to a skill, agent, hook, or script is `feat` or `fix`; `docs` is only for ADRs, READMEs, and progress notes. Promote `preview` into `main` first if the first release should contain everything.

## Open issues

- `install-all.sh` was not run for real (no package manager or RTK installer was executed). Only stubs and a dry run.
- What `rtk init -g` changes was not read from RTK's documentation. The installer relies on its `--dry-run` preview, a settings backup, and `rtk init -g --uninstall`.
- Not verified in a live session: that Claude Code follows the symlinks `install.sh` creates in `~/.claude/agents/`, that the frontmatter hook runs for the `reviewer`, and that the custom `Explore` replaces the built-in.
- The order in which Claude Code runs several hooks on one call is not documented in what was read; the `rtk` prefix handling makes the harness correct either way.
- `main` is behind `preview`, so a fresh clone of `main` misses most skills. Promote `preview` into `main`.
- Lint-config templates (`ruff`, `eslint`) are planned as P8. Until then, rules a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose in the skills.
- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth` and would need a separate decision.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
