# Long-Running Agent Plugin for Claude Code

A reusable plugin that gives any project **long-running agent capabilities** — work across multiple Claude Code sessions without losing context or progress.

Based on Anthropic's [Effective Harnesses for Long-Running Agents](https://docs.anthropic.com) pattern, implemented using Claude Code's native Subagent + Skills system.

## What It Does

| Problem | Solution |
|---|---|
| Agent tries to build everything at once | **Initializer** breaks work into bite-sized tasks |
| New session doesn't know what happened before | **session-start** skill reads progress files + git log |
| Progress gets lost between sessions | **progress-tracker** skill maintains task_plan.md + notes.md |
| Agent skips testing and declares done | **Coder** enforces TDD + verification before marking complete |

## Prerequisites

Install these globally (they are NOT bundled with this plugin):

1. **[Superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, verification
2. **[Planning with Files](https://github.com/OthmanAdi/planning-with-files)** — Manus-style persistent markdown planning
3. **[Ralph-plan](https://lobehub.com/skills/belumume-claude-skills-ralph-loop)** (optional) — iterative command builder

## Installation

Copy the plugin files into your project:

```bash
# From this repo's root
cp -r .claude/ /path/to/your-project/.claude/
```

Or manually copy these files into your project's `.claude/` directory:

```
.claude/
├── agents/
│   ├── initializer.md
│   └── coder.md
├── skills/
│   ├── session-start/
│   │   └── SKILL.md
│   └── progress-tracker/
│       └── SKILL.md
└── CLAUDE.md
```

## Usage

> **Important:** `/agents` is a management command (view/edit/delete). To **run** an agent, type a natural language request in the chat. Subagents are loaded at session start — restart Claude Code after installation.

### First Time (Project Setup)

Open Claude Code in your project directory and type:

```
Use the initializer agent to set up this project: Build a REST API with
user authentication, CRUD operations for blog posts, and a React frontend
with dark mode support.
```

Or from the CLI:

```bash
claude --agent initializer "Set up this project based on spec.md"
```

The initializer will:
1. **Brainstorm** the design with you (Q&A, 2-3 approaches, your approval)
2. **Generate** a detailed implementation plan with bite-sized tasks
3. **Create** `task_plan.md`, `notes.md`, and `init.sh`
4. **Commit** everything to git

### Every Subsequent Session

```
Use the coder agent to make progress on this project
```

Or from the CLI:

```bash
claude --agent coder "Implement the next feature"
```

The coder will:
1. **Orient** itself (read progress, check git, start dev environment)
2. **Pick** the next unchecked task
3. **Implement** with TDD (test → fail → code → pass → refactor)
4. **Verify** the task works (full test suite, evidence)
5. **Commit** and update progress files
6. **Repeat** until context limit or all tasks done

### Checking Progress

At any time, you can ask Claude to run the progress-tracker skill:

```
Show me the current project status
```

## Architecture

```
Initializer Agent ──► brainstorming ──► writing-plans ──► planning-with-files
     (run once)         (design)         (plan tasks)      (setup files)

Coder Agent ──► session-start ──► TDD ──► verification ──► progress-tracker
 (every session)  (orient)      (build)    (verify)          (track)
```

## File Reference

| File | Created By | Updated By | Purpose |
|---|---|---|---|
| `task_plan.md` | Initializer | Coder (each task) | Checkboxes + status |
| `notes.md` | Initializer | Coder (each task) | Decisions + session logs |
| `docs/plans/*.md` | Initializer | Never (read-only) | Detailed task blueprint |
| `init.sh` | Initializer | Never (idempotent) | Dev environment setup |

## License

MIT
