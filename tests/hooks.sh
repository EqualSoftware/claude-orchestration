#!/bin/bash
# Tests for the hook scripts. Each case gives a hook input and the expected result.
# Usage: tests/hooks.sh

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$(jq -r '.name' "$ROOT/.claude-plugin/plugin.json" | tr -d '\r')"
FAILED=0
COUNT=0

# expect <hook> <allow|deny> <json input>
expect() {
  local got
  got="$(CLAUDE_PLUGIN_ROOT="$ROOT" "$ROOT/hooks/$1" <<< "$3" | jq -r '.hookSpecificOutput.permissionDecision' | tr -d '\r')"
  # A hook that allows the call prints nothing.
  got="${got:-allow}"
  COUNT=$((COUNT + 1))
  [ "$got" = "$2" ] && return
  echo "FAIL $1 expected $2, got $got: $3"
  FAILED=$((FAILED + 1))
}

ARCHITECT="$PLUGIN:architect"
# agent <subagent_type> [session agent_type]
agent() { jq -nc --arg t "$1" --arg s "${2-$ARCHITECT}" '{tool_input: {subagent_type: $t}} + (if $s == "" then {} else {agent_type: $s} end)'; }
# worker_cmd <command> [subagent agent_type]
worker_cmd() { jq -nc --arg c "$1" --arg t "${2-$PLUGIN:builder}" '{agent_id: "a1", agent_type: $t, tool_input: {command: $c}}'; }
main_cmd() { jq -nc --arg c "$1" --arg s "$ARCHITECT" '{agent_type: $s, tool_input: {command: $c}}'; }

for name in builder builder-fast scout runner reviewer researcher; do
  expect check-agent.sh allow "$(agent "$PLUGIN:$name")"
done
expect check-agent.sh deny "$(agent "$PLUGIN:architect")"
expect check-agent.sh deny "$(agent "$PLUGIN:unknown")"
expect check-agent.sh deny "$(agent "builder")"
expect check-agent.sh deny "$(agent "Explore")"
expect check-agent.sh deny "$(agent "general-purpose")"
expect check-agent.sh deny "$(jq -nc --arg s "$ARCHITECT" '{agent_type: $s, tool_input: {}}')"
expect check-agent.sh deny "$(jq -nc --arg t "$PLUGIN:builder" --arg s "$ARCHITECT" '{agent_type: $s, tool_input: {subagent_type: $t, model: "opus"}}')"
expect check-agent.sh deny "$(jq -nc --arg t "$PLUGIN:builder" --arg s "$ARCHITECT" '{agent_type: $s, tool_input: {subagent_type: $t, effort: "high"}}')"
# Sessions that do not run the architect are not changed.
expect check-agent.sh allow "$(agent "Explore" "")"
expect check-agent.sh allow "$(agent "general-purpose" "general-purpose")"
expect check-agent.sh allow "$(jq -nc '{tool_input: {subagent_type: "Plan", model: "opus"}}')"

for c in "git status" "git diff --stat" "git log -5" "git -C /tmp/x show HEAD" "git branch --show-current" \
  "git worktree list" "git mv a b" "ls && git status"; do
  expect check-worker-git.sh allow "$(worker_cmd "$c")"
done
# shellcheck disable=SC2016 # The command text must stay literal.
for c in "git push" "git commit -m x" "git add ." "git -C /tmp/x commit -m x" "git branch -D x" \
  "git worktree add x" "git checkout main" "git reset --hard" "git stash" 'sh -c "git push"' \
  "ls; git push" "/usr/bin/git push" 'git $(echo push)' "git.exe push" "Git push" \
  'C:\Program Files\Git\cmd\git.exe commit -m x' "& git commit -m x" "git status; git push origin main" \
  '"C:\Program Files\Git\cmd\git.exe" push'; do
  expect check-worker-git.sh deny "$(worker_cmd "$c")"
done
expect check-worker-git.sh allow "$(main_cmd "git commit -m x")"
# Subagents that are not of the plugin are not changed.
expect check-worker-git.sh allow "$(worker_cmd "git push" "Explore")"
expect check-worker-git.sh allow "$(worker_cmd "git commit -m x" "")"

# expect_rules <yes|no> <json input>
expect_rules() {
  local got=no
  CLAUDE_PLUGIN_ROOT="$ROOT" "$ROOT/hooks/inject-rules.sh" <<< "$2" |
    jq -e --rawfile r "$ROOT/RULES.md" '.hookSpecificOutput.additionalContext == $r' > /dev/null && got=yes
  COUNT=$((COUNT + 1))
  [ "$got" = "$1" ] && return
  echo "FAIL inject-rules.sh expected $1, got $got: $2"
  FAILED=$((FAILED + 1))
}

rules_input() { jq -nc --arg e "$1" --arg t "$2" '{hook_event_name: $e} + (if $t == "" then {} else {agent_type: $t} end)'; }

expect_rules no "$(rules_input SessionStart "")"
expect_rules yes "$(rules_input SessionStart "$PLUGIN:architect")"
expect_rules no "$(rules_input SessionStart "other-agent")"
for name in builder builder-fast scout runner reviewer researcher; do
  expect_rules yes "$(rules_input SubagentStart "$PLUGIN:$name")"
done
expect_rules no "$(rules_input SubagentStart "Explore")"
expect_rules no "$(rules_input SubagentStart "")"

# Without jq, the hooks block only the calls that name an agent of the plugin.
# Git Bash on Windows copies a program on "ln -s", and a copy of bash does not start, so skip these cases there.
case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) SKIP_NOJQ=1 ;; *) SKIP_NOJQ=0 ;; esac
NOJQ="$(mktemp -d)"
for tool in bash cat sed head dirname; do ln -s "$(command -v "$tool")" "$NOJQ/$tool"; done
# expect_nojq <hook> <exit code> <json input>
expect_nojq() {
  [ "$SKIP_NOJQ" = 1 ] && return
  local got=0
  CLAUDE_PLUGIN_ROOT="$ROOT" PATH="$NOJQ" "$ROOT/hooks/$1" <<< "$3" > /dev/null 2>&1 || got=$?
  COUNT=$((COUNT + 1))
  [ "$got" = "$2" ] && return
  echo "FAIL $1 without jq expected exit $2, got $got: $3"
  FAILED=$((FAILED + 1))
}
expect_nojq check-agent.sh 2 "$(agent "$PLUGIN:builder")"
expect_nojq check-agent.sh 0 "$(agent "Explore" "")"
expect_nojq check-worker-git.sh 2 "$(worker_cmd "git push")"
expect_nojq check-worker-git.sh 0 "$(worker_cmd "git push" "Explore")"
expect_nojq inject-rules.sh 0 "$(rules_input SubagentStart "$PLUGIN:builder")"
rm -rf "$NOJQ"

echo "$((COUNT - FAILED)) of $COUNT hook tests pass."
[ "$FAILED" -eq 0 ]
