# Post-Task Reflection Protocol

Run this protocol after EVERY task — whether it succeeded or failed. Reflection outputs are **artifacts**, not transient reasoning. They persist across sessions.

## Step 1: Outcome Assessment

Answer these questions explicitly (write the answers in notes.md):

- **Did the task succeed?** (yes / no / partial)
- **If failed: what was the root cause?**
  - Code bug
  - Environment issue (wrong account, expired creds, missing dep)
  - Missing context (adapter.md was incomplete or wrong)
  - Wrong approach (the plan was flawed)
  - External dependency (API down, flaky test, rate limit)
- **How many attempts did it take?**
- **Was the acceptance criteria met?** (from task_plan.json)

## Step 2: Pattern Recognition

Read the last 5 entries in `notes.md`. Ask:

- Is this failure/difficulty **similar** to a previous one?
- Have I hit this same error type before?
- Is this the **second time** I've had to do something that should be automated?

If you detect a recurring pattern → proceed to Step 3.
If this is a one-off → skip to Step 4.

## Step 3: Create a Guard (only if recurring pattern found)

Recurring problems should become permanent knowledge, not repeated mistakes.

Choose the appropriate guard type:

| Pattern Type | Guard | Where |
|---|---|---|
| Common error with known fix | Add to "Known Gotchas" in `domain/adapter.md` | adapter.md |
| Architectural decision | Write an ADR | `docs/decisions/YYYY-MM-DD-<topic>.md` |
| Missing test coverage | Write a regression test | project test directory |
| Manual step that should be automated | Add to init.sh or create a script | project root |
| Domain knowledge gap | Document it | `domain/knowledge/` |

ADR format:
```markdown
# [Decision Title]

## Date
YYYY-MM-DD

## Context
[What prompted this decision]

## Decision
[What we decided and why]

## Consequences
[What this means for future work]

## Status
active
```

## Step 4: Knowledge Capture

Ask: did I learn something NEW about this project that future sessions need?

- **New domain knowledge** → update `domain/knowledge/`
- **Adapter was wrong or incomplete** → fix `domain/adapter.md`
- **New gotcha discovered** → add to adapter's "Known Gotchas"
- **Convention changed** → update adapter's "Conventions" section
- **Nothing new** → that's fine, skip

## Step 5: Plan Check

Ask: does the remaining plan still make sense?

- Is the next task still the right priority?
- Did this task reveal new work that should be added?
- Should any pending task be reordered or blocked?

If the plan needs adjustment:
1. Update `task_plan.json` (add/reorder tasks, change status to "blocked")
2. Log the reason in `notes.md` with `[PLAN ADJUSTED]` prefix

## Step 6: Update State

Update `state.json`:

```json
{
  "last_session": {
    "timestamp": "<now>",
    "agent": "coder",
    "task_completed": "<task description>",
    "status": "<success|failed|partial>",
    "verification": {
      "local_tests": "<pass|fail|skipped>",
      "deployed": "<pass|fail|skipped|n/a>"
    },
    "reflection": {
      "recurring_pattern": <true|false>,
      "guard_created": "<guard description or null>",
      "knowledge_updated": <true|false>
    },
    "next_task": "<next pending task from plan>"
  }
}
```

## Rules

- ALWAYS run this protocol, even for trivial tasks
- Reflection outputs go into FILES, not just your reasoning
- If you created a guard, it must be committed alongside the code change
- Never skip Step 2 (pattern recognition) — this is how the harness learns
- Be honest about failures — false "success" poisons future sessions
