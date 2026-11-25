# Progress

## Current state

Phases 1–6, P7 (project board), and P9 (one installer, optional RTK) are verified. P10 (versioning) is implemented and in review: versions are Git tags computed from the commit types, `scripts/next-version.sh` and `scripts/release-notes.sh` do the work, and `.github/workflows/release.yml` creates the tag and a GitHub Release when `preview` is promoted into `main`. ADR 0009 records the decision. `scripts/test-release.sh` has 41 cases, including the real `run:` step of the workflow with a fake `gh`, and `check.sh` runs it. `wf-git-flow` now tells the agent which commit type produces which version.

## Last session

Wrote the release scripts, the workflow, ADR 0009, and the tests. Reading the first release notes showed that every commit but the newest had an empty subject (git ends each record with a newline), which would have made the next-version script ignore every `feat` and `fix`. Fixed in both scripts. The first tests did not catch it, because the deciding commit was always the newest, so cases with an older deciding commit were added, and the bug is now caught by several tests.

## Next step

Merge this PR, then open the promotion PR from `preview` to `main` (merge commit). Its first run of `release.yml` will create `v0.1.0`; it is the first time the workflow runs on GitHub, so check the Actions tab. After that, run `./install.sh` from a clean clone of `main`. Remaining ideas: P8 (lint-config templates), a Docker standard, a new-repo scaffolder, and the Obsidian knowledge base (backlog issue #21).

## Open issues

- `release.yml` has not run on GitHub. Its first run is the first promotion, and it could fail on something the local tests cannot show, such as the token's permission to create a release.
- A wrong commit type means a wrong version; nothing checks the type against the files changed. Past commits such as `docs(skills): …` are not reclassified.
- `install.sh` was not run for real (no package manager, RTK installer, or write to a real `settings.json`). Only stubs and dry runs.
- What `rtk init -g` changes was not read from RTK's documentation. The installer relies on its `--dry-run` preview, a settings backup, and `rtk init -g --uninstall`.
- Not verified in a live session: that Claude Code follows the symlinks the installer creates in `~/.claude/agents/`, that the frontmatter hook runs for the `reviewer`, and that the custom `Explore` replaces the built-in.
- The old `~/.claude/mcp.json` is not read by Claude Code, so MemPalace and Playwright registered there are inactive. It is left as it was.
- `main` is behind `preview`, so a fresh clone of `main` misses most skills until the promotion.
- Lint-config templates (`ruff`, `eslint`) are planned as P8. Until then, rules a linter could enforce are prose in the skills.
- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth`.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the user's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
