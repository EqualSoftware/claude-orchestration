#!/bin/bash
# PreToolUse hook for the Agent tool. In a session of the architect, allow only
# the worker agents of the plugin (agents/*.md except architect), as
# "<plugin name>:<name>". Deny the model and effort parameters and Opus workers.
# Other sessions are not changed.

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INPUT="$(cat)"
if ! command -v jq > /dev/null; then
  # Without jq, block only the calls that name an agent of the plugin. Other sessions are not changed.
  PLUGIN="$(sed -n 's/^ *"name": *"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json" | head -n 1)"
  [[ "$INPUT" == *"\"$PLUGIN:"* ]] || exit 0
  echo "check-agent.sh: jq is not installed. Install jq to use the architect." >&2
  exit 2
fi
# Read a field of the hook input. Native jq on Windows ends lines with CRLF, so remove the CR.
field() { jq -r "$1" <<< "$INPUT" | tr -d '\r'; }
PLUGIN="$(jq -r '.name' "$ROOT/.claude-plugin/plugin.json" | tr -d '\r')"
SESSION="$(field '.agent_type // empty')"
TYPE="$(field '.tool_input.subagent_type // empty')"
MODEL="$(field '.tool_input.model // empty')"
EFFORT="$(field '.tool_input.effort // empty')"
DIR="$ROOT/agents"
[ "$SESSION" = "$PLUGIN:architect" ] || exit 0

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

WORKERS="$(for f in "$DIR"/*.md; do basename "$f" .md; done | grep -vx architect | sed "s/^/$PLUGIN:/" | paste -sd, -)"
NAME="${TYPE#"$PLUGIN":}"

[ -z "$MODEL$EFFORT" ] || deny "Do not pass model or effort. The agent file sets them."
[ -n "$TYPE" ] || deny "Give subagent_type. Allowed: $WORKERS."
[[ "$TYPE" == "$PLUGIN":* ]] || deny "Agent type '$TYPE' is not a worker agent. Allowed: $WORKERS."
[ "$NAME" != "architect" ] || deny "$PLUGIN:architect is the main session agent. Allowed: $WORKERS."
[[ "$NAME" =~ ^[a-z-]+$ && -f "$DIR/$NAME.md" ]] || deny "Agent type '$TYPE' is not a worker agent. Allowed: $WORKERS."
grep -qx 'model: opus' "$DIR/$NAME.md" && deny "A worker agent must not use Opus. Change the model in $NAME.md."
exit 0
