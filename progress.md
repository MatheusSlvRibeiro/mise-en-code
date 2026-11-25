# Progress

## Current state

Phases 1–6, P7 (project board), P9 (one installer, optional RTK), and P10 (versioning) are verified. `main` was promoted and `release.yml` created release `v0.1.0` on its first run. The maintainer installed the harness from a clone of `main` in `~/mise-en-code`.

Confirmed in a live setup (Claude Code 2.1.251):

- `install.sh` linked the 11 skills and 3 agents, and registered `block-main-push` and `lint-on-edit` in `settings.json` next to the RTK hook.
- Claude Code follows the symlinks: the skills and the `reviewer` and `test-runner` agents appear in a session.
- `block-main-push` blocks in a real session: `git push origin main` in an empty repository with no remote was refused before Git ran.
- The custom `Explore` replaces the built-in one: the agent list of a new session showed this repo's description with `Read, Grep, Glob`, and not the built-in entry. The model it runs on was not observed.

## Last session

Confirmed from a new session's record that the custom `Explore` agent is the one loaded.

## Next step

Run the remaining live checks (see Open issues). Then pick one: P8 (lint-config templates), a Docker standard, a new-repo scaffolder, or the Obsidian knowledge base (backlog issue #21).

## Open issues

- Asking Claude to describe an agent can be answered by reading the file on disk, which proves nothing about what is loaded. Check the session's agent list.
- Not verified: that the `reviewer` frontmatter hook blocks a write command.
- Not verified: `lint-on-edit` in a real project.
- The `/agents` command no longer opens a list in Claude Code 2.1.251. To see the agents, ask Claude which subagents are available.
- `install.sh` has not installed a package or RTK for real. Only stubs and dry runs cover that.
- What `rtk init -g` changes was not read from RTK's documentation. The installer relies on its `--dry-run` preview, a settings backup, and `rtk init -g --uninstall`.
- A wrong commit type means a wrong version; nothing checks the type against the files changed.
- Lint-config templates (`ruff`, `eslint`) are planned as P8. Until then, rules a linter could enforce are prose in the skills.
- Write `Closes #N` alone on its own line in a PR body, and never use a closing keyword followed by a number in prose: the workflow reads the squash message.
- Cookie auth is the standard for new projects. An existing project that uses a Bearer header is not covered by `be-jwt-auth`.
- Not decided: the sprint cadence (iteration length and start day).
- `notes.md` (the maintainer's conventions) stays untracked on purpose.
- `lint-on-edit.sh` supports Python (`ruff`) and TypeScript/JavaScript (project-local `eslint`) only.
