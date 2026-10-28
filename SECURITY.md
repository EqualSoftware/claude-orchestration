# Security policy

## Supported versions

Only the latest release gets security fixes. Run `claude plugin update dx-agents@claude-orchestration` to get it.

## Report a vulnerability

Do not open a public issue.

Use the private report form of GitHub: go to the **Security** tab of this repository and click **Report a vulnerability**. Only the maintainers can see the report.

Give:

- the plugin version (in `/plugin`) and the Claude Code version (`claude --version`),
- the operating system,
- the steps to reproduce the problem,
- the effect (example: a worker agent that changes git state, a blocked agent type that starts).

The maintainers reply as soon as possible. When a fix is available, the maintainers publish a release and a security advisory, and give credit to the reporter if the reporter agrees.

## Scope

These parts are important for security:

- `hooks/inject-rules.sh`: the hook that adds the shared rules to the context of each agent.
- `hooks/check-agent.sh`: the hook that lets the architect start only the worker agents and blocks the `model` and `effort` parameters.
- The `disallowedTools` of each agent file.

The hooks act only on the agents of the plugin. The hooks and the rules reduce risk. They are not a sandbox. A worker agent can still run other shell commands and use the MCP tools of the session. Use the permission settings of Claude Code to limit them.
