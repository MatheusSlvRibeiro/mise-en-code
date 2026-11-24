# 0009. Version with tags computed from the commit types

Status: Accepted
Date: 2026-11-24

## Context

Until now the repository had no versions: no tags, no releases, only history. Someone installing it could not say which version they had, pin one, or read what changed between two. Some projects keep versions as branches (`v1.0.0`, `release/1.x`), others as tags.

The workflow already has the pieces a version needs. Commits follow Conventional Commits, because PR titles become commit titles (0004). Promotion from `preview` to `main` is a deliberate act by the maintainer. The rulesets block direct pushes to the branches that matter, which limits how a release can be automated.

## Decision

- **Versions are tags**, named `vMAJOR.MINOR.PATCH`, on `main`. A GitHub Release holds the notes.
- **A release happens on promotion.** A push to `main` runs `.github/workflows/release.yml`. It calls `scripts/next-version.sh` to compute the next version and `scripts/release-notes.sh` to write the notes, then creates the tag and the Release with `gh release create`. If nothing releasable is found, it does nothing.
- **The commit type decides the bump**, looking at the non-merge commits since the last `vX.Y.Z` tag:
  - `feat` is a minor release; `fix` and `perf` are a patch.
  - A breaking change is `type!:` or a body line starting with `BREAKING CHANGE:`. It is a major release, except while the major version is 0, where it is a minor release. Reaching 1.0.0 is a decision for a person, not something a commit can trigger.
  - `docs`, `chore`, `ci`, `test`, `refactor`, `style`, and subjects with no type release nothing by themselves.
  - The highest bump among the commits wins. With no tag yet, the first release is `v0.1.0`.
- **What counts as `feat` or `fix` is set by what the repository ships.** Skills, agents, hooks, scripts, and the installer change how the harness behaves, so changes to them are `feat` or `fix`. `docs` is for ADRs, READMEs, and progress notes only. The `wf-git-flow` skill says so.
- **Merge commits are ignored.** The promotion merge commit has a title that says nothing about content; the squash commits it brings in are what count.
- **The notes live in GitHub Releases**, grouped by type, with a compare link. There is no `CHANGELOG.md`.

## Consequences

- A version appears only when `preview` is promoted. Merging into `preview` does not release.
- The first promotion creates `v0.1.0`.
- A wrong commit type means a wrong version. `docs(skills): …` would hide a behavior change from the release. The convention is the control, and `wf-git-flow` states it. Nothing checks it.
- A person can pin a version with `git checkout v0.2.0` in the installed copy. Tags do not move; a branch named like a version could.
- The scripts are tested against throwaway repositories (`scripts/test-release.sh`), including the exact shape of a promotion and the real `run:` step of the workflow with a fake `gh`. The workflow itself has not run on GitHub yet. Its first run is the first promotion, so a failure there is possible, for example in the token's permission to create a release.
- Notes are made from commit subjects, so a vague PR title makes a vague note.

## Alternatives considered

- **Version branches** (`v1.0.0`, `release/1.x`). Useful when older versions are maintained in parallel. Nobody does that here. A branch named like a tag makes `git checkout v1.0.0` ambiguous, every new branch would need its own ruleset, and `release` is not a branch type in `wf-git-flow`. If a supported old version ever appears, a `release/1.x` branch can be cut from its tag on demand.
- **release-please.** It opens a release PR. A PR created with the workflow token does not trigger other workflows, so the `check` job that both rulesets require would never run and the PR could not be merged without a personal token or a GitHub App.
- **semantic-release.** It pushes a version commit straight to `main`, which the ruleset forbids.
- **A `CHANGELOG.md` kept in the repository.** A file written by CI would need the same direct push. Releases carry the same information.
- **Versions by hand.** A person remembers to tag until they do not.
