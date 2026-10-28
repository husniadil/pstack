# husniadil/pstack

A fork of [cursor/plugins](https://github.com/cursor/plugins) that keeps only pstack and rewrites it for Claude Code. Upstream writes pstack for Cursor and ships a Claude Code copy that maps Cursor names at runtime through an adapter document. This fork edits the text itself, so Claude Code reads Claude Code names directly.

## Install

```
/plugin marketplace add husniadil/pstack
/plugin install pstack@pstack
```

`pstack/.claude-plugin/plugin.json` sets no `version`, so Claude Code versions the plugin by commit SHA and every push to `main` is an update.

## Layout

- `pstack/` is the plugin. Upstream's file paths are kept and only file contents change, so upstream diffs keep applying with few conflicts.
- `.claude-plugin/marketplace.json` lists pstack alone, from `./pstack`.
- `pstack/.claude-plugin/plugin.json` is the fork's manifest. `pstack/plugin.json` is upstream's and merges as is.
- These paths are removed, and every sync removes them again: everything upstream has outside `pstack/`, `pstack/automations/` (Cursor Automations only), `pstack/skills/setup-pstack/`, `pstack/docs/harness/`, and `pstack/.cursor-plugin/`.
- `.fork/` holds the sync and check scripts.

## Porting rules

Apply these to every file under `pstack/skills`, `pstack/agents`, `pstack/docs`, and `pstack/README.md`.

### Keep the diff small

- Change only the words that name a Cursor tool, field, path, model, or product feature. Keep every other word, the line breaks, the headings, and the paragraph order as upstream wrote them. Rewrite a whole sentence only when a word swap leaves it wrong.
- Never add, rename, or move files. Delete a line only when its whole content is Cursor-only.
- Match upstream's voice: short declarative sentences, no long dash, no colon as a mid-sentence connector. The README is lowercase like upstream's.

### Tools and subagent fields

| Cursor | Claude Code |
| --- | --- |
| `Task` (tool, call, spawn) | `Agent` |
| `AskQuestion` | `AskUserQuestion`. In `-p` mode it is absent, so ask in plain text. |
| Open a todolist | `TodoWrite` |
| `subagent_type: generalPurpose` | `subagent_type: "general-purpose"` |
| `poteto-agent`, `comment-sicko` as a `subagent_type` | `"pstack:poteto-agent"`, `"pstack:comment-sicko"` |
| `readonly: true` | `subagent_type: "Explore"`, and the brief says "do not edit files". Check `git status` afterward. |
| `readonly: false` | `subagent_type: "general-purpose"` |
| `environment: "cloud"` | `isolation: "worktree"`. Name the branch or commit the worker checks out. |
| `environment: "local"`, `run_in_background: true` | Drop. Claude Code runs subagents in the background by default. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `resume` an agent | `SendMessage` with the agent's ID or name. Explore and Plan agents cannot be resumed, so spawn a fresh agent with the earlier result in its brief. |
| Fork a worker to reuse its built state (its checkout, uncommitted changes, or a running process) | Spawn a fresh worker in that worker's worktree. Put the worktree path in the brief and omit `isolation`, so it works on the same checkout and uncommitted changes. The `Agent` tool forks only the calling agent, so a fork would carry the coordinator's context and checkout. |
| `file_attachments` | List the paths in the brief. |
| `is_background: true` (agent frontmatter) | `background: true` |

### Models

There is no per-role model rule and no `setup-pstack` skill. Each role uses a fixed default.

| Upstream default | Claude Code |
| --- | --- |
| `claude-opus-5-5-<effort>` | `model: "opus"`, `effort: "<effort>"` |
| `grok-*`, `auto`, `inherit-parent`, any non-Claude slug | Omit `model`, so the agent runs on the parent session model. Keep the `effort`. |
| A `-fast` suffix or "fast mode" for a subagent | Drop. Subagents have no fast mode. |
| A panel list such as `claude-opus-5-5-xhigh, grok-4.7-xhigh-fast` | One agent with `model: "opus"` and one with `model` omitted, both at the listed effort. |
| "configurable via `/setup-pstack`", "the role's line", "per-role lines in the rule override", `pstack-models.mdc` | Remove. State the fixed default instead. |

The `Agent` tool takes `model` values `opus`, `sonnet`, `haiku`, and `fable`, and `effort` values `low`, `medium`, `high`, `xhigh`, and `max`.

### Skills, paths, and links

| Cursor | Claude Code |
| --- | --- |
| "In Claude Code, read the Claude Code adapter ..." line | Remove it. If the skill runs another pstack skill, put this line in its place: "To run another pstack skill, read `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md` and follow it." |
| Run another pstack skill (`/name` or "the **name** skill") | Read `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md` and follow it. pstack skills set `disable-model-invocation`, so the `Skill` tool refuses them. |
| A slash command the user is told to type, in prose or a code block | `/pstack:<name>`. A bare `/name` that only names the skill stays as upstream wrote it. |
| A relative link to another skill, such as `[...](../<name>/SKILL.md)` | Keep it as upstream wrote it. Claude Code gives a skill its base directory, so the link resolves from there. When the sentence tells the agent to run that skill, the row on running another pstack skill applies instead. |
| An absolute path to a skill, to pass to a subagent | `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md`. Claude Code substitutes the absolute path when it loads the skill or agent. |
| `.cursor/skills/`, `~/.cursor/skills/` | `.claude/skills/`, `~/.claude/skills/` |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | `${CLAUDE_PLUGIN_ROOT}`, `.claude-plugin/plugin.json` |
| `.cursor/rules/*.mdc`, an always-applied rule | `CLAUDE.md` |
| `https://github.com/cursor/plugins/blob/main/pstack/<path>` | A relative link in `docs/` and `README.md`, `${CLAUDE_PLUGIN_ROOT}/<path>` in skills and agents |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.claude/projects/<slug>/<session>.jsonl`. The slug is the workspace path with each `/` and `.` changed to `-`. The newest `.jsonl` there is the current session, and `<session>/subagents/` holds its subagent transcripts. |
| The agent's store, "path in the system prompt" | `~/.claude/pstack/`. Claude Code gives an agent no store of its own. |
| The Project tracker (`notes.md`) and the Project store | `~/.claude/pstack/orchestrate/<project-slug>/notes.md` for the tracker, and the rest of that directory for the store. `<project-slug>` is the program's name in kebab-case. Both outlast a restart, which `TodoWrite` does not. |
| A Cursor chat, Cursor restart, Cursor window | A Claude Code session, restart, terminal |
| Cursor Plan mode | Claude Code plan mode |

### Cursor-only features

| Cursor | Claude Code |
| --- | --- |
| Cursor Automations (routines, `update_state`, `api2.cursor.sh` webhooks, routine wakes, `SendToUser`) | A Claude Code routine through `/schedule` when a step needs work on a schedule, `/loop` for a recurring check inside a session. Remove a step that only makes sense inside Cursor Automations. |
| Cursor cloud agents | A worktree subagent (`isolation: "worktree"`). Remove a step that needs the cloud agent's dashboard or machine. |
| Bugbot | Keep. It is a GitHub app, and its comments are ordinary review threads. Remove a step that starts or configures Bugbot. |
| A built-in PR tool, Origin | `gh` |
| `deslop` from `cursor-team-kit` | `/simplify` |
| `control-cli`, `control-ui` from `cursor-team-kit` | `/run` to launch and drive the app, and Claude in Chrome for a browser UI when the session has it |
| Cursor's built-in `create-skill` or `babysit` skill | Remove the mention, or point at pstack's `playbooks/authoring-a-skill.md` or `playbooks/babysit.md`. |
| Grok Bot | A Claude Code routine with an API trigger |

## Syncing upstream

The routine on the agamemnon VM runs this daily. Do it the same way by hand.

1. Run `.fork/sync.sh`. It fetches, merges `upstream/main` without committing, removes the dropped paths, keeps this fork's marketplace, and prints the conflicts left plus every `pstack/` file upstream changed. Exit code 3 means there is nothing new, so stop.
2. Resolve each conflict in `pstack/` by taking upstream's new text and applying the porting rules to it. Port the cleanly merged files it printed too, since new upstream text arrives with Cursor names.
3. Run `.fork/check.sh` until it prints no Cursor names.
4. Run `claude plugin validate pstack` and `claude plugin validate .`. When the merge touched `pstack/skills/poteto-mode/scripts/`, run `bun install && bun test` there.
5. Commit with `git commit --no-edit` and push to `origin main`.
6. If a conflict needs a judgment the rules do not settle, run `git merge --abort`, push nothing, and report the files and the question.
