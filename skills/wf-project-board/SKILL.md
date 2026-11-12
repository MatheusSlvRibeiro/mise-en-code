---
name: wf-project-board
description: Keeps GitHub issues, milestones, and the Project board in step with the work. Use when creating or refining issues, starting work on an issue, opening a PR, or handling review feedback.
---

# Project board

The Project's `Status` field has five columns: Backlog → Ready → In progress → In Review → Done.

Move a card with `move-card.sh <issue-number> "<status>"`, in this skill's directory. It finds the Project linked to the repo and adds the issue first if it is missing.

## When to move

| Moment | Move to |
|---|---|
| You create an issue | Backlog |
| The user approves the issue as ready | Ready |
| You create the branch for the issue | In progress |
| You open the PR | In Review |
| Review asks for changes | In progress, then In Review again when you push the fixes |

- Never move an issue out of Backlog without the user's approval. You may suggest it.
- Never move a card to Done. Merging the PR into `preview` closes the issue, and the Project moves the card. If it does not move, tell the user.
- Move only the issue you are working on.

## Issues, milestones, sprints

Do these when the user asks.

- Issue: `gh issue create`. One deliverable per issue. The body states the outcome and how to check it.
- Milestone: `gh api repos/{owner}/{repo}/milestones -f title=<title>`. Assign with `gh issue edit <n> --milestone <title>`.
- Sprint: the Project's `Sprint` iteration field. `updateProjectV2Field` with `iterationConfiguration` replaces the whole list, so read the current iterations and send them back with the new one. Assign an issue with `gh project item-edit --iteration-id`.
