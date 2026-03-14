# Long-Running Agent Plugin — Design Document

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** A reusable Claude Code plugin that gives any project long-running agent capabilities via two orchestrating Subagents + two custom Skills, delegating to existing Superpowers / Planning-with-Files / Ralph-plan skills.

**Architecture:** Hybrid — custom Subagents own orchestration logic, existing skills do the heavy lifting.

**Dependencies:** Superpowers plugin, Planning with Files skill, Ralph-plan skill (all assumed installed).

---

## 1. Overall Architecture

```mermaid
graph TB
    subgraph Project["User's Project"]
        CLAUDE_MD[".claude/CLAUDE.md<br/>(project conventions)"]

        subgraph Agents["Subagents (this plugin)"]
            INIT["initializer.md<br/>(run ONCE)"]
            CODER["coder.md<br/>(run EVERY session)"]
        end

        subgraph CustomSkills["Custom Skills (this plugin)"]
            SS["session-start/SKILL.md"]
            PT["progress-tracker/SKILL.md"]
        end

        subgraph Files["Files on Disk (working memory)"]
            TP["task_plan.md"]
            NOTES["notes.md"]
            PLAN["docs/plans/YYYY-MM-DD-*.md"]
            INITSH["init.sh"]
        end
    end

    subgraph Existing["Pre-installed Skills (NOT part of plugin)"]
        subgraph SP["Superpowers"]
            BRAIN["brainstorming"]
            WP["writing-plans"]
            EP["executing-plans"]
            SDD["subagent-driven-dev"]
            TDD["TDD"]
            VERIF["verification"]
            FINISH["finishing-branch"]
        end
        PWF["planning-with-files"]
        RP["ralph-plan"]
    end

    INIT -->|delegates design| BRAIN
    INIT -->|delegates planning| WP
    INIT -->|delegates file setup| PWF
    CODER --> SS
    CODER -->|delegates implementation| TDD
    CODER -->|delegates verification| VERIF
    CODER --> PT
    CODER -->|delegates completion| FINISH
    SS -->|reads| TP
    SS -->|reads| NOTES
    PT -->|updates| TP
    PT -->|appends| NOTES
    PWF -->|manages| TP
    PWF -->|manages| NOTES
    WP -->|generates| PLAN

    style INIT fill:#4a9eff,color:#fff
    style CODER fill:#4a9eff,color:#fff
    style SS fill:#ff9f43,color:#fff
    style PT fill:#ff9f43,color:#fff
    style BRAIN fill:#a29bfe,color:#fff
    style WP fill:#a29bfe,color:#fff
    style EP fill:#a29bfe,color:#fff
    style SDD fill:#a29bfe,color:#fff
    style TDD fill:#a29bfe,color:#fff
    style VERIF fill:#a29bfe,color:#fff
    style FINISH fill:#a29bfe,color:#fff
    style PWF fill:#55efc4,color:#333
    style RP fill:#55efc4,color:#333
    style TP fill:#ffeaa7,color:#333
    style NOTES fill:#ffeaa7,color:#333
    style PLAN fill:#ffeaa7,color:#333
    style INITSH fill:#ffeaa7,color:#333
```

---

## 2. Initializer Agent Flow (run ONCE per project)

```mermaid
flowchart TD
    START(["User: /agents initializer"])
    
    EXPLORE["1. Explore Project Context<br/>Read files, docs, READMEs, package.json"]
    
    BRAINSTORM["2. Brainstorming<br/>Ask user questions one-at-a-time<br/>Propose 2-3 approaches<br/>Get user approval on design"]
    BRAINSTORM_SKILL["superpowers:brainstorming"]
    
    WRITEPLAN["3. Write Implementation Plan<br/>Bite-sized tasks (2-5 min each)<br/>TDD: test → fail → implement → pass → commit<br/>Exact file paths, commands, expected output"]
    WRITEPLAN_SKILL["superpowers:writing-plans"]
    PLAN_OUT[("docs/plans/<br/>YYYY-MM-DD-*.md")]
    
    SETUPFILES["4. Setup Planning Files<br/>Create task_plan.md (phases + checkboxes)<br/>Create notes.md (decisions, constraints)"]
    PWF_SKILL["planning-with-files"]
    FILES_OUT[("task_plan.md<br/>notes.md")]
    
    INITSH["5. Create init.sh<br/>Install dependencies<br/>Start dev server<br/>Basic smoke test<br/>(idempotent)"]
    
    GITINIT["6. Git Init + Commit<br/>git add -A<br/>git commit -m 'chore: initialize project<br/>with plan and progress tracking'"]
    
    REPORT["7. Report Summary<br/>Total tasks by phase<br/>Recommended first task<br/>How to start: /agents coder"]

    START --> EXPLORE
    EXPLORE --> BRAINSTORM
    BRAINSTORM -.->|delegates to| BRAINSTORM_SKILL
    BRAINSTORM --> WRITEPLAN
    WRITEPLAN -.->|delegates to| WRITEPLAN_SKILL
    WRITEPLAN --> PLAN_OUT
    WRITEPLAN --> SETUPFILES
    SETUPFILES -.->|delegates to| PWF_SKILL
    SETUPFILES --> FILES_OUT
    SETUPFILES --> INITSH
    INITSH --> GITINIT
    GITINIT --> REPORT

    style START fill:#4a9eff,color:#fff
    style BRAINSTORM_SKILL fill:#a29bfe,color:#fff
    style WRITEPLAN_SKILL fill:#a29bfe,color:#fff
    style PWF_SKILL fill:#55efc4,color:#333
    style PLAN_OUT fill:#ffeaa7,color:#333
    style FILES_OUT fill:#ffeaa7,color:#333
    style REPORT fill:#00b894,color:#fff
```

---

## 3. Coder Agent Flow (run EVERY session)

```mermaid
flowchart TD
    START(["User: /agents coder"])

    subgraph A["A. Session Start (custom skill)"]
        A1["Read task_plan.md"]
        A2["Read notes.md"]
        A3["git log --oneline -20"]
        A4["Run init.sh"]
        A5["Smoke test<br/>(broken? fix first!)"]
        A6["Pick next unchecked task"]
        A7["Announce: I will now implement [task]"]
        A1 --> A2 --> A3 --> A4 --> A5 --> A6 --> A7
    end

    subgraph B["B. Implement One Task (TDD)"]
        B1["Write failing test"]
        B2["Run test → FAIL"]
        B3["Write minimal code"]
        B4["Run test → PASS"]
        B5["Refactor if needed"]
        B1 --> B2 --> B3 --> B4 --> B5
    end

    subgraph C["C. Verify"]
        C1["Run full test suite"]
        C2["E2E / manual check"]
        C3["Evidence before claims"]
        C1 --> C2 --> C3
    end

    subgraph D["D. Commit & Track (custom skill)"]
        D1["git commit -m '...'"]
        D2["Mark [x] in task_plan.md"]
        D3["Log entry in notes.md"]
        D1 --> D2 --> D3
    end

    MORE{{"E. More tasks?"}}
    HAS_CONTEXT{"Context budget<br/>remains?"}

    subgraph F["F. Finish"]
        F1["Final verification"]
        F2["Update task_plan.md<br/>ALL COMPLETE"]
        F3["Present options:<br/>merge / PR / cleanup"]
        F1 --> F2 --> F3
    end

    START --> A
    A --> B
    B -.->|"superpowers:TDD"| B
    B --> C
    C -.->|"superpowers:verification"| C
    C --> D
    D --> MORE
    MORE -->|"YES — tasks remain"| HAS_CONTEXT
    HAS_CONTEXT -->|"YES"| A
    HAS_CONTEXT -->|"NO — save & stop"| STOP(["End session<br/>(resume next time)"])
    MORE -->|"NO — all done!"| F
    F -.->|"superpowers:finishing-branch"| F

    style START fill:#4a9eff,color:#fff
    style A fill:#ff9f431a,stroke:#ff9f43
    style B fill:#a29bfe1a,stroke:#a29bfe
    style C fill:#a29bfe1a,stroke:#a29bfe
    style D fill:#ff9f431a,stroke:#ff9f43
    style F fill:#00b8941a,stroke:#00b894
    style STOP fill:#636e72,color:#fff
```

---

## 4. File Lifecycle Across Sessions

```mermaid
graph LR
    subgraph T0["Project Start<br/>(Initializer)"]
        TP0["task_plan.md<br/>- [ ] Task 1<br/>- [ ] Task 2<br/>- [ ] Task 3<br/>- [ ] Task 4<br/><b>Status: Initialized</b>"]
        N0["notes.md<br/>Decisions:<br/>- Architecture: X<br/>- Tech stack: Y"]
    end

    subgraph T1["Session 1<br/>(Coder)"]
        TP1["task_plan.md<br/>- [x] Task 1 ✓<br/>- [x] Task 2 ✓<br/>- [ ] Task 3<br/>- [ ] Task 4<br/><b>Status: Phase 2</b>"]
        N1["notes.md<br/>Decisions:<br/>- Architecture: X<br/>Session 1 Log:<br/>- Completed Task 1<br/>- Completed Task 2"]
    end

    subgraph TN["Session N<br/>(Coder)"]
        TPN["task_plan.md<br/>- [x] Task 1 ✓<br/>- [x] Task 2 ✓<br/>- [x] Task 3 ✓<br/>- [x] Task 4 ✓<br/><b>ALL COMPLETE</b>"]
        NN["notes.md<br/>Decisions:<br/>- Architecture: X<br/>Session N Log:<br/>- Completed Task 4<br/>- ALL COMPLETE"]
    end

    PLAN["docs/plans/*.md<br/>(read-only blueprint,<br/>never modified)"]
    INITSH["init.sh<br/>(run every session)"]

    TP0 -->|"coder reads & updates"| TP1
    TP1 -->|"..."| TPN
    N0 -->|"coder appends"| N1
    N1 -->|"..."| NN
    PLAN -.->|"read by coder"| T1
    PLAN -.->|"read by coder"| TN
    INITSH -.->|"run by coder"| T1
    INITSH -.->|"run by coder"| TN

    style TP0 fill:#ffeaa7,color:#333
    style TP1 fill:#ffeaa7,color:#333
    style TPN fill:#ffeaa7,color:#333
    style N0 fill:#dfe6e9,color:#333
    style N1 fill:#dfe6e9,color:#333
    style NN fill:#dfe6e9,color:#333
    style PLAN fill:#a29bfe,color:#fff
    style INITSH fill:#74b9ff,color:#333
```

---

## 5. Skill Delegation Map

```mermaid
flowchart LR
    subgraph InitAgent["Initializer Agent"]
        I2["Step 2: Design"]
        I3["Step 3: Plan"]
        I4["Step 4: Files"]
    end

    subgraph CoderAgent["Coder Agent"]
        CA["Step A: Orient"]
        CB["Step B: Implement"]
        CC["Step C: Verify"]
        CD["Step D: Track"]
        CF["Step F: Finish"]
    end

    subgraph ExistingSkills["Existing Skills"]
        BRAIN["superpowers:brainstorming"]
        WP["superpowers:writing-plans"]
        PWF["planning-with-files"]
        TDD_S["superpowers:TDD"]
        VERIF_S["superpowers:verification"]
        FINISH_S["superpowers:finishing-branch"]
    end

    subgraph CustomSkills["Custom Skills (this plugin)"]
        SS_S["session-start"]
        PT_S["progress-tracker"]
    end

    I2 --> BRAIN
    I3 --> WP
    I4 --> PWF
    CA --> SS_S
    CB --> TDD_S
    CC --> VERIF_S
    CD --> PT_S
    CF --> FINISH_S
    SS_S -->|reads| PWF
    PT_S -->|updates| PWF

    style InitAgent fill:#4a9eff1a,stroke:#4a9eff
    style CoderAgent fill:#4a9eff1a,stroke:#4a9eff
    style ExistingSkills fill:#a29bfe1a,stroke:#a29bfe
    style CustomSkills fill:#ff9f431a,stroke:#ff9f43
```

---

## 6. Plugin Deliverables

| File | Type | Purpose |
|---|---|---|
| `.claude/agents/initializer.md` | Subagent | First-run orchestration |
| `.claude/agents/coder.md` | Subagent | Per-session coding loop |
| `.claude/skills/session-start/SKILL.md` | Skill | Session orientation |
| `.claude/skills/progress-tracker/SKILL.md` | Skill | Progress management |
| `.claude/CLAUDE.md` | Config | Project conventions |
| `README.md` | Docs | Installation & usage guide |

---

## 7. User Journey

```mermaid
flowchart TD
    INSTALL["<b>INSTALL</b><br/>Copy plugin files into .claude/<br/>(Superpowers, planning-with-files,<br/>ralph-plan already installed globally)"]

    FIRST["<b>FIRST RUN</b><br/>User: /agents initializer<br/>User: Build a [description]"]
    FIRST_STEPS["Brainstorming Q&A → Design approval<br/>→ Plan generated → Files created<br/>→ Git initialized"]

    EVERY["<b>EVERY SUBSEQUENT SESSION</b><br/>User: /agents coder"]
    EVERY_STEPS["Orient → Pick task → TDD implement<br/>→ Commit + update progress<br/>→ Repeat until context limit"]

    COMPLETE["<b>COMPLETION</b><br/>All tasks checked<br/>→ finishing-branch skill<br/>→ Merge / PR options"]

    INSTALL --> FIRST
    FIRST --> FIRST_STEPS
    FIRST_STEPS --> EVERY
    EVERY --> EVERY_STEPS
    EVERY_STEPS -->|"next session"| EVERY
    EVERY_STEPS -->|"all tasks done"| COMPLETE

    style INSTALL fill:#636e72,color:#fff
    style FIRST fill:#4a9eff,color:#fff
    style FIRST_STEPS fill:#4a9eff22,stroke:#4a9eff
    style EVERY fill:#ff9f43,color:#fff
    style EVERY_STEPS fill:#ff9f4322,stroke:#ff9f43
    style COMPLETE fill:#00b894,color:#fff
```
