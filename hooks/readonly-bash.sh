#!/usr/bin/env bash
# Claude Code PreToolUse hook (matcher: Bash), for read-only agents such as the reviewer.
# Allows only read-only git commands and a few output filters. Exit 2 blocks the call.
set -eo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$command" ] || exit 0

deny() {
  echo "Blocked (read-only agent): $1" >&2
  exit 2
}

# Anything that writes a file or runs a nested command.
# shellcheck disable=SC2016  # the patterns are literal text to match, not expansions
case "$command" in
  *'>'* | *'`'* | *'$('* | *'<('*) deny "redirection and command substitution are not allowed" ;;
esac
case "$command" in
  *--output* | *--ext-diff* | *--open-files-in-pager*) deny "that option writes a file or runs a program" ;;
esac

git_subcommands=" diff log show status merge-base rev-parse blame grep ls-files shortlog describe "
filters=" head tail wc grep cut ls pwd "

while IFS= read -r segment; do
  read -ra words <<<"$segment"
  [ "${#words[@]}" -gt 0 ] || continue
  first="${words[0]}"

  if [ "$first" = git ]; then
    i=1
    # Skip global options that cannot run code. `-c` can, so it is not skipped.
    while [ "$i" -lt "${#words[@]}" ]; do
      case "${words[$i]}" in
        --no-pager | --no-optional-locks) i=$((i + 1)) ;;
        -C) i=$((i + 2)) ;;
        *) break ;;
      esac
    done
    sub="${words[$i]:-}"
    if [ "$sub" = branch ]; then
      [ "${words[$((i + 1))]:-}" = "--show-current" ] && [ "${#words[@]}" -eq $((i + 2)) ] ||
        deny "only 'git branch --show-current' is allowed"
    elif [[ "$git_subcommands" != *" $sub "* ]]; then
      deny "git ${sub:-<none>} is not a read-only command"
    fi
  elif [[ "$filters" != *" $first "* ]]; then
    deny "$first is not allowed; use read-only git commands and head, tail, wc, grep, cut, ls, pwd"
  fi
done < <(sed -E 's/(&&|\|\||[;|])/\n/g' <<<"$command")
