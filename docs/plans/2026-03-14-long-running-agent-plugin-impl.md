# Long-Running Agent Plugin — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a reusable Claude Code plugin (6 files) that gives any project long-running agent capabilities via two Subagents + two custom Skills.

**Architecture:** Hybrid orchestration — Subagents own the workflow, existing skills (Superpowers, Planning with Files) do the heavy lifting. See `docs/plans/2026-03-14-long-running-agent-plugin-design.md` for full design with Mermaid diagrams.

**Tech Stack:** Claude Code Subagents (`.claude/agents/*.md`), Claude Code Skills (`.claude/skills/*/SKILL.md`), Markdown, Bash.

---

### Task 1: Project scaffold and git init

**Files:**
- Create: `.claude/agents/` (directory)
- Create: `.claude/skills/session-start/` (directory)
- Create: `.claude/skills/progress-tracker/` (directory)

**Step 1: Create directory structure**

```bash
mkdir -p .claude/agents
mkdir -p .claude/skills/session-start
mkdir -p .claude/skills/progress-tracker
```

**Step 2: Initialize git**

```bash
git init
```

**Step 3: Create .gitignore**

Create `.gitignore`:

```
.DS_Store
*.swp
*~
```

**Step 4: Verify directories exist**

```bash
find .claude -type d | sort
```

Expected:
```
.claude
.claude/agents
.claude/skills
.claude/skills/progress-tracker
.claude/skills/session-start
```

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: scaffold plugin directory structure"
```

---

### Task 2: session-start Skill

This is the custom skill that fills a gap: no existing skill handles "orient yourself at session start." It follows the planning-with-files pattern (read before decide) and adds git/environment orientation.

**Files:**
- Create: `.claude/skills/session-start/SKILL.md`

**Step 1: Write the Skill file**

Create `.claude/skills/session-start/SKILL.md` with the following content:

```markdown
---
name: session-start
description: Start a new coding session by reviewing progress, checking environment health, and choosing the next task. Use at the beginning of every coding session.
allowed-tools: Read, Bash, Glob, Grep
---

# Session Startup Procedure

Follow these steps EXACTLY at the start of every coding session. Do NOT skip steps. Do NOT start implementing until all steps are done.

## Step 1: Orient yourself

Run `pwd` and `ls` to understand the project structure.

## Step 2: Review progress

1. Read `task_plan.md` — understand current phase, which tasks are done, which remain
2. Read `notes.md` — recall design decisions, constraints, errors encountered
3. Run `git log --oneline -20` — review recent commits to understand what the last session accomplished

If `task_plan.md` does not exist, STOP and tell the user to run the initializer agent first.

## Step 3: Check completion

Count checked `[x]` vs unchecked `[ ]` tasks in `task_plan.md`. Report: "Progress: X/Y tasks complete (Z%)"

If all tasks are checked, announce "All tasks complete!" and invoke the superpowers:finishing-a-development-branch skill. Do NOT continue to Step 4.

## Step 4: Start the dev environment

1. If `init.sh` exists, run `bash init.sh` to set up the environment
2. Wait for the dev server to be ready (if applicable)
3. Run a basic smoke test to verify the app is in a working state

If the smoke test fails, FIX the issue BEFORE moving to Step 5. Log the error in the "Errors Encountered" section of `task_plan.md`.

## Step 5: Choose next task

1. Find the first task in `task_plan.md` with `- [ ]` (unchecked)
2. Read the corresponding detailed task description from `docs/plans/*.md`
3. Announce: **"I will now implement: [task description]"**

## Rules

- NEVER skip the progress review (Step 2)
- NEVER start coding before completing all 5 steps
- If the environment is broken, fix it FIRST
- Always re-read task_plan.md — this refreshes goals in your attention window (Manus principle)
```

**Step 2: Verify the file**

```bash
head -5 .claude/skills/session-start/SKILL.md
```

Expected: should show the YAML frontmatter starting with `---`.

**Step 3: Verify frontmatter fields**

Check that `name`, `description`, and `allowed-tools` are present in the frontmatter.

```bash
grep -A4 "^---" .claude/skills/session-start/SKILL.md | head -5
```

Expected:
```
---
name: session-start
description: Start a new coding session by reviewing progress, checking environment health, and choosing the next task. Use at the beginning of every coding session.
allowed-tools: Read, Bash, Glob, Grep
---
```

**Step 4: Commit**

```bash
git add .claude/skills/session-start/SKILL.md
git commit -m "feat: add session-start skill for session orientation"
```

---

### Task 3: progress-tracker Skill

This is a thin wrapper around planning-with-files patterns, providing structured operations for progress management. It enforces append-only logging and never-delete-tasks discipline.

**Files:**
- Create: `.claude/skills/progress-tracker/SKILL.md`

**Step 1: Write the Skill file**

Create `.claude/skills/progress-tracker/SKILL.md` with the following content:

```markdown
---
name: progress-tracker
description: Track and report project progress by managing task_plan.md and notes.md. Use after completing a task, to check status, or to log findings. Supports commands - status, update, log.
allowed-tools: Read, Write, Edit, Bash
---

# Progress Tracker

Manage the project's `task_plan.md` and `notes.md` files following the planning-with-files pattern.

## Commands

When invoked, determine the mode from context or arguments:

### "status" — Show current progress

1. Read `task_plan.md`
2. Count checked `[x]` vs unchecked `[ ]` items
3. Calculate percentage complete
4. List the next 3-5 unchecked tasks
5. Show the current Status section

### "update [task description]" — Mark a task complete

1. Read `task_plan.md`
2. Find the matching `- [ ]` checkbox line
3. Change it to `- [x]` — ONLY if you have verified the task works
4. Update the `## Status` section with current phase
5. Append a timestamped entry to `notes.md`:

```
### [YYYY-MM-DD HH:MM] Completed: [task description]
- What was done: [brief summary]
- Files changed: [list]
- Tests: [pass/fail status]
```

6. Write back both files

### "log [message]" — Record a finding or decision

1. Append a timestamped entry to `notes.md`:

```
### [YYYY-MM-DD HH:MM] Note: [message]
- [details]
```

2. If the message describes an error, ALSO add it to the "Errors Encountered" section in `task_plan.md`

## Rules

- NEVER uncheck a completed task (no `[x]` → `[ ]`)
- NEVER delete tasks from task_plan.md
- NEVER edit task descriptions — only change checkbox state
- ONLY mark a task as complete after verifying it works
- ALWAYS include a timestamp in log entries
- ALWAYS update the Status section after marking a task complete
- Follow planning-with-files principle: update after every action
```

**Step 2: Verify the file**

```bash
head -5 .claude/skills/progress-tracker/SKILL.md
```

Expected: YAML frontmatter starting with `---`.

**Step 3: Verify frontmatter fields**

```bash
grep -A4 "^---" .claude/skills/progress-tracker/SKILL.md | head -5
```

Expected:
```
---
name: progress-tracker
description: Track and report project progress by managing task_plan.md and notes.md. Use after completing a task, to check status, or to log findings. Supports commands - status, update, log.
allowed-tools: Read, Write, Edit, Bash
---
```

**Step 4: Commit**

```bash
git add .claude/skills/progress-tracker/SKILL.md
git commit -m "feat: add progress-tracker skill for task management"
```

---

### Task 4: Initializer Agent (Subagent)

The Initializer Agent orchestrates the first-run setup. It delegates to Superpowers brainstorming, writing-plans, and planning-with-files. It explicitly declares the skills it needs in its frontmatter.

**Files:**
- Create: `.claude/agents/initializer.md`

**Step 1: Write the Subagent file**

Create `.claude/agents/initializer.md` with the following content:

```markdown
---
name: initializer
description: Initialize a new long-running project. Use ONLY for the first session of a new project. Sets up feature plan, progress tracking, and dev environment.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - progress-tracker
model: opus
memory: project
---

You are the **Initializer Agent** for a long-running coding project.

Your SOLE job is to set up the project so that the **Coder Agent** can work effectively across many sessions. You run ONCE, at the very beginning.

## Your Workflow

### Phase 1: Understand the Project

1. Read any existing files: README, spec, docs, package.json, etc.
2. Ask the user what they want to build if no spec is provided
3. Understand: purpose, constraints, target users, tech preferences

### Phase 2: Design (Brainstorming)

Use the **superpowers:brainstorming** approach:

1. Ask the user clarifying questions — ONE at a time
2. Propose 2-3 architectural approaches with trade-offs
3. Lead with your recommendation and explain why
4. Get user approval on the chosen design
5. Cover: architecture, components, data flow, error handling, testing strategy

### Phase 3: Write Implementation Plan

Use the **superpowers:writing-plans** approach:

1. Break the approved design into bite-sized tasks (each 2-5 minutes of work)
2. Each task follows TDD: write failing test → run → implement → run → commit
3. Include exact file paths, complete code snippets, exact commands
4. Order tasks by dependency (foundational first)
5. Save the plan to `docs/plans/YYYY-MM-DD-<project-name>.md`

### Phase 4: Setup Progress Tracking

Use the **planning-with-files** pattern:

1. Create `task_plan.md` at the project root with:
   - Goal (one sentence)
   - Phases with checkboxes (derived from the implementation plan)
   - Key Questions section
   - Decisions Made section (from brainstorming)
   - Errors Encountered section (empty)
   - Status section

2. Create `notes.md` at the project root with:
   - Design decisions from brainstorming
   - Tech stack rationale
   - Constraints and assumptions

### Phase 5: Environment Setup

1. Create `init.sh` — an idempotent script that:
   - Installs dependencies (npm install, pip install, etc.)
   - Starts the development server (if applicable)
   - Runs a basic smoke test to verify the app loads
   - Is safe to re-run (checks before acting)
2. Run `chmod +x init.sh`
3. Test-run `init.sh` to verify it works

### Phase 6: Initialize Git

1. `git init` (if not already a repo)
2. Create a sensible `.gitignore` for the project's tech stack
3. `git add -A`
4. `git commit -m "chore: initialize project with plan and progress tracking"`

### Phase 7: Report

Print a summary:
- Total tasks by phase
- Priority breakdown
- Recommended first task to implement
- Instruction: **"Run `/agents coder` to start implementing."**

## Critical Rules

- Follow the phases IN ORDER — do not skip brainstorming
- Get user approval on design BEFORE writing the plan
- Make tasks granular enough to complete in one context window
- The implementation plan is the source of truth — task_plan.md checkboxes mirror it
- Leave the project in a clean, ready-to-code state
- Save what you learned about this project to your agent memory

## What Success Looks Like

When you're done, verify:
1. `docs/plans/*.md` exists with a detailed implementation plan
2. `task_plan.md` exists with checkboxes for every task
3. `notes.md` exists with design decisions
4. `init.sh` exists, is executable, and runs successfully
5. A git commit has been made with all the above
6. The user knows exactly what to do next
```

**Step 2: Verify frontmatter**

```bash
head -10 .claude/agents/initializer.md
```

Expected: should show `---`, then `name: initializer`, `description`, `tools`, `skills`, `model`, `memory`, then `---`.

**Step 3: Verify skills reference**

```bash
grep "skills:" .claude/agents/initializer.md
```

Expected: `skills:` followed by `  - progress-tracker`.

**Step 4: Commit**

```bash
git add .claude/agents/initializer.md
git commit -m "feat: add initializer subagent for first-run project setup"
```

---

### Task 5: Coder Agent (Subagent)

The Coder Agent runs every session. It orients using session-start, implements one task at a time with TDD, tracks progress, and loops. It declares both custom skills in its frontmatter.

**Files:**
- Create: `.claude/agents/coder.md`

**Step 1: Write the Subagent file**

Create `.claude/agents/coder.md` with the following content:

```markdown
---
name: coder
description: Make incremental progress on the project by implementing features one at a time. Use for every coding session after initialization.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - session-start
  - progress-tracker
model: opus
memory: project
maxTurns: 100
---

You are the **Coder Agent** for a long-running project.

You make incremental progress by implementing one task at a time, testing it, committing, and updating progress. You may run across many sessions — each session picks up where the last left off.

## Session Workflow

### 1. Start: Orient Yourself

Run the **session-start** skill to:
- Review `task_plan.md` and `notes.md`
- Check recent git history
- Start the dev environment
- Smoke test the current state
- Choose the next task

### 2. Implement: One Task at a Time

For each task, follow **superpowers:test-driven-development**:

1. Read the detailed task description from `docs/plans/*.md`
2. Write a failing test
3. Run the test — confirm it FAILS
4. Write the minimal code to make it pass
5. Run the test — confirm it PASSES
6. Refactor if needed (keep tests green)

### 3. Verify: Confirm It Works

Before marking anything done, follow **superpowers:verification-before-completion**:

1. Run the full test suite — all tests must pass
2. Run a manual or E2E check if applicable
3. Evidence before claims — show the output

### 4. Commit: Save Your Work

```bash
git add -A
git commit -m "feat: [descriptive message about what was implemented]"
```

### 5. Update: Track Progress

Use the **progress-tracker** skill:
- Mark the completed task as `[x]` in `task_plan.md`
- Log a timestamped entry in `notes.md`
- Update the Status section

### 6. Repeat or Stop

- If more unchecked tasks remain AND context budget allows → go back to Step 1
- If context is running low → commit all work, update progress, and STOP cleanly
- If ALL tasks are checked → invoke **superpowers:finishing-a-development-branch**

## Critical Rules

- **ONE task at a time** — never try to implement multiple tasks in parallel
- **ALWAYS commit** after completing a task with a descriptive message
- **ALWAYS update progress** after each task (task_plan.md + notes.md)
- **NEVER mark a task complete** without thorough testing and verification
- **NEVER delete or modify** task descriptions in task_plan.md — only change checkbox state
- **Fix bugs first** — if you find a bug in existing code, fix and commit before new work
- **Leave clean state** — the codebase must be mergeable at the end of every session
- **Re-read task_plan.md** before every major decision (planning-with-files: attention refresh)
- **Log errors** — every failure goes in the Errors Encountered section of task_plan.md

## When Context is Running Low

If you sense you're approaching the context limit:

1. Finish or revert the current task (don't leave half-done work)
2. `git add -A && git commit -m "wip: [what you were working on]"`
3. Update `task_plan.md` Status section: "Stopped mid-session. Next: [task description]"
4. Update `notes.md` with what you learned this session
5. STOP — the next session will pick up cleanly

## Memory

- Check your agent memory at the start of each session for project-specific patterns
- Update your memory with new learnings before ending a session
- Track: naming conventions, common patterns, gotchas, test commands
```

**Step 2: Verify frontmatter**

```bash
head -12 .claude/agents/coder.md
```

Expected: frontmatter with `name: coder`, `skills:` listing `session-start` and `progress-tracker`, `maxTurns: 100`.

**Step 3: Verify skills references**

```bash
grep -A3 "skills:" .claude/agents/coder.md
```

Expected:
```
skills:
  - session-start
  - progress-tracker
```

**Step 4: Commit**

```bash
git add .claude/agents/coder.md
git commit -m "feat: add coder subagent for per-session incremental development"
```

---

### Task 6: CLAUDE.md (Project-level Configuration)

This is the project-level instruction file that Claude Code reads automatically. It explains the two-agent pattern, key files, and rules.

**Files:**
- Create: `.claude/CLAUDE.md`

**Step 1: Write CLAUDE.md**

Create `.claude/CLAUDE.md` with the following content:

```markdown
# Long-Running Agent Plugin

This project uses a **two-agent pattern** for long-running development across multiple sessions.

## Agents

| Agent | When to Use | Command |
|---|---|---|
| **Initializer** | ONCE at project start — sets up plan, progress tracking, environment | `/agents initializer` |
| **Coder** | Every subsequent session — implements one task at a time | `/agents coder` |

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
First time:  /agents initializer  →  brainstorm → plan → setup → commit
Every time:  /agents coder        →  orient → implement → verify → commit → repeat
```

## Dependencies

This plugin requires these skills to be installed globally:

- **Superpowers** — brainstorming, writing-plans, TDD, verification, finishing-branch
- **Planning with Files** — task_plan.md / notes.md management pattern
- **Ralph-plan** (optional) — for structuring iterative ralph-loop commands
```

**Step 2: Verify the file exists and has content**

```bash
wc -l .claude/CLAUDE.md
```

Expected: approximately 45-55 lines.

**Step 3: Commit**

```bash
git add .claude/CLAUDE.md
git commit -m "feat: add CLAUDE.md with project conventions and agent usage guide"
```

---

### Task 7: README.md

The user-facing documentation explaining what the plugin is, how to install it, and how to use it.

**Files:**
- Create: `README.md`

**Step 1: Write README.md**

Create `README.md` with the following content:

```markdown
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

### First Time (Project Setup)

Open Claude Code in your project directory and run:

```
/agents initializer
```

Then tell it what you want to build:

```
Build a REST API with user authentication, CRUD operations for blog posts,
and a React frontend with dark mode support.
```

The initializer will:
1. **Brainstorm** the design with you (Q&A, 2-3 approaches, your approval)
2. **Generate** a detailed implementation plan with bite-sized tasks
3. **Create** `task_plan.md`, `notes.md`, and `init.sh`
4. **Commit** everything to git

### Every Subsequent Session

```
/agents coder
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
```

**Step 2: Verify the README has all sections**

```bash
grep "^##" README.md
```

Expected:
```
## What It Does
## Prerequisites
## Installation
## Usage
## Architecture
## File Reference
## License
```

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and usage guide"
```

---

### Task 8: Final verification and cleanup

Verify the complete plugin is correct and self-consistent.

**Step 1: Verify all 6 deliverable files exist**

```bash
echo "=== Checking deliverables ==="
for f in \
  .claude/agents/initializer.md \
  .claude/agents/coder.md \
  .claude/skills/session-start/SKILL.md \
  .claude/skills/progress-tracker/SKILL.md \
  .claude/CLAUDE.md \
  README.md; do
  if [ -f "$f" ]; then
    echo "✓ $f"
  else
    echo "✗ MISSING: $f"
  fi
done
```

Expected: all 6 files show ✓.

**Step 2: Verify Subagent frontmatter references correct skills**

```bash
echo "=== initializer.md skills ==="
grep -A5 "^skills:" .claude/agents/initializer.md

echo "=== coder.md skills ==="
grep -A5 "^skills:" .claude/agents/coder.md
```

Expected:
- initializer: `progress-tracker`
- coder: `session-start`, `progress-tracker`

**Step 3: Verify Skill descriptions contain keywords for auto-matching**

```bash
echo "=== session-start description ==="
grep "^description:" .claude/skills/session-start/SKILL.md

echo "=== progress-tracker description ==="
grep "^description:" .claude/skills/progress-tracker/SKILL.md
```

Expected: descriptions contain natural-language keywords that Claude Code will match against.

**Step 4: Verify git log shows all commits**

```bash
git log --oneline
```

Expected: 7 commits (scaffold, session-start, progress-tracker, initializer, coder, CLAUDE.md, README).

**Step 5: Final commit (if any cleanup needed)**

If any fixes were made:

```bash
git add -A
git commit -m "chore: final verification and cleanup"
```

**Step 6: Report**

Print:
- Total files: 6 deliverables + design doc + implementation plan + .gitignore
- Plugin is ready to use
- Next step: copy `.claude/` into any project and run `/agents initializer`
