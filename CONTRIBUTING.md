# Contributing to claude-orchestration

Thank you for your help. This file tells you how to set up the project, how to make a change and how to send it.

By contributing, you agree to obey the [Code of Conduct](CODE_OF_CONDUCT.md).

## Report a problem or an idea

- Bug: open an issue with the **Bug report** form.
- Idea: open an issue with the **Feature request** form.
- Security problem: do not open an issue. Read [SECURITY.md](SECURITY.md).

## Set up

You need the tools of the [README requirements](README.md#requirements) (Claude Code, `git`, `bash` and `jq`) and [ShellCheck](https://www.shellcheck.net/), which lints the shell scripts.

Install ShellCheck:

```sh
brew install shellcheck              # macOS
sudo apt install shellcheck          # Debian and Ubuntu
sudo dnf install ShellCheck          # Fedora and RHEL
sudo pacman -S shellcheck            # Arch
winget install --id koalaman.shellcheck -e   # Windows, in PowerShell
```

Check it with `shellcheck --version`. On Windows, run the scripts of this repository in Git Bash.

Load your clone for one session, with the architect as the main agent:

```sh
claude --plugin-dir /path/to/claude-orchestration --agent dx-agents:architect
```

Or add the clone as a directory marketplace. Claude Code then loads the plugin in place, and `/reload-plugins` loads your edits. The directory marketplace has the same name as the GitHub one, so first remove the GitHub one (`claude plugin marketplace remove claude-orchestration`) if you added it:

```sh
claude plugin marketplace add /path/to/claude-orchestration
claude plugin install dx-agents@claude-orchestration
```

Then turn on the architect in the project where you test, as the README tells you.

## Check a change

Run the acceptance check before you send a change:

```sh
scripts/check.sh
```

It runs three checks. CI runs the same checks on macOS, Linux and Windows. All checks must pass.

- **Validate**: `claude plugin validate --strict .`
- **Lint**: ShellCheck on all shell scripts.
- **Hook tests**: `tests/hooks.sh`. Add a test case for each change to a hook.

For a change to an agent or to `RULES.md`, also test it in a real Claude Code session. Say in the pull request what you tested.

## Write a change

- Make the smallest complete change. Do not refactor unrelated text or code.
- Keep the plugin generic. It must work in projects of any language, with their own skills, MCP tools and language servers.
- Keep the plugin working on macOS, Linux and Windows. The hooks run in `bash` 3.2 or later, and in Git Bash on Windows. Remove the `\r` from the output of `jq`, because jq on Windows ends lines with CRLF.
- When a doc names a tool, a setting or an environment variable, tell how to install or set it on each system.
- Write docs, agent files and comments in [ASD-STE100](https://www.asd-ste100.org/) Simplified Technical English: short sentences, active voice, one instruction in each sentence.
- Do not rename a published agent or the plugin without a major reason. A rename breaks the installs and the settings of the users.

For a small fix, open a pull request directly. For a new feature or a change to the workflow, open an issue first, so we can agree on it before you write it.

## Commit

Use [Conventional Commits](https://www.conventionalcommits.org/). The commit type sets the next version through release-please, so use the correct type.

```text
<type>(<scope>): <summary>
```

| Type | Use for | Version change |
| :--- | :--- | :--- |
| `feat` | A new feature | MINOR |
| `fix` | A bug fix | PATCH |
| `perf` | A performance change | PATCH |
| `refactor`, `test`, `docs`, `build`, `ci`, `style`, `chore` | Other changes | None |
| `revert` | A revert of an earlier commit | PATCH |

The project follows [Semantic Versioning](https://semver.org/). Before `1.0.0`, an incompatible change increases MINOR. From `1.0.0`, it increases MAJOR.

- Scopes: `agents`, `hooks`, `rules`, `marketplace`, `docs`, `ci`.
- The summary is imperative and lowercase, with no period. The header has a maximum of 72 characters.
- Add `!` after the type, or a `BREAKING CHANGE:` footer, for an incompatible change. Examples: a renamed agent, a removed profile key, a hook that blocks more calls.
- Make one commit for each logical change.

## Send a pull request

1. Fork the repository and make a branch from `main`.
2. Make your commits. Rebase on `main` to update your branch. Do not merge `main` into your branch.
3. Open a pull request and complete the checklist.
4. A maintainer reviews it. The project accepts only rebase merges, so the history stays linear.

## Release

release-please keeps a release pull request open with the next version and `CHANGELOG.md`. It also updates `version` in `.claude-plugin/plugin.json`. When a maintainer merges the release pull request, release-please creates the tag `v<version>` and the GitHub release. Do not change `version` by hand.

## License

Your contribution is published under the [MIT License](LICENSE).
