# 0004. Work flows through preview into main

Status: Accepted
Date: 2026-11-17

## Context

Projects have two long-lived branches: `preview` (staging) and `main` (production). Changes need review and a staging step before they reach production. Two limits of GitHub shaped the flow:

- Squash-merging a branch into `main` and then promoting `preview` into `main` the same way makes the two branches diverge, because a squash commit does not carry the original history.
- GitHub closes issues from a closing keyword only when the change reaches the default branch, which is `main`. Work lands in `preview` first, so its issues would stay open until promotion.

## Decision

- Work branches start from an up-to-date `preview` and are named `<type>/<short-kebab-description>`. Every branch starts from an issue.
- A PR into `preview` is squash-merged. Its title becomes the commit and its body becomes the message, so both are written for that.
- The promotion PR from `preview` into `main` is merged with a merge commit, so `main` inherits the history of `preview`.
- The maintainer approves and merges every PR, including the promotion.
- GitHub enforces this with two rulesets: `protect-preview` allows only squash and `protect-main` allows only merge commits (`allowed_merge_methods`). Both require a PR and the `check` job, block force pushes and deletion, and have no bypass actors. Squash and merge commits are both enabled at the repository level so each ruleset can pick one.
- The head branch is deleted after merge. The `preview` ruleset blocks deletion, so the promotion merge cannot remove `preview`.
- A workflow (`.github/workflows/close-issues-on-merge.yml`) runs on every push to `preview`. It reads the squash commit message and closes each issue named on a line that is exactly `Closes #N`. A GitHub Project automation then moves the card to Done.

## Consequences

- An issue closes when its PR reaches `preview`, not when the change reaches production.
- A closing keyword followed by a number in prose anywhere in a PR body must be avoided. The workflow's first version read such text and tried to close unrelated numbers, so it now accepts only a line of its own.
- Each ruleset allows one merge method, so using the wrong method on a PR is impossible, not just discouraged.
- The workflow was first written with a `pull_request_target` trigger, which never fired for PRs into `preview`. The `push` trigger runs from the branch's own file.
- Branching from `preview` means a branch can include staging changes that have not reached `main` yet.

## Alternatives considered

- **Squash for the promotion too.** Rejected: it makes `preview` and `main` diverge.
- **Make `preview` the default branch** so closing keywords work natively. Rejected: the `protect-main` ruleset targets the default branch, so this would move that protection onto `preview` and leave `main` unprotected.
- **Rebase merges.** Not enabled: the repository has no use for them.
