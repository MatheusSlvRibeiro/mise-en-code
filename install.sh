#!/usr/bin/env bash
# The mise-en-code installer. It links the skills, agents, and hooks into ~/.claude/, and
# offers the extras: missing dependencies, RTK, and registering the hooks in settings.json.
# Linking only creates symlinks and is safe to repeat. Everything else asks first, and
# no terminal (end of input) counts as no.
#
# Usage: ./install.sh [--yes] [--with-rtk] [--dry-run]
#   --yes        answer yes to the questions (not to RTK; see --with-rtk)
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
      sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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

settings="$claude_dir/settings.json"
backup_made=0
# backup_settings: copy settings.json once per run, with a timestamp so earlier backups survive.
backup_settings() {
  if [ "$backup_made" = 1 ] || [ ! -f "$settings" ]; then return 0; fi
  run cp "$settings" "$settings.mise-en-code-backup-$(date +%Y%m%d%H%M%S)"
  backup_made=1
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

# link <source> <destination>: a symlink to this repo. Never replaces anything that is not
# already a link to the same place.
skipped=0
link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ok       $dest"
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "  skipped  $dest (exists and is not a link to this repo)" >&2
    skipped=1
  elif [ "$dry_run" = 1 ]; then
    echo "  would link $dest"
  else
    ln -s "$src" "$dest"
    echo "  linked   $dest"
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

if have rtk && [ "$dry_run" = 0 ] && ! grep -qs 'rtk hook' "$settings"; then
  echo
  echo "RTK is installed but its hook is not registered in $settings. Preview:"
  rtk init -g --dry-run || true
  if ask_rtk "  Register it? (settings.json is backed up first; undo with: rtk init -g --uninstall)"; then
    backup_settings
    if [ "$with_rtk" = 1 ]; then
      run rtk init -g --auto-patch
    else
      run rtk init -g
    fi
  fi
fi

echo
echo "Skills, agents, and hooks (symlinks into $claude_dir)"
if [ "$missing_required" = 1 ]; then
  echo "  Required dependencies are missing; the hooks and the project-board skill need them."
fi
if [ "$dry_run" = 0 ]; then
  mkdir -p "$claude_dir/skills" "$claude_dir/agents" "$claude_dir/hooks"
fi
for dir in "$repo"/skills/*/; do
  [ -d "$dir" ] || continue
  link "${dir%/}" "$claude_dir/skills/$(basename "$dir")"
done
for file in "$repo"/agents/*.md; do
  [ -f "$file" ] || continue
  link "$file" "$claude_dir/agents/$(basename "$file")"
done
for file in "$repo"/hooks/*.sh; do
  [ -f "$file" ] || continue
  link "$file" "$claude_dir/hooks/$(basename "$file")"
done

# The hooks that settings.example.json shows. $HOME stays literal: the shell expands it when
# Claude Code runs the hook. readonly-bash.sh is not here: only the reviewer agent uses it.
# shellcheck disable=SC2016  # literal $HOME on purpose
hooks_wanted='[
  {"event": "PreToolUse", "matcher": "Bash", "command": "$HOME/.claude/hooks/block-main-push.sh"},
  {"event": "PostToolUse", "matcher": "Edit|Write|MultiEdit", "command": "$HOME/.claude/hooks/lint-on-edit.sh"}
]'

# Add each wanted hook to settings.json unless a hook with the same command is already there.
# Other entries (RTK's, for example) are left exactly as they are.
# shellcheck disable=SC2016  # $wanted and $h are jq variables, not shell ones
add_hooks_filter='
  reduce $wanted[] as $h (.;
    if any(.hooks[$h.event][]?.hooks[]?; .command == $h.command)
    then .
    else .hooks[$h.event] = ((.hooks[$h.event] // []) + [{"matcher": $h.matcher, "hooks": [{"type": "command", "command": $h.command}]}])
    end)'

register_hooks() {
  local name current updated
  if ! have jq; then
    echo "  jq is missing, so the hooks were not registered. Install jq and run this script again."
    return 0
  fi
  if [ "$dry_run" = 0 ]; then
    # A hook that points to a missing file fails on every tool call, so require the links first.
    for name in block-main-push lint-on-edit; do
      if [ ! -x "$claude_dir/hooks/$name.sh" ]; then
        echo "  $name.sh is not linked in $claude_dir/hooks, so the hooks were not registered."
        return 0
      fi
    done
  fi
  if [ -f "$settings" ]; then
    if ! current="$(jq . "$settings" 2>/dev/null)"; then
      echo "  $settings is not valid JSON. It was not touched; fix it and run this script again." >&2
      return 1
    fi
  else
    current="{}"
  fi
  updated="$(jq --argjson wanted "$hooks_wanted" "$add_hooks_filter" <<<"$current")"
  if [ "$(jq -S . <<<"$current")" = "$(jq -S . <<<"$updated")" ]; then
    echo "  The mise-en-code hooks are already registered in $settings."
    return 0
  fi
  echo "  This would change $settings:"
  diff -u <(echo "$current") <(echo "$updated") | tail -n +3 | sed 's/^/    /' || true
  if ask "  Register them? (a backup is taken first)"; then
    backup_settings
    echo "+ write $settings"
    if [ "$dry_run" = 0 ]; then
      mkdir -p "$claude_dir"
      echo "$updated" >"$settings.tmp" && mv "$settings.tmp" "$settings"
    fi
  else
    echo "  not registered. Copy the entries you want from settings.example.json."
  fi
}

echo
echo "Hooks (block pushes to main and preview, lint on edit)"
register_hooks || true

echo
echo "Done. Restart Claude Code so it loads the hooks."
exit "$skipped"
