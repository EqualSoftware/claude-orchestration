# dx-agents rules

These are the shared rules of the `dx-agents` plugin. A hook of the plugin adds them to the context of each agent of the plugin. Each agent also obeys the `CLAUDE.md` of the project. A rule in the project `CLAUDE.md` wins over a rule in this file.

## Project profile

The project `CLAUDE.md` can have a section `## dx-agents profile`. It holds the values that the plugin reads. If the section or a key is missing, use the default.

| Key | Meaning | Default |
| :--- | :--- | :--- |
| `Language` | `ASD-STE100` or `free` | `ASD-STE100` |
| `Acceptance check` | The exact command, skill or tool, and the list of checks that it runs | None. A worker stops and reports it. The architect asks the user |
| `Independent review areas` | The areas of code that need an independent review | None |
| `Commit scopes` | Examples of scopes for commit messages | None |
| `Main branch` | The branch where work is integrated | `main` |

## Rules

### Language

- Use ASD-STE100 Simplified Technical English for docs, code, comments, identifiers, commit messages and agent communication. If the profile has `Language: free`, this rule does not apply.
- Write short sentences. Use the active voice. Write one instruction in each sentence.
- Do not apply ASD-STE100 to text that the end user reads: user interface text, story, dialogue, marketing text and other content of the product.
- If the project has a glossary, use its terms with their defined meaning.

### Commits

- Use Conventional Commits: `<type>(<scope>): <summary>`.
- If the project has a commit procedure (a skill, a command or an MCP tool), use it.
- Types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `build`, `ci`, `style`, `chore`, `revert`.
- Mark an incompatible change with `!` after the type, or with a `BREAKING CHANGE:` footer.
- Scope is the target or module. The profile can list examples.
- A worker agent that changes files in a worktree commits its changes on the worktree branch before it reports. In the main checkout, a worker does not commit. It reports the changed files.
- Only the main session pushes, and only when the user tells it to push. Stage files by name.

### Changes

- Follow the existing architecture, project conventions and constraints.
- Make the smallest complete change. Do not expand the scope. Do not do unrelated refactors.
- The code must obey the linters and formatters of the project.
- The build must have no errors and no warnings. Do not disable a warning to make the build pass.

Write code that is:

- **Simple.** Use the most direct solution. Do not add abstractions, layers or options that the task does not need.
- **Performant.** Do not add unnecessary allocations, network calls, I/O or work on the main thread.
- **Easy to delete.** Keep each feature in few places with few dependencies. A person must be able to remove it without changes to unrelated code.
- **Low in cyclomatic complexity.** Keep functions short. Use early returns. Avoid deep nesting and long `if`/`switch` chains.

### Acceptance check

Before a change is accepted, the acceptance check must pass. It is the `Acceptance check` of the profile: a command, a skill or a tool. The agent that makes the change or `dx-agents:runner` runs it. Each check in the profile list must pass.

To run the acceptance check:

1. Run the command, skill or tool of the profile without changes, in the worktree path if the brief gives one. If the profile has no command, stop and report it.
2. If the command cannot start (for example a missing tool or environment variable), stop and report the setup problem.
3. Get the changed files with `git status --short` and `git diff --name-only <main>...HEAD`, where `<main>` is the `Main branch` of the profile. A failure in a changed file, or in code that uses a changed file, is caused by the change and must be fixed. If the cause is not clear, compare with the result on `<main>`. A failure that also occurs on `<main>` existed before. Report it. Do not fix it unless the brief tells you to.
4. Report one line for each check of the profile: `<check>: PASS`, `FAIL` or `SKIPPED`, with its result line. List the platforms that you did not verify, if the change touches platform-specific code.

### Project tools

The project can give its own skills, commands and MCP tools. The agents of the plugin get all the tools of the session, except the tools that their file disallows.

- The procedures for planning, integration, publication and questions to the user belong to the main session. A worker agent does not run them.
- The brief can name the project tools that a worker must use.

### Code and file work

Each agent that reads, searches or changes code or files obeys this order. Use a generic tool only when no tool of a higher step applies.

1. **Project tools.** Use the skills, MCP tools and commands of the project, and the tools that the project installs: formatters, linters, code generators, refactor and migration tools, and the scripts of its build and task runner (for example `make`, `npm run`, `cargo`, `just`). Use them in the versions and with the configuration of the project. Do not install a new tool or use a global version when the project gives one.
2. **Generic tools.** Use `Read`, `Grep`, `Glob`, `Edit` and `Write` for the remaining work. Do not use `Bash` to read, search or edit files (`cat`, `sed`, `awk`, `echo >`) when a generic tool can do it.

- To find the available tools, read the project `CLAUDE.md`, the build and task runner files, and the list of tools of the session. Do this one time for each brief, not before each step.
- After you edit a file, run the formatter of the project on it, if one exists, before the acceptance check.
- If a project tool fails or gives a result that is not correct, use the next step and report the failure.

### Independent review

- If the diff touches an `Independent review areas` item of the profile, a fresh `dx-agents:reviewer` must review it. Start a new reviewer and give it only the diff and the objective.
- The author of such a change does not accept it.
- If the profile has no areas, the architect decides which changes are risky and tells the user.

### Agents

- The architect rules are in `agents/architect.md`.
- A worker agent does not start other agents.
- A subagent cannot ask the user. Plans and decisions with the user stay in the main session.
- `.claude/worktrees/` holds the worktrees of the architect. Exclude it when you search the repository.
