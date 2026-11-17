# 0006. Pin a model and a minimal tool set for each agent

Status: Accepted
Date: 2026-11-17

## Context

Three recurring tasks differ a lot in how much thinking they need: searching a codebase, running tests and reading the result, and reviewing a diff against a set of rules. A subagent with no `model` inherits the main conversation's model, and one with no `tools` list inherits every tool. Both defaults cost more than the task needs, and the second also lets a search agent edit files.

Claude Code resolves a subagent's model in this order: the per-call parameter, the agent's `model` field, the `CLAUDE_CODE_SUBAGENT_MODEL` environment variable, then the main conversation's model. A user-level agent named `Explore` overrides the built-in one and keeps its own `model`.

## Decision

Each agent in `agents/` sets `model` and `tools` explicitly.

| Agent | Model | Tools | Why |
|---|---|---|---|
| `Explore` | `haiku` | `Read, Grep, Glob` | Searching and summarizing with line references is mechanical, and it runs often. It replaces the built-in agent of the same name. |
| `test-runner` | `haiku` | `Bash, Read, Grep, Glob` | Running a command and filtering its output to the failures is mechanical. It needs `Bash` to run the tests. |
| `reviewer` | `opus` | `Read, Grep, Glob, Bash` | Judging a diff against rules and spotting what is wrong is the one task here where a weaker model misses things that matter. |

Read-only is enforced, not requested:

- `Explore` has no `Bash`, `Edit`, or `Write`, so it cannot change anything.
- `reviewer` needs `git diff`, but the `tools` field cannot limit `Bash` to certain commands. Its frontmatter registers `hooks/readonly-bash.sh` as a `PreToolUse` hook on `Bash`. The hook allows only read-only git commands and a few output filters, and blocks redirection, command substitution, and options that write a file.
- `scripts/check.sh` fails the PR if an agent has no pinned model (`haiku`, `sonnet`, or `opus`), no explicit `tools`, a write tool, a name that differs from its file, or a hook script that does not exist. See 0003.

## Consequences

- Searching and test runs cost little. The expensive model is used only when a review needs it.
- `haiku` can miss a subtle failure when it summarizes test output. The `test-runner` therefore reports the exact command, the exit code, and the counts, so the caller can tell a bad summary from a bad run.
- The `test-runner` has `Bash` and can write whatever the test run writes. Nothing restricts that.
- The `reviewer` hook allows a fixed list of commands. A review that needs another read-only command is blocked until the list is extended.
- Changing a model is a one-line edit. If that changes the reasoning above, add a new ADR and mark this one `Superseded by NNNN`.
- Not verified in a live session: that Claude Code follows the symlinks `install.sh` creates in `~/.claude/agents/` (the documentation does not mention symbolic links), and that the frontmatter hook runs for the `reviewer`.

## Alternatives considered

- **Inherit the main model.** Rejected: every search and test run would pay for the main conversation's model.
- **`sonnet` for the reviewer.** Not rejected on evidence. Opus was chosen because a missed defect in review costs more than the extra tokens. Revisit if reviews prove too slow or too expensive.
- **A reviewer without `Bash`.** Rejected: the caller would have to save the diff to a file before every review.
