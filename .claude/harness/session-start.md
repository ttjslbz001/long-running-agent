# Session Startup Protocol

Follow these steps EXACTLY at the start of every coding session. Do NOT skip steps. Do NOT start implementing until all steps are done.

## Step 1: Orient

```bash
pwd
ls
```

## Step 2: Load Context (single-file fast path)

Read `state.json`. This gives you:
- Project name and tech stack
- What the last session did
- Whether it succeeded or failed
- What the next task should be
- Known issues and quality status

If `state.json` does not exist, STOP. Tell the user to run the initializer agent.

## Step 3: Deep Context (if needed)

Read these for full picture:
1. `task_plan.json` — all tasks with status
2. `notes.md` — recent decisions, errors, learnings
3. `git log --oneline -15` — recent commits
4. `.claude/domain/adapter.md` — build/test/deploy commands for this project

## Step 4: Check Progress

Count tasks in `task_plan.json`:
- Total tasks
- Completed
- Pending
- Blocked

Report: **"Progress: X/Y tasks complete (Z%)"**

If all tasks are completed, announce it and ask the user for next steps.

## Step 5: Health Check

1. Run `bash init.sh` if it exists
2. Run the build command from `domain/adapter.md`
3. Run the test command from `domain/adapter.md`

If any step fails:
- This is your FIRST priority — fix it before any new work
- Log the error in `notes.md` under the current timestamp
- Add to `known_issues` in `state.json` if it's a new issue

## Step 6: Choose Next Task

1. Check if `state.json` has a `last_session.next_task` recommendation
2. Otherwise, find the first `"pending"` task in `task_plan.json`
3. Read its full description and acceptance criteria
4. Announce: **"I will now implement: [task description]"**

## Rules

- NEVER skip the context load (Step 2)
- NEVER start coding before completing all 6 steps
- If the environment is broken, fix it FIRST
- Always re-read state.json — this refreshes goals in your attention window
- The adapter.md tells you HOW to work in this project — read it
