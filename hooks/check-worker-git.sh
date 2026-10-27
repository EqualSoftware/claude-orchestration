#!/bin/bash
# PreToolUse hook for the Bash and PowerShell tools. A worker agent of the
# plugin (a call with agent_id and a plugin agent_type) may run only git
# commands that read the repository, and git mv and git rm. Other agents are
# not changed.

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INPUT="$(cat)"
if ! command -v jq > /dev/null; then
  # Without jq, block only the calls that name an agent of the plugin. Other sessions are not changed.
  PLUGIN="$(sed -n 's/^ *"name": *"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json" | head -n 1)"
  [[ "$INPUT" == *"\"$PLUGIN:"* ]] || exit 0
  echo "check-worker-git.sh: jq is not installed. Install jq to use the worker agents." >&2
  exit 2
fi
# Read a field of the hook input. Native jq on Windows ends lines with CRLF, so remove the CR.
field() { jq -r "$1" <<< "$INPUT" | tr -d '\r'; }
PLUGIN="$(jq -r '.name' "$ROOT/.claude-plugin/plugin.json" | tr -d '\r')"
[ -n "$(field '.agent_id // empty')" ] || exit 0
[[ "$(field '.agent_type // empty')" == "$PLUGIN":* ]] || exit 0
CMD="$(field '.tool_input.command // empty')"

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

# Allowed subcommands. "branch" needs --show-current or --list. "worktree" needs list.
allowed() {
  case "$1" in
    status | diff | log | show | ls-files | grep | blame | rev-parse | merge-base | mv | rm) return 0 ;;
    branch) [[ " $2 $3 " == *" --show-current "* || " $2 $3 " == *" --list "* ]] ;;
    worktree) [ "$2" = "list" ] ;;
    *) return 1 ;;
  esac
}

# Is the word the git program? Accept a path with / or \, the .exe name and any letter case.
is_git() {
  local name="${1##*/}"
  name="$(tr '[:upper:]' '[:lower:]' <<< "${name##*\\}")"
  [ "$name" = git ] || [ "$name" = git.exe ]
}

# Split the command at Bash and PowerShell separators and quotes. Check each part that has git.
while IFS= read -r PART; do
  read -r -a W <<< "$PART"
  for ((i = 0; i < ${#W[@]}; i++)); do
    is_git "${W[i]}" || continue
    j=$((i + 1))
    # Skip global options. -C and -c take one value.
    while [[ "${W[j]}" == -* ]]; do
      case "${W[j]}" in -C | -c) j=$((j + 2)) ;; *) j=$((j + 1)) ;; esac
    done
    allowed "${W[j]}" "${W[j + 1]}" "${W[j + 2]}" ||
      deny "Worker agents do not change git state. Report to the main session."
  done
done < <(tr '&;|(){}`"$'"'" '\n' <<< "$CMD")
exit 0
