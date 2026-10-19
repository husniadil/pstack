# Set up pstack

In this page you install the plugin, learn which models pstack uses, and run your first task. Setup is two commands.

## Install the plugin

In a Claude Code session, run:

```text
/plugin marketplace add husniadil/pstack
/plugin install pstack@pstack
```

Claude Code confirms the plugin is installed. It prefixes plugin skills, so you type `/poteto-mode` as `/pstack:poteto-mode`.

## Know the default models

There is nothing to configure. Each role has a fixed default. Code delegates omit the subagent `model` field, so they run on your parent session model. The hardest changes, prose, and judgment use `model: "opus"`. A review panel runs one subagent on Opus and one on your session model, so the panel stays diverse.

The defaults run at `xhigh` reasoning. For the hardest work the agent raises the subagent `effort` one step, up to `max`, and for routine work it lowers it.

Every `/swarm` worker also runs on your session model unless a race names a model for each arm.

## Generate verification skills, or don't

pstack works best with a way to prove app behavior in your project, either a `verify-*` skill or an existing harness. If you have neither, generate one with [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md).

It writes `.claude/skills/verify-<app>/`, a project-local skill that teaches agents to drive your app the way a user does. It proves the skill works once before handing it over. You can run `/pstack:create-verification-skill` any time. [Verify and ship](./06-verify-and-ship.md#create-a-project-verification-skill) covers it in depth.

If you're new to pstack, run it. An agent that can check its own work keeps going until the check passes. An agent that can't hands every result back to you to check by hand. Of everything in this guide, the verification skill pays off the most.

Then you can generate a formal verification skill with [`/create-formal-verification-skill`](../../skills/create-formal-verification-skill/SKILL.md), unless the project already has one. Tests check the cases someone thought to write. A formal verification skill checks one key property of your code, such as "a job never runs twice at once", in every case within a stated scope. Run it when your code has concurrency, retries, a state machine, or a parser, where a bug is costly and tests rarely reach the case that breaks. Otherwise skip it, and run it later if that changes. [Verify and ship](./06-verify-and-ship.md#prove-a-property-with-a-formal-verification-skill) covers it.

## Keep the cost in check

pstack spends extra tokens on subagents and review panels. That's the price of the rigor. To spend fewer:

- Run the session on a cheaper model. Code delegates run on the session model, so they get cheaper too.
- Shorten a panel list. Each entry runs one subagent.
- Save `/poteto-mode` for work that needs rigor. A small, obvious edit doesn't.

## Run your first task

Pick something real but small, and describe it the way you'd describe it to a colleague:

```text
/pstack:poteto-mode add a --json flag to this command. text output stays byte-identical. verify both.
```

Watch the todo list. Its first items are the matched playbook's steps copied in, the Feature playbook for this prompt. If `/poteto-mode` skips a step, the step stays in the list with `skip: <reason>`, so you can see what it chose not to do.

From here you can type normal follow-ups. Typing a skill attaches it to one message, and it fades as the chat moves on. To keep `/poteto-mode` on, start each new task with `/pstack:poteto-mode`.

Next: [Route work through `/poteto-mode`](./02-poteto-mode.md).
