#!/bin/bash
# Report the token usage of one Claude Code session, for each agent and model.
# The agent is "main" for the session file, else the agentType of the subagent.
# Needs bash 3.2 or later and jq.
# Usage: scripts/token-usage.sh <session id | path to session .jsonl>

usage() {
  echo "Usage: scripts/token-usage.sh <session id | path to session .jsonl>" >&2
  exit 1
}

# Print the session file for an id or a path.
find_session() {
  local arg="$1" file
  [ -f "$arg" ] && { echo "$arg"; return 0; }
  for file in "$HOME"/.claude/projects/*/"$arg".jsonl; do
    [ -f "$file" ] && { echo "$file"; return 0; }
  done
  return 1
}

# Print "agent<TAB>model<TAB>input<TAB>cache write<TAB>cache read<TAB>output" for each
# model of one file. One message is on many lines, so count each message id one time.
# Native jq on Windows ends lines with CRLF, so remove the CR.
file_usage() {
  local agent="$1" file="$2"
  jq -rs --arg a "$agent" '
    [.[] | select(.type == "assistant" and .message.usage != null)]
    | unique_by(.message.id // .uuid)
    | group_by(.message.model // "unknown")[]
    | [$a, (.[0].message.model // "unknown"),
       (map(.message.usage.input_tokens // 0) | add),
       (map(.message.usage.cache_creation_input_tokens // 0) | add),
       (map(.message.usage.cache_read_input_tokens // 0) | add),
       (map(.message.usage.output_tokens // 0) | add)]
    | @tsv' "$file" | tr -d '\r'
}

# Print the agent name of a subagent file: agentType of the meta file, else the file name.
agent_name() {
  local file="$1" name
  name="$(jq -r '.agentType // empty' "${file%.jsonl}.meta.json" 2> /dev/null | tr -d '\r')"
  echo "${name:-$(basename "$file" .jsonl)}"
}

# Print the usage lines of the session file and of its subagent files.
all_usage() {
  local session="$1" file
  file_usage main "$session"
  for file in "${session%.jsonl}"/subagents/agent-*.jsonl; do
    [ -f "$file" ] && file_usage "$(agent_name "$file")" "$file"
  done
}

# Print the table, sorted by model and agent. Rows with the same agent and model
# are added together. A total row ends each model.
print_table() {
  sort -t "$(printf '\t')" -k2,2 -k1,1 | awk -F '\t' '
    function row(name, mdl, v) {
      printf "%-28s %-24s %12d %12d %12d %10d\n", name, mdl, v[3], v[4], v[5], v[6]
    }
    function flushrow(   i) {
      if (agent == "") return
      row(agent, model, r)
      for (i = 3; i <= 6; i++) t[i] += r[i]
    }
    function flushmodel() {
      flushrow()
      if (model == "") return
      row("total", model, t)
      print ""
    }
    BEGIN {
      printf "%-28s %-24s %12s %12s %12s %10s\n", "agent", "model", "input", "cache write", "cache read", "output"
    }
    $1 != agent || $2 != model {
      if ($2 != model) { flushmodel(); t[3] = t[4] = t[5] = t[6] = 0 } else flushrow()
      agent = $1; model = $2; r[3] = r[4] = r[5] = r[6] = 0
    }
    { for (i = 3; i <= 6; i++) r[i] += $i }
    END { flushmodel() }'
}

[ $# -eq 1 ] || usage
command -v jq > /dev/null || { echo "token-usage.sh: jq is not installed." >&2; exit 1; }
SESSION="$(find_session "$1")" || { echo "token-usage.sh: session not found: $1" >&2; usage; }
all_usage "$SESSION" | print_table
