#!/bin/bash
# SessionStart and SubagentStart hook. Add RULES.md to the context of the
# architect and of each worker agent of the plugin, so that no agent must read
# the file from the plugin folder. Other sessions and subagents are not changed.

if ! command -v jq > /dev/null; then
  echo "inject-rules.sh: jq is not installed. Install jq to give the rules to the agents." >&2
  exit 0
fi
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INPUT="$(cat)"
# Read a field of the hook input. Native jq on Windows ends lines with CRLF, so remove the CR.
field() { jq -r "$1" <<< "$INPUT" | tr -d '\r'; }
PLUGIN="$(jq -r '.name' "$ROOT/.claude-plugin/plugin.json" | tr -d '\r')"
EVENT="$(field '.hook_event_name // empty')"
TYPE="$(field '.agent_type // empty')"

[[ "$TYPE" == "$PLUGIN":* ]] || exit 0

jq -n --arg e "$EVENT" --rawfile r "$ROOT/RULES.md" \
  '{hookSpecificOutput: {hookEventName: $e, additionalContext: $r}}'
