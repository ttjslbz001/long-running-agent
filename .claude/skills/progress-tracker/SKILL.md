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
