---
name: wf-git-flow
description: Defines how to branch, commit, and open pull requests in a GitHub flow where work goes into `preview` and is then promoted to `main`. Use before creating a branch, committing, or opening a PR.
---

# Git flow

## Branches

- Start every unit of work from an up-to-date `preview`: `git checkout preview && git pull --ff-only`.
- Name: `<type>/<short-kebab-description>`, in English. Describe the work, never the issue number: `feat/webhook-receiver`, not `feat/issue-42`.
- Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`. The type is the dominant type of the work.
- Every branch starts from an issue.
- One branch, one PR.
- Projects have two long-lived branches: `main` (production) and `preview` (staging).
- PRs target `preview`. Once approved there, the change goes to `main`. The user does the promotion, as a PR from `preview` to `main`.

## Commits

- Conventional Commits: `<type>(<optional scope>): <imperative subject>`. English, lowercase subject, no trailing period, first line at most 72 characters.
- Types: the branch types plus `style` (formatting only) and `perf`.
- One logical change per commit. Explain why in the body when the diff doesn't.
- Never use `--no-verify` unless the user asks. If a hook fails, fix the cause.
- Never `--amend` a pushed commit. Make a new one.

## Pull requests

- PRs into `preview` are squash-merged: the PR title becomes the commit on `preview`, and the PR body becomes its message. Write both for that. The promotion PR into `main` is merged with a merge commit.
- Title: Conventional Commits format, at most 72 characters.
- Body:
  ```
  ## Summary
  - what changed and why

  ## Test plan
  - [ ] what you actually ran (command + result)

  Closes #N
  ```
- One `Closes #N` line per issue. A branch may close several related issues.
- Open the PR only after `wf-verify-done` passes.
- The user approves and merges. Never merge a PR yourself.

## After merge

- Sync `preview`, then delete the local branch. Because of the squash, use `git branch -D`.
