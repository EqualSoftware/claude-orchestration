#!/bin/bash
# PreToolUse hook for the Read tool. In a session of the architect, deny a full
# read of a text file with more lines than the limit, so that the architect gives
# the question to dx-agents:scout or reads a section. The limit is the variable
# DX_AGENTS_MAX_READ_LINES (default 350, 0 turns the hook off).
# Other sessions are not changed.

if ! command -v jq > /dev/null; then
  echo "check-read.sh: jq is not installed. Install jq to limit the full reads." >&2
  exit 0
fi
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INPUT="$(cat)"
# Read a field of the hook input. Native jq on Windows ends lines with CRLF, so remove the CR.
field() { jq -r "$1" <<< "$INPUT" 2> /dev/null | tr -d '\r'; }
SESSION="$(field '.agent_type // empty')"
[[ "$SESSION" == *:architect ]] || exit 0
PLUGIN="$(jq -r '.name' "$ROOT/.claude-plugin/plugin.json" | tr -d '\r')"
[ "$SESSION" = "$PLUGIN:architect" ] || exit 0

MAX="${DX_AGENTS_MAX_READ_LINES:-350}"
[[ "$MAX" =~ ^[0-9]+$ ]] || MAX=350
MAX=$((10#$MAX))
[ "$MAX" -gt 0 ] || exit 0

[ -z "$(field '.tool_input.offset // empty, .tool_input.limit // empty, .tool_input.pages // empty')" ] || exit 0
FILE="$(field '.tool_input.file_path // empty')"
[ -f "$FILE" ] || exit 0
[ ! -s "$FILE" ] || LC_ALL=C grep -Iq -e . -- "$FILE" || exit 0

LINES="$(wc -l < "$FILE" | tr -d ' ')"
[ "$LINES" -gt "$MAX" ] || exit 0

jq -n --arg r "The file has $LINES lines (limit $MAX). Give the question to $PLUGIN:scout, or read only the necessary section with offset and limit." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $r}}'
