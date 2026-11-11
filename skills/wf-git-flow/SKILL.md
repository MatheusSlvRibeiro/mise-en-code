---
name: wf-git-flow
description: Defines how to branch, commit, and open pull requests in a GitHub squash-merge flow. Use before creating a branch, committing, or opening a PR.
---

# Git flow

## Branches

- Start every unit of work from an up-to-date `main`: `git checkout main && git pull --ff-only`.
- Name: `<type>/<short-kebab-description>`, in English. Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`.
- One branch, one PR.

## Commits

- Conventional Commits: `<type>(<optional scope>): <imperative subject>`. English, lowercase subject, no trailing period.
- One logical change per commit. Explain why in the body when the diff doesn't.

## Pull requests

- The repo is squash-only: the PR title becomes the commit on `main`, and the PR body becomes its message. Write both for that.
- Title: Conventional Commits format, same as a commit subject.
- Body: a short summary of what changed and why, then a test plan listing what you actually ran.
- Open the PR only after `wf-verify-done` passes.

## After merge

- Sync `main`, then delete the local branch. Because of the squash, use `git branch -D`.
