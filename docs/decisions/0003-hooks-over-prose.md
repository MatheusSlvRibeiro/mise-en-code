# 0003. Enforce yes/no rules with hooks and CI, not prose

Status: Accepted
Date: 2026-11-17

## Context

The previous version wrote its rules as text in long instruction files and skills, including rules with a plain yes or no answer ("never push to main", "every skill has a description"). An agent reads prose as advice. Over a long session it forgets, and nothing tells anyone that a rule was broken.

## Decision

A rule that has a yes or no answer is enforced by something that can fail. Prose is kept for judgment calls only. The enforcement lives in three places:

- **Claude Code hooks** (`hooks/`, wired through `settings.example.json`): `block-main-push.sh` stops a push to `main` or `preview`, and `lint-on-edit.sh` lints each edited file and returns the output to the agent.
- **CI** (`scripts/check.sh`, job `check`): skill structure, JSON state files and statuses, `AGENTS.md` length, `CLAUDE.md` content, README language switch and paired changes, decision-record index, `shellcheck`, and the hook tests in `scripts/test-hooks.sh`.
- **GitHub settings**: rulesets on `main` and `preview` require a PR, the `check` job, no force push, no deletion, and no bypass. See 0004.

Every enforcement is tested by breaking the rule on purpose and confirming the check fails.

## Consequences

- A broken rule fails a PR with a message, instead of relying on someone to notice.
- Instruction files stay short, because they no longer carry the rules a tool checks.
- The hooks have known gaps: `git -C <dir> push` is judged by the current directory's branch, a push with no destination uses the current branch rather than its upstream, and an `echo` of a push command is blocked too.
- Some rules are still prose because no check exists yet: default exports, `any`, inline styles, arbitrary Tailwind values, `fields = '__all__'`. A linter can enforce these. Lint-config templates are planned as a later item.
- Hooks only run once registered in the user's `~/.claude/settings.json`; `install.sh` links the scripts but does not edit settings.

## Alternatives considered

- **Longer instructions.** This is the old approach. Rejected: it did not hold.
- **Branch protection through hooks alone.** Rejected: a hook guards only one machine. The GitHub rulesets guard the repository for everyone, and the hook gives an earlier, clearer message.
