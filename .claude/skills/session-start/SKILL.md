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
