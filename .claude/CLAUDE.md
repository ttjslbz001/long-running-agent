# Long-Running Agent Scaffold

A portable, project-agnostic harness for multi-session AI coding agents.

## Agents

| Agent | When | Invoke |
|---|---|---|
| **initializer** | ONCE per project — scans codebase, generates adapter + state | `Use the initializer agent to set up this project` |
| **coder** | Every session — plans features OR implements tasks | `Use the coder agent to [your goal]` |
| **gardener** | Periodically — cleans drift, updates quality score | `Use the gardener agent to clean up` |
| **learner** | After human corrections — extracts patterns, updates long-term memory | `Use the learner agent to learn from recent feedback` |

## Lifecycle

```
init (once)    →  scans project → generates adapter.md, state.json, init.sh
coder (plan)   →  user gives goal → brainstorm → approve → task_plan.json
coder (build)  →  orient → implement → observe → reflect → commit → repeat
learner (loop) →  analyzes human corrections → updates preferences, anti-patterns, adapter
```

## Key Files

| File | Format | Purpose |
|---|---|---|
| `state.json` | JSON | Machine-readable project state (single-file session context) |
| `task_plan.json` | JSON | Structured feature/task list with pass/fail status |
| `notes.md` | Markdown | Human-readable session logs, decisions, errors |
| `init.sh` | Shell | Idempotent dev environment setup |
| `domain/adapter.md` | Markdown | Project-specific build/test/deploy/verify recipes |
| `domain/knowledge/` | Markdown | Domain docs discovered or created during work |
| `domain/knowledge/preferences.md` | Markdown | Human style/taste preferences (learner agent) |
| `domain/knowledge/anti-patterns.md` | Markdown | Things agents must avoid (learner agent) |

## Rules

1. **One task at a time** — never implement multiple features simultaneously
2. **Always commit** after completing a task
3. **Always update state** — state.json, task_plan.json, notes.md
4. **Fix broken state first** — repair before new features
5. **Never delete tasks** — only change status in task_plan.json
6. **Observe after deploy** — run the verify protocol from adapter.md
7. **Reflect after every task** — run harness/session-reflect.md
8. **Leave clean state** — codebase must be mergeable at session end

## File Map

```
.claude/
├── CLAUDE.md                  ← you are here
├── agents/
│   ├── initializer.md         scan project → generate scaffold
│   ├── coder.md               orient → implement → observe → reflect → commit
│   ├── gardener.md            periodic quality maintenance
│   └── learner.md             human feedback → long-term memory
├── harness/
│   ├── session-start.md       generic startup protocol
│   ├── session-reflect.md     post-task reflection protocol
│   ├── session-observe.md     post-deploy verification protocol
│   └── progress-tracker.md    state.json + task_plan.json management
├── domain/
│   ├── adapter.md             ★ THE PLUGGABLE PART — project-specific recipes
│   └── knowledge/             domain docs (auto-populated)
├── templates/
│   ├── state.json             template for machine-readable state
│   ├── task_plan.json         template for structured feature list
│   └── adapter-example.md     example adapter for reference
└── docs/
    ├── decisions/             ADRs from reflection loop
    └── evidence/              verification artifacts
```
