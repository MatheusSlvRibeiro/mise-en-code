#!/usr/bin/env bash
# Feeds sample hook inputs to the hooks and checks their exit codes.
set -eo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

# A scratch repo whose current branch we can switch.
git -C "$tmp" init -q -b main
git -C "$tmp" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init

expect() { # expect <want-exit> <label> <exit-code>
  if [ "$3" = "$1" ]; then
    echo "ok   $2"
  else
    echo "FAIL $2 (want exit $1, got $3)"
    failures=$((failures + 1))
  fi
}

push() { # push <branch> <command> <want-exit>
  git -C "$tmp" checkout -q -B "$1"
  local code=0
  jq -n --arg c "$2" --arg d "$tmp" '{tool_input:{command:$c}, cwd:$d}' |
    "$root/hooks/block-main-push.sh" >/dev/null 2>&1 || code=$?
  expect "$3" "block-main-push [$1] $2" "$code"
}

push feat/x "git push origin main" 2
push feat/x "git push origin HEAD:preview" 2
push feat/x "git push origin +feat/x:main" 2
push feat/x "git push --delete origin main" 2
push feat/x "git push --all" 2
push feat/x "git status && git push origin main" 2
push main "git push" 2
push main "git push origin" 2
push main "git push origin HEAD" 2
push preview "git push -u origin" 2
push main "git push -u origin feat/x" 0
push feat/x "git push" 0
push feat/x "git push -u origin feat/x" 0
push feat/x "git push --force-with-lease origin feat/x" 0
push feat/x "rtk git push origin main" 2
push feat/x "rtk proxy git push origin HEAD:preview" 2
push feat/x "rtk git push -u origin feat/x" 0
push main "git status" 0
push main "git commit -m 'fix main'" 0

# lint-on-edit: fake linters stand in for ruff and eslint.
bin="$tmp/bin"
proj="$tmp/proj"
mkdir -p "$bin" "$proj/node_modules/.bin"
printf 'x = 1\n' >"$proj/a.py"
printf 'const x = 1\n' >"$proj/a.ts"
printf 'text\n' >"$proj/a.md"

lint() { # lint <file> <want-exit> <label>
  local code=0
  jq -n --arg f "$1" '{tool_input:{file_path:$f}}' |
    CLAUDE_PROJECT_DIR="$proj" PATH="$bin:$PATH" "$root/hooks/lint-on-edit.sh" >/dev/null 2>&1 || code=$?
  expect "$2" "lint-on-edit $3" "$code"
}

printf '#!/bin/sh\nexit 1\n' >"$bin/ruff"
printf '#!/bin/sh\nexit 1\n' >"$proj/node_modules/.bin/eslint"
chmod +x "$bin/ruff" "$proj/node_modules/.bin/eslint"
lint "$proj/a.py" 2 "failing ruff blocks"
lint "$proj/a.ts" 2 "failing eslint blocks"
lint "$proj/a.md" 0 "other extensions are skipped"
lint "$proj/missing.py" 0 "missing file is skipped"

printf '#!/bin/sh\nexit 0\n' >"$bin/ruff"
printf '#!/bin/sh\nexit 0\n' >"$proj/node_modules/.bin/eslint"
lint "$proj/a.py" 0 "passing ruff"
lint "$proj/a.ts" 0 "passing eslint"

rm "$proj/node_modules/.bin/eslint"
lint "$proj/a.ts" 0 "no eslint in project is skipped"

# readonly-bash: only read-only git commands and output filters pass.
ro() { # ro <want-exit> <command>
  local code=0
  jq -n --arg c "$2" '{tool_input:{command:$c}}' |
    "$root/hooks/readonly-bash.sh" >/dev/null 2>&1 || code=$?
  expect "$1" "readonly-bash $2" "$code"
}

ro 0 "git diff main...HEAD"
ro 0 "git diff --stat | head -20"
ro 0 "git log --oneline -5"
ro 0 "git -C sub status"
ro 0 "git --no-pager show HEAD:README.md"
ro 0 "git branch --show-current"
ro 0 "git rev-parse --show-toplevel"
ro 0 "git grep -n foo | wc -l"
ro 0 "git merge-base preview HEAD && git diff --name-only preview...HEAD"
ro 0 "ls -la"
ro 2 "rm -rf build"
ro 2 "git push origin feat/x"
ro 2 "git commit -m x"
ro 2 "git checkout main"
ro 2 "git branch newname"
ro 2 "git branch -D old"
ro 2 "git diff > out.patch"
ro 2 "git diff >> out.patch"
ro 2 "git diff --output=out.patch"
ro 2 "git log --output=x"
ro 2 "git -c core.pager=sh log"
ro 2 "git diff --ext-diff"
ro 2 "git status; rm x"
ro 2 "git status && rm x"
ro 2 "git diff | tee out.patch"
ro 2 "git diff | sort -o out.txt"
# RTK rewrites commands to `rtk <command>`; the hook judges the command underneath.
ro 0 "rtk git diff --stat"
ro 0 "rtk git status && rtk git log --oneline -3"
ro 0 "rtk proxy git diff main...HEAD"
ro 0 "rtk grep -n foo"
ro 2 "rtk git push origin main"
ro 2 "rtk proxy git push origin main"
ro 2 "rtk proxy rm -rf x"
ro 2 "rtk rm -rf x"
ro 2 "rtk gain"
ro 2 "rtk"
ro 2 "rtk proxy"
# shellcheck disable=SC2016  # these are literal command strings fed to the hook
ro 2 'git diff $(rm x)'
# shellcheck disable=SC2016
ro 2 'git diff `rm x`'
ro 2 "FOO=1 git status"
ro 2 "echo hi"
ro 2 "cat README.md"
ro 2 "curl https://example.com"
ro 2 "python3 -c 'print(1)'"
ro 2 "git"

[ "$failures" = 0 ] || { echo "$failures hook test(s) failed"; exit 1; }
