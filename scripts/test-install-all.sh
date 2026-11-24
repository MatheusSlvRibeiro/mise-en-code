#!/usr/bin/env bash
# Runs install-all.sh against stub tools in a throwaway PATH. Nothing is really installed:
# each stub only appends the command it received to a log, and the tests read that log.
set -eo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
base="$(mktemp -d)"
trap 'rm -rf "$base"' EXIT
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  failures=$((failures + 1))
}

# The utilities install-all.sh and install.sh need, and nothing else, so a tool can be "missing".
core="bash sh env dirname basename sed id wc mktemp rm head grep cp chmod mkdir readlink ln cat tr"

new_sandbox() { # sets: d bin claude log out
  d="$(mktemp -d "$base/s.XXXXXX")"
  bin="$d/bin"
  claude="$d/claude"
  log="$d/log"
  out="$d/out"
  mkdir -p "$bin" "$claude"
  : >"$log"
  local c
  for c in $core; do ln -s "$(command -v "$c")" "$bin/$c"; done
}

stub() { # stub <name>: records its call
  # shellcheck disable=SC2016  # the stub's text must stay literal
  printf '#!/bin/sh\necho "%s $*" >> "$LOG"\n' "$1" >"$bin/$1"
  chmod +x "$bin/$1"
}

stub_rtk() {
  cat >"$bin/rtk" <<'EOF'
#!/bin/sh
echo "rtk $*" >> "$LOG"
case "$1" in --version) echo "rtk 0.0.0-test" ;; esac
exit 0
EOF
  chmod +x "$bin/rtk"
}

# curl "downloads" a script that, when run, installs the rtk stub.
stub_curl() {
  cat >"$d/fake-rtk-installer.sh" <<EOF
#!/bin/sh
echo "rtk-installer-ran" >> "\$LOG"
cat > "$bin/rtk" <<'INNER'
#!/bin/sh
echo "rtk \$*" >> "\$LOG"
case "\$1" in --version) echo "rtk 0.0.0-test" ;; esac
exit 0
INNER
chmod +x "$bin/rtk"
EOF
  cat >"$bin/curl" <<EOF
#!/bin/sh
echo "curl \$*" >> "\$LOG"
while [ \$# -gt 0 ]; do [ "\$1" = -o ] && out="\$2"; shift; done
cp "$d/fake-rtk-installer.sh" "\$out"
EOF
  chmod +x "$bin/curl"
}

# stub_brew: `brew install rtk` also installs the rtk stub.
stub_brew() {
  cat >"$bin/brew" <<EOF
#!/bin/sh
echo "brew \$*" >> "\$LOG"
if [ "\$2" = rtk ]; then
  cat > "$bin/rtk" <<'INNER'
#!/bin/sh
echo "rtk \$*" >> "\$LOG"
case "\$1" in --version) echo "rtk 0.0.0-test" ;; esac
exit 0
INNER
  chmod +x "$bin/rtk"
fi
EOF
  chmod +x "$bin/brew"
}

base_tools() { stub git; stub gh; stub jq; stub sudo; stub apt-get; }

# run_installer <stdin-text> <args...>
run_installer() {
  local input="$1"
  shift
  set +e
  printf '%s' "$input" | PATH="$bin" HOME="$d" CLAUDE_DIR="$claude" LOG="$log" "$root/install-all.sh" "$@" >"$out" 2>&1
  rc=$?
  set -e
}

logged() { grep -qE "$1" "$log"; }
printed() { grep -qE "$1" "$out"; }
check() { # check <label> <command...>
  local label="$1"
  shift
  if "$@"; then pass "$label"; else
    fail "$label"
    sed 's/^/     | /' "$out" | head -20
    echo "     log:"
    sed 's/^/     | /' "$log" | head -10
  fi
}
not() { ! "$@"; }
no_install_calls() { ! grep -qE '^(sudo|apt-get|brew|curl|rtk-installer-ran)' "$log"; }

# 1. Everything present, answer no to RTK and to linking: nothing is installed.
new_sandbox
base_tools
stub shellcheck
run_installer $'n\nn\n'
check "all present, answers no: exit 0" test "$rc" = 0
check "all present, answers no: nothing installed" no_install_calls

# 2. jq missing: yes to jq, no to the rest.
new_sandbox
stub git; stub gh; stub sudo; stub apt-get; stub shellcheck
run_installer $'y\nn\nn\n'
check "jq missing, yes: installs jq with sudo apt-get" logged '^sudo apt-get install -y jq$'
check "jq missing, yes: does not install anything else" not logged 'apt-get install -y shellcheck|curl|brew'

# 3. jq missing and no terminal (end of input): nothing is installed.
new_sandbox
stub git; stub gh; stub sudo; stub apt-get
run_installer ''
check "no input: exit 0" test "$rc" = 0
check "no input: installs nothing" no_install_calls

# 4. --yes installs the dependencies but never RTK.
new_sandbox
stub git; stub gh; stub sudo; stub apt-get; stub_curl; stub_brew
run_installer '' --yes
check "--yes: installs jq" logged '^sudo apt-get install -y jq$'
check "--yes: installs shellcheck" logged '^sudo apt-get install -y shellcheck$'
check "--yes: does not install RTK" not logged '^(curl|brew)'
check "--yes: runs install.sh (links into CLAUDE_DIR)" test -d "$claude/skills"

# 5. --dry-run lists commands and runs none.
new_sandbox
stub git; stub gh; stub sudo; stub apt-get
run_installer '' --dry-run
check "--dry-run: lists the jq install" printed '^\+ sudo apt-get install -y jq$'
check "--dry-run: runs nothing" no_install_calls
check "--dry-run: links nothing" test ! -d "$claude/skills"

# 6. --with-rtk without brew: downloads the script, runs it, verifies, registers the hook.
new_sandbox
base_tools
stub shellcheck
stub_curl
printf '{"hooks":{}}\n' >"$claude/settings.json"
run_installer $'n\n' --with-rtk
check "--with-rtk (curl): downloads the install script" logged '^curl -fsSL .*rtk-ai/rtk.* -o '
check "--with-rtk (curl): runs the downloaded script" logged '^rtk-installer-ran$'
check "--with-rtk (curl): checks 'rtk gain'" logged '^rtk gain$'
check "--with-rtk (curl): previews the hook with --dry-run" logged '^rtk init -g --dry-run$'
check "--with-rtk (curl): backs up settings.json" test -f "$claude/settings.json.mise-en-code-backup"
check "--with-rtk (curl): registers the hook" logged '^rtk init -g --auto-patch$'

# 7. Interactive RTK: yes, yes (run the script), yes (register), no (link).
new_sandbox
base_tools
stub shellcheck
stub_curl
run_installer $'y\ny\ny\nn\n'
check "interactive RTK: script ran after the second yes" logged '^rtk-installer-ran$'
check "interactive RTK: registers the hook without --auto-patch" logged '^rtk init -g$'

# 8. Interactive RTK, but decline running the downloaded script.
new_sandbox
base_tools
stub shellcheck
stub_curl
run_installer $'y\nn\nn\n'
check "decline the script: it is downloaded but not run" not logged '^rtk-installer-ran$'
check "decline the script: says RTK is not installed" printed 'RTK is not installed'

# 9. brew present: RTK comes from brew, not from curl.
new_sandbox
base_tools
stub shellcheck
stub_brew
stub_curl
run_installer $'n\n' --with-rtk
check "--with-rtk (brew): uses brew install rtk" logged '^brew install rtk$'
check "--with-rtk (brew): does not use curl" not logged '^curl'

# 10. RTK already installed and registered: it is left alone.
new_sandbox
base_tools
stub shellcheck
stub_rtk
printf '{"hooks":{"PreToolUse":[{"hooks":[{"command":"rtk hook claude"}]}]}}\n' >"$claude/settings.json"
run_installer $'n\n'
check "RTK present and registered: no init" not logged '^rtk init'
check "RTK present and registered: no install" no_install_calls

# 11. gh missing with apt: not installed automatically, says where to get it.
new_sandbox
stub git; stub jq; stub sudo; stub apt-get; stub shellcheck
run_installer $'n\nn\n'
check "gh missing (apt): no install attempt" no_install_calls
check "gh missing (apt): points to cli.github.com" printed 'cli.github.com'

# 12. Option handling.
new_sandbox
base_tools
run_installer '' --nope
check "unknown option: exit 2" test "$rc" = 2
run_installer '' --help
check "--help: exit 0 and shows usage" printed 'Usage: ./install-all.sh'

[ "$failures" = 0 ] || { echo "$failures install-all test(s) failed"; exit 1; }
echo "all install-all tests passed"
