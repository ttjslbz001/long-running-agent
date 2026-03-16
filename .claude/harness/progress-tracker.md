# Progress Tracker

Manages `state.json`, `task_plan.json`, and `notes.md`. These three files are the project's memory across sessions.

## File Roles

| File | Format | Reader | Purpose |
|---|---|---|---|
| `state.json` | JSON | Agent (fast path) | Current project state, last session summary, quality metrics |
| `task_plan.json` | JSON | Agent | Structured task list with status per task |
| `notes.md` | Markdown | Human + Agent | Timestamped log of decisions, errors, learnings |

## Operations

### "status" — Show current progress

1. Read `state.json` for quick summary
2. Read `task_plan.json` for task breakdown
3. Count by status: pending, in_progress, completed, blocked
4. Report: **"Progress: X/Y tasks complete (Z%). Next: [task]"**

### "update" — Mark a task complete

Prerequisites: task was verified (tests pass, deploy verified if applicable).

1. In `task_plan.json`: change task status from `"in_progress"` to `"completed"`
2. In `state.json`: increment `tasks.completed`, update `last_session`
3. In `notes.md`: append timestamped entry:

```markdown
### [YYYY-MM-DD HH:MM] Completed: [task description]
- What was done: [brief summary]
- Files changed: [list]
- Tests: [pass/fail]
```

### "start" — Begin a task

1. In `task_plan.json`: change task status from `"pending"` to `"in_progress"`
2. In `state.json`: increment `tasks.in_progress`

### "block" — Mark a task as blocked

1. In `task_plan.json`: change task status to `"blocked"`, add `"blocked_reason"`
2. In `state.json`: increment `tasks.blocked`
3. In `notes.md`: log why it's blocked

### "add" — Add a new task

1. In `task_plan.json`: append new task with next available ID, status `"pending"`
2. In `state.json`: increment `tasks.total`
3. In `notes.md`: log why the task was added (discovered during implementation, etc.)

### "log" — Record a finding

1. In `notes.md`: append timestamped entry:

```markdown
### [YYYY-MM-DD HH:MM] Note: [message]
- [details]
```

2. If the message describes an error, ALSO add to `known_issues` in `state.json`

### "reorder" — Change task priority

1. In `task_plan.json`: change the order of tasks (by moving the task object)
2. In `notes.md`: log why with `[PLAN ADJUSTED]` prefix

## Rules

- NEVER change a task's status to `"completed"` without verification
- NEVER delete tasks — only change status or add new ones
- NEVER edit task descriptions after creation — add clarifications as new fields
- ALWAYS include timestamps in notes.md entries
- ALWAYS keep state.json counts in sync with task_plan.json actual statuses
- JSON files must remain valid JSON at all times
