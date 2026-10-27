# CLAUDE.md

This repository is the `dx-agents` Claude Code plugin and its marketplace, `claude-orchestration`. Read [CONTRIBUTING.md](../CONTRIBUTING.md) for the setup, the checks and the commit rules.

## dx-agents profile

- Language: ASD-STE100
- Acceptance check: `scripts/check.sh`
  - Checks: Validate, Lint, Hook tests
- Independent review areas: hooks, agent tool permissions
- Commit scopes: agents, hooks, rules, marketplace, docs, ci
- Main branch: main

## Rules

- The plugin must stay generic. Do not add rules, tools or names that only one language or one project uses.
- Do not change `version` in `.claude-plugin/plugin.json` by hand. release-please sets it.
- A change to a hook needs a test case in `tests/hooks.sh`.
