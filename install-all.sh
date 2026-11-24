#!/usr/bin/env bash
# Guided installer: checks the dependencies, offers to install the missing ones, and then
# runs install.sh. Nothing is installed without a yes.
#
# Usage: ./install-all.sh [--yes] [--with-rtk] [--dry-run]
#   --yes        answer yes to the dependency questions (not to RTK; see --with-rtk)
#   --with-rtk   also install RTK, the optional token saver, without asking
#   --dry-run    print what would be done and change nothing
set -eo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="${CLAUDE_DIR:-$HOME/.claude}"
rtk_script_url="https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh"

assume_yes=0
with_rtk=0
dry_run=0
for arg in "$@"; do
  case "$arg" in
    --yes) assume_yes=1 ;;
    --with-rtk) with_rtk=1 ;;
    --dry-run) dry_run=1 ;;
    -h | --help)
      sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg (see --help)" >&2
      exit 2
      ;;
  esac
done

have() { command -v "$1" >/dev/null 2>&1; }

# ask <question>: yes only on an explicit "y". End of input (no terminal) counts as no.
# In a dry run nothing is asked: the step is listed as if the answer were yes.
ask() {
  local reply
  if [ "$dry_run" = 1 ]; then
    echo "$1 [dry run: would ask]"
    return 0
  fi
  if [ "$assume_yes" = 1 ]; then
    echo "$1 [yes, --yes]"
    return 0
  fi
  read -r -p "$1 [y/N] " reply || return 1
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ask_rtk <question>: --yes does not cover RTK. Only --with-rtk or an explicit "y" does.
ask_rtk() {
  local reply
  if [ "$with_rtk" = 1 ]; then
    echo "$1 [yes, --with-rtk]"
    return 0
  fi
  if [ "$dry_run" = 1 ]; then
    echo "$1 [dry run: would ask]"
    return 0
  fi
  read -r -p "$1 [y/N] " reply || return 1
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# run <command...>: print the command, then run it unless this is a dry run.
run() {
  echo "+ $*"
  if [ "$dry_run" = 1 ]; then return 0; fi
  "$@"
}

sudo_cmd=""
if [ "$(id -u)" -ne 0 ] && have sudo; then sudo_cmd="sudo"; fi

pm=""
if have apt-get; then
  pm=apt
elif have dnf; then
  pm=dnf
elif have pacman; then
  pm=pacman
elif have brew; then
  pm=brew
fi

# install_cmd <tool>: the command that installs it, or nothing when it is not automated.
install_cmd() {
  local tool="$1" pkg="$1"
  case "$pm" in
    apt)
      # GitHub's CLI is not in the default apt sources; adding a repository is not automated.
      [ "$tool" = gh ] && return 0
      echo "$sudo_cmd apt-get install -y $pkg"
      ;;
    dnf) echo "$sudo_cmd dnf install -y $pkg" ;;
    pacman)
      [ "$tool" = gh ] && pkg=github-cli
      echo "$sudo_cmd pacman -S --noconfirm $pkg"
      ;;
    brew) echo "brew install $pkg" ;;
  esac
}

# offer_install <tool> <why>
offer_install() {
  local tool="$1" why="$2" cmd
  cmd="$(install_cmd "$tool" | sed 's/^ *//')"
  if [ -z "$cmd" ]; then
    echo "  $tool is missing ($why). It is not installed automatically here: see https://cli.github.com"
    return 1
  fi
  if ask "  Install $tool ($why) with '$cmd'?"; then
    # shellcheck disable=SC2086  # $cmd is a fixed command line built above, split on purpose
    run $cmd
  else
    echo "  skipped $tool"
    return 1
  fi
}

echo "mise-en-code installer"
echo
echo "Dependencies"
if ! have git; then
  echo "  git is missing. Install git first, then run this script again." >&2
  exit 1
fi
echo "  ok       git"

missing_required=0
for tool in gh jq; do
  if have "$tool"; then
    echo "  ok       $tool"
  else
    case "$tool" in
      gh) why="needed by the project-board skill and the workflow" ;;
      jq) why="needed by the hooks" ;;
    esac
    offer_install "$tool" "$why" || missing_required=1
  fi
done

if have shellcheck; then
  echo "  ok       shellcheck"
else
  offer_install shellcheck "optional: only to run scripts/check.sh locally; CI runs it" || true
fi

echo
echo "RTK (optional: shortens command output to save tokens)"
install_rtk=0
if have rtk; then
  echo "  ok       $(rtk --version 2>/dev/null | head -n 1)"
elif ask_rtk "  Install RTK?"; then
  install_rtk=1
else
  echo "  skipped RTK"
fi

if [ "$install_rtk" = 1 ]; then
  if have brew; then
    run brew install rtk
  elif have curl; then
    script="$(mktemp)"
    run curl -fsSL "$rtk_script_url" -o "$script"
    if [ "$dry_run" = 0 ]; then
      echo "  RTK's install script is saved at $script ($(wc -c <"$script") bytes). Read it with: less $script"
      if ask_rtk "  Run it now?"; then
        run sh "$script"
      else
        echo "  not run. RTK is not installed."
      fi
    fi
    rm -f "$script"
  else
    echo "  neither brew nor curl is available. See https://github.com/rtk-ai/rtk" >&2
  fi
  if [ "$dry_run" = 0 ] && have rtk; then
    # Another package is also named rtk: `rtk gain` shows the savings dashboard only for this one.
    if rtk gain >/dev/null 2>&1; then
      echo "  ok       $(rtk --version 2>/dev/null | head -n 1)"
    else
      echo "  'rtk gain' failed: this may be a different package named rtk." >&2
    fi
  fi
fi

if have rtk && [ "$dry_run" = 0 ] && ! grep -qs 'rtk hook' "$claude_dir/settings.json"; then
  echo
  echo "RTK is installed but its hook is not registered in $claude_dir/settings.json. Preview:"
  rtk init -g --dry-run || true
  if ask_rtk "  Register it? (settings.json is backed up first; undo with: rtk init -g --uninstall)"; then
    if [ -f "$claude_dir/settings.json" ]; then
      run cp "$claude_dir/settings.json" "$claude_dir/settings.json.mise-en-code-backup"
    fi
    if [ "$with_rtk" = 1 ]; then
      run rtk init -g --auto-patch
    else
      run rtk init -g
    fi
  fi
fi

echo
echo "Skills, agents, and hooks"
if [ "$missing_required" = 1 ]; then
  echo "  Required dependencies are missing; the hooks and the project-board skill need them."
fi
if ask "  Link them into $claude_dir now (runs install.sh)?"; then
  run "$repo/install.sh"
else
  echo "  not linked. Run ./install.sh when you are ready."
fi

echo
echo "Next: register the hooks you want in $claude_dir/settings.json, copying from settings.example.json."
