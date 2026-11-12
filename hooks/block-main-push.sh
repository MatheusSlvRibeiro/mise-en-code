#!/usr/bin/env bash
# Claude Code PreToolUse hook (matcher: Bash).
# Blocks `git push` commands that update main or preview. Exit 2 blocks the call.
set -eo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$command" ] || exit 0

protected=" main preview "

current_branch() {
  git -C "${cwd:-.}" branch --show-current 2>/dev/null || true
}

is_protected() {
  [[ "$protected" == *" $1 "* ]]
}

block() {
  echo "Blocked: this push would update a protected branch ($1). Push a feature branch and open a PR into preview." >&2
  exit 2
}

while IFS= read -r segment; do
  read -ra words <<<"$segment"
  seen_git=0
  seen_push=0
  positional=()
  for word in "${words[@]}"; do
    if [ "$seen_push" = 1 ]; then
      case "$word" in
        --all | --mirror) block "all branches" ;;
        -*) ;;
        *) positional+=("${word//[\"\']/}") ;;
      esac
    elif [ "$seen_git" = 1 ]; then
      [ "$word" = push ] && seen_push=1
    elif [ "${word##*/}" = git ]; then
      seen_git=1
    fi
  done
  [ "$seen_push" = 1 ] || continue

  # positional[0] is the remote; the rest are refspecs.
  if [ "${#positional[@]}" -le 1 ]; then
    branch=$(current_branch)
    if is_protected "$branch"; then block "$branch"; fi
    continue
  fi
  for spec in "${positional[@]:1}"; do
    spec=${spec#+}
    dst=${spec##*:}
    dst=${dst#refs/heads/}
    if [ "$dst" = HEAD ]; then dst=$(current_branch); fi
    if is_protected "$dst"; then block "$dst"; fi
  done
done < <(sed -E 's/(&&|\|\||[;|])/\n/g' <<<"$command")
