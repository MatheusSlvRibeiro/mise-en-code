# Progress

## Current state

Phases 1–6 and P7 (project board) are verified. P9 (optional RTK integration and one guided installer) is implemented and in review: `install.sh` is the only installer. It checks `git`, `gh`, and `jq`, offers to install what is missing, offers RTK, links the skills, agents, and hooks, and offers to register `block-main-push` and `lint-on-edit` in `settings.json` (diff shown first, timestamped backup, no duplicates, other hooks untouched). `readonly-bash.sh` understands the `rtk` prefix. ADR 0007 records the single installer and RTK as optional; ADR 0008 records why MemPalace and OpenSpace are not offered. `scripts/test-install.sh` has 64 cases and `check.sh` runs it.

## Last session

Merged the two scripts into one `install.sh` and removed `install-all.sh`. Linking no longer asks, because it only creates symlinks and never replaces anything; every other question still defaults to no, and with no terminal the script only links. Parked the Obsidian knowledge-base idea as a backlog issue (#21).

## Next step

Merge this PR, then promote `preview` into `main` so a fresh clone has everything, and run `./install.sh` on the new setup. After that: P10 (versioning), then decide about a Docker standard and a new-repo scaffolder (see the notes in memory). The Obsidian idea waits in the backlog until its open questions are answered.

## Open issues

- `install.sh` was not run for real (no package manager, RTK installer, or write to a real `settings.json`). Only stubs, a throwaway HOME for the MCP test, and dry runs.
- What `rtk init -g` changes was not read from RTK's documentation. The installer relies on its `--dry-run` preview, a settings backup, and `rtk init -g --uninstall`.
- Not verified in a live session: that Claude Code follows the symlinks the installer creates in `~/.claude/agents/`, that the frontmatter hook runs for the `reviewer`, and that the custom `Explore` replaces the built-in.
- The order in which Claude Code runs several hooks on one call is not documented in what was read; the `rtk` prefix handling makes the harness correct either way.
- The old `~/.claude/mcp.json` is not read by Claude Code, so MemPalace and Playwright registered there are inactive. It is left as it was.
- `main` is behind `preview`, so a fresh clone of `main` misses most skills. Promote `preview` into `main`.
- Lint-config templates (`ruff`, `eslint`) are planned as P8. Until then, rules a linter could enforce (default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`) are prose in the skills.
- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth` and would need a separate decision.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
