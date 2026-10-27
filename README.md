# claude-orchestration

`dx-agents` is a Claude Code plugin for agent orchestration. It works with any project, in any language. An architect agent plans with you and gives the work to worker agents. The agents use the tools of each project: its language servers, skills, commands and MCP tools.

The plugin gives:

- **Agents.** `dx-agents:architect` is the main session agent (Opus). It plans and orchestrates. The workers are `dx-agents:builder`, `dx-agents:builder-fast`, `dx-agents:scout`, `dx-agents:runner`, `dx-agents:reviewer` and `dx-agents:researcher` (Sonnet and Haiku).
- **Tools.** The agents set `disallowedTools`, not a closed `tools` list. They get all the tools of the session, also the language servers, skills and MCP tools of the project. The workers cannot start agents. `dx-agents:runner`, `dx-agents:reviewer` and `dx-agents:researcher` do not get the file edit tools.
- **Tool order.** An agent that reads or changes code or files uses the language server first, then the tools of the project (skills, MCP tools, formatters, linters, generators, build and task scripts), and the generic file tools last.
- **Hooks.** The hooks act only on the agents of the plugin. One hook adds `RULES.md` to the context of each agent. One hook lets the architect start only the worker agents and blocks the `model` and `effort` parameters. One hook allows a worker agent only the `git` commands that read the repository, and `git mv` and `git rm`.
- **Rules.** `RULES.md` holds the shared rules. Each agent obeys them and the `CLAUDE.md` of the project.

The architect runs only in the projects where you turn it on. See [Install](#install).

## Requirements

The plugin works on macOS, Linux and Windows. It needs:

| Tool | Version | Why |
| :--- | :--- | :--- |
| Claude Code | 2.1.308 or later | Runs the agents and the hooks |
| git | 2.30 or later | Claude Code clones the plugin with git. The agents use git |
| `bash` | 3.2 or later | Runs the hooks. macOS and Linux have it. On Windows, it is Git Bash, from Git for Windows |
| [jq](https://jqlang.org/) | 1.6 or later | The hooks read their input with jq |

On Windows, the hooks need Git Bash. Without it, Claude Code runs the hooks in PowerShell, and they fail.

### Install jq

```sh
brew install jq                  # macOS, with Homebrew
sudo apt install jq              # Debian and Ubuntu
sudo dnf install jq              # Fedora and RHEL
sudo pacman -S jq                # Arch
sudo zypper install jq           # openSUSE
winget install --id jqlang.jq -e # Windows, in PowerShell
```

On Windows, close the terminal and open a new one, so that the new `PATH` applies. In WSL, use the Linux command in the WSL terminal.

To check it, run `jq --version`. On Windows, run it in Git Bash. It must print `jq-1.6` or later.

## Install

The plugin is in early testing (version `0.x`). It is not in the Anthropic plugin directory. You install it directly from GitHub: this repository is the plugin and also a marketplace with this one plugin.

Install the [requirements](#requirements) first.

The install has two steps: install the plugin, then turn on the architect in a project. The plugin does not change a session until you turn on the architect. Sessions that do not run the architect keep all the agents and behavior of Claude Code.

### 1. Install the plugin

Select the scope:

| Scope | Who gets the plugin | Where Claude Code writes it |
| :--- | :--- | :--- |
| `user` | You, in all your projects | `~/.claude/settings.json` (on Windows, `%USERPROFILE%\.claude\settings.json`) |
| `project` | All the people who work in the project | `.claude/settings.json` of the project, which you commit |
| `local` | You, in this project only | `.claude/settings.local.json` of the project, which you do not commit |

Run the commands in a terminal: on macOS and Linux in your shell, on Windows in PowerShell or Git Bash.

For the `user` scope:

```sh
claude plugin marketplace add EqualSoftware/claude-orchestration
claude plugin install dx-agents@claude-orchestration
```

For the `project` scope, run the commands in the project folder, then commit `.claude/settings.json`:

```sh
claude plugin marketplace add EqualSoftware/claude-orchestration --scope project
claude plugin install dx-agents@claude-orchestration --scope project
```

Each person who opens the project and trusts the folder then gets the plugin. You can also write the same keys in `.claude/settings.json` yourself:

```json
{
  "extraKnownMarketplaces": {
    "claude-orchestration": {
      "source": { "source": "github", "repo": "EqualSoftware/claude-orchestration" }
    }
  },
  "enabledPlugins": {
    "dx-agents@claude-orchestration": true
  }
}
```

For the `local` scope, run the commands in the project folder:

```sh
claude plugin marketplace add EqualSoftware/claude-orchestration --scope local
claude plugin install dx-agents@claude-orchestration --scope local
```

In a Claude Code session, `/plugin marketplace add EqualSoftware/claude-orchestration` adds the marketplace, and `/plugin install dx-agents@claude-orchestration` lets you select the scope.

### 2. Turn on the architect

The architect is the main session agent. To start each session of a project as the architect, add the `agent` key to a settings file of the project. The file is in the `.claude` folder at the root of the project. If the folder or the file does not exist, make it. If the file exists, add the key to the object that is already there, and keep the other keys.

- For all the people in the project, use `.claude/settings.json` and commit it. With the `project` scope install, the file then has:

  ```json
  {
    "extraKnownMarketplaces": {
      "claude-orchestration": {
        "source": { "source": "github", "repo": "EqualSoftware/claude-orchestration" }
      }
    },
    "enabledPlugins": {
      "dx-agents@claude-orchestration": true
    },
    "agent": "dx-agents:architect"
  }
  ```

- For you only, use `.claude/settings.local.json`. Do not commit this file. For example:

  ```json
  {
    "agent": "dx-agents:architect"
  }
  ```

Start a new session in the project to use the setting. To check it, ask the session which agent it is.

To start one session as the architect without a setting, run `claude --agent dx-agents:architect`. To start one session without the architect in a project that sets it, run `claude --agent general-purpose`.

### Pin a version

To stay on one release, add its tag to the marketplace source. The [releases](https://github.com/EqualSoftware/claude-orchestration/releases) page lists the versions. Replace `<version>` with one of them, for example `0.1.0`.

- With the command: `claude plugin marketplace add EqualSoftware/claude-orchestration#v<version> --scope <scope>`, with the same scope as the install. If you added the marketplace before, first remove it with `claude plugin marketplace remove claude-orchestration`. This also uninstalls the plugin, so install it again after you add the marketplace.
- In the settings: add `ref` to the `source` object.

  ```json
  {
    "extraKnownMarketplaces": {
      "claude-orchestration": {
        "source": { "source": "github", "repo": "EqualSoftware/claude-orchestration", "ref": "v<version>" }
      }
    }
  }
  ```

### Update

Auto-update is off by default. To get a new version:

- In your shell: `claude plugin update dx-agents@claude-orchestration`. Claude Code finds the scope of the install.
- In a session: `/plugin marketplace update claude-orchestration`.

To turn on auto-update, run `/plugin` in a session, go to **Marketplaces**, select `claude-orchestration` and select **Enable auto-update**. For all the people in a project, add `"autoUpdate": true` to the marketplace in `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-orchestration": {
      "source": { "source": "github", "repo": "EqualSoftware/claude-orchestration" },
      "autoUpdate": true
    }
  }
}
```

### Remove

Use the same scope as the install. Replace `<scope>` with `user`, `project` or `local`:

```sh
claude plugin uninstall dx-agents@claude-orchestration --scope <scope>
claude plugin marketplace remove claude-orchestration
```

Then remove the `agent` key from `.claude/settings.json` or `.claude/settings.local.json` of the project. If the project has no `agent` key, Claude Code starts its default agent.

## Project profile

Add a `## dx-agents profile` section to the `CLAUDE.md` file at the root of the project. If the project has no `CLAUDE.md`, make it, or run `/init` in a session to make one. The section holds the values that the plugin reads. If the section or a key is missing, the plugin uses the default.

```md
## dx-agents profile

- Language: ASD-STE100
- Acceptance check: `make check`
  - Checks: Build, Lint, Test
- Independent review areas: concurrency, security, file formats
- Commit scopes: api, cli, docs
- Main branch: main
```

| Key | Used by | Default |
| :--- | :--- | :--- |
| `Language` | All agents. `ASD-STE100` or `free`. | `ASD-STE100` |
| `Acceptance check` | The workers that change code and `dx-agents:runner`. The exact command, skill or tool, and the list of checks. | None. A worker stops and reports it. The architect asks you |
| `Independent review areas` | The architect and `dx-agents:reviewer`. | None |
| `Commit scopes` | The architect, for commit messages, if the project has no commit procedure of its own. | None |
| `Main branch` | The architect, for worktrees and merges. | `main` |

The values above are an example. Use the values of your project.

## Project settings

The plugin needs no permissions in the project. Apart from the install, the only setting is the `agent` key that turns on the architect. The hooks block the agent types that the workflow does not use, and the `git` commands that change the repository state when a worker runs them.

The permissions of Claude Code still apply. For fewer permission prompts, allow the commands that the agents run often, for example the command of `Acceptance check`. Add them to `permissions.allow` in `.claude/settings.json` of the project (for all the people) or in `.claude/settings.local.json` (for you only). For example, for `make check` and read-only `git` commands:

```json
{
  "permissions": {
    "allow": [
      "Bash(make check)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)"
    ]
  }
}
```

On Windows, a command that runs in PowerShell needs its own rule, for example `"PowerShell(make check)"`. To see and change the rules in a session, run `/permissions`. The [permissions docs](https://code.claude.com/docs/en/permissions) give the rule syntax.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) to set up a clone, run the acceptance check (`scripts/check.sh`) and send a pull request. Report security problems as [SECURITY.md](SECURITY.md) tells you.

## Layout

```text
.claude-plugin/
  plugin.json          the plugin manifest
  marketplace.json     the marketplace with this one plugin
  icon.png             the plugin icon
RULES.md               shared rules
agents/                the architect and 6 worker agents
hooks/                 hooks.json and the three hook scripts
scripts/check.sh       the acceptance check
tests/hooks.sh         the hook tests
```

## Version

The project follows [Semantic Versioning](https://semver.org/). Each release has a tag `v<version>` and a GitHub release with the changes. Claude Code updates an installed plugin only when `version` in `.claude-plugin/plugin.json` changes. release-please sets this value from the Conventional Commits. See [CONTRIBUTING.md](CONTRIBUTING.md#release).

## License

[MIT](LICENSE).
