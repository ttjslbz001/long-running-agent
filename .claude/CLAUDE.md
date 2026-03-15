# Long-Running Agent Plugin

This project uses a **two-agent pattern** for long-running development across multiple sessions.

## Agents

| Agent | When to Use | How to Invoke |
|---|---|---|
| **Initializer** | ONCE at project start — sets up plan, progress tracking, environment | Type: `Use the initializer agent to set up this project` |
| **Coder** | Every subsequent session — implements one task at a time | Type: `Use the coder agent to make progress on this project` |

> **Note:** `/agents` is a management command (view/edit/delete). To **run** an agent, type a natural language request in the chat. Or use CLI: `claude --agent initializer "your prompt"`

## Key Files

| File | Purpose | Managed By |
|---|---|---|
| `task_plan.md` | Task checkboxes and progress status (source of truth) | progress-tracker skill |
| `notes.md` | Design decisions, session logs, error traces | progress-tracker skill |
| `docs/plans/*.md` | Detailed implementation plan (read-only after creation) | initializer agent |
| `init.sh` | Idempotent dev environment setup (run every session) | initializer agent |

## Rules

1. **One task at a time** — never implement multiple features simultaneously
2. **Always commit** after completing a task
3. **Always update progress** — mark `[x]` in task_plan.md, log in notes.md
4. **Fix bugs first** — repair broken state before new features
5. **Never delete tasks** — only change checkbox state in task_plan.md
6. **Re-read task_plan.md** before major decisions — keeps goals in attention window
7. **Leave clean state** — codebase must be mergeable at session end

## Workflow

```
First time:  "Use the initializer agent to..."  →  brainstorm → plan → setup → commit
Every time:  "Use the coder agent to..."        →  orient → implement → verify → commit → repeat

CLI alternative:
  claude --agent initializer "set up this project based on spec.md"
  claude --agent coder "implement the next feature"
```

## Dependencies

This plugin requires these skills to be installed globally:

- **Superpowers** — brainstorming, writing-plans, TDD, verification, finishing-branch
- **Planning with Files** — task_plan.md / notes.md management pattern
- **Ralph-plan** (optional) — for structuring iterative ralph-loop commands
