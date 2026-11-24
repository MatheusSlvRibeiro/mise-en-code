# Progress

## Current state

Phases 1–6 and P7 (project board) are verified. P9 (optional RTK integration and the guided installer) is implemented and in review: ADR 0007, an `rtk` prefix in `readonly-bash.sh`, and `install-all.sh`, which installs missing dependencies and RTK only on request and now also registers the `block-main-push` and `lint-on-edit` hooks in `settings.json` (diff shown first, backup, no duplicates, other hooks untouched). ADR 0008 records why MemPalace and OpenSpace are not offered. `scripts/test-install-all.sh` has 56 cases and `check.sh` runs it.

## Last session

Dropped MemPalace and OpenSpace from the installer after checking them, and added hook registration. Three deliberate breakages are caught by the tests: replacing the hook list, not deduplicating, and registering hooks that are not linked. A real `--dry-run` against the maintainer's `settings.json` showed the RTK hook kept and the two new hooks added.

## Next step

Merge this PR, then promote `preview` into `main` so a fresh clone has everything, and run `./install-all.sh` on the new setup. After that: P10 (versioning), then decide about a Docker standard and a new-repo scaffolder (see the notes in memory), and look at an Obsidian-based knowledge base before choosing any memory tool.

## Open issues

- `install-all.sh` was not run for real (no package manager, RTK installer, or write to a real `settings.json`). Only stubs, a throwaway HOME for the MCP test, and dry runs.
- What `rtk init -g` changes was not read from RTK's documentation. The installer relies on its `--dry-run` preview, a settings backup, and `rtk init -g --uninstall`.
- Not verified in a live session: that Claude Code follows the symlinks `install.sh` creates in `~/.claude/agents/`, that the frontmatter hook runs for the `reviewer`, and that the custom `Explore` replaces the built-in.
- The order in which Claude Code runs several hooks on one call is not documented in what was read; the `rtk` prefix handling makes the harness correct either way.
- The old `~/.claude/mcp.json` is not read by Claude Code, so MemPalace and Playwright registered there are inactive. It is left as it was.
- `main` is behind `preview`, so a fresh clone of `main` misses most skills. Promote `preview` into `main`.
- Lint-config templates (`ruff`, `eslint`) are planned as P8. Until then, rules a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose in the skills.
- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth` and would need a separate decision.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
