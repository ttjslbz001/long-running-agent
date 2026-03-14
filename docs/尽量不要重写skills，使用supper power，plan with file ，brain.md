<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# 尽量不要重写skills，使用supper power，plan with file ，brain storming ，ralph-loop来满足需求

可以，在你已有的技能体系里，用 **Superpowers + Planning with Files + Brainstorming + Ralph-loop** 基本就能实现那篇文章里的长时运行 harness，不必自己重写一大堆 SKILL。下面直接给你一个「最小改造方案」，偏实战配置思路。

***

## 总体思路：把论文里的 4 个核心能力映射到现有技能

长时运行 harness 需要 4 个关键能力：[^1][^2]


| Harness 能力 | 推荐现成技能 |
| :-- | :-- |
| 项目拆解 + 设计阶段 | **Superpowers:brainstorm** + Brainstorming skill[^3][^4] |
| 生成结构化实现计划（feature list / phases） | **Superpowers:write-plan** 或 `:execute-plan` 里的 plan 文件[^3] |
| 把上下文记忆写到文件，跨多 session 延续 | **Planning with Files**，用 `task_plan.md / progress.md / findings.md` 等[^1][^5] |
| 自动循环执行小步迭代，直到完成 | **Ralph-loop skill / plugin**，基于 git 和 `.claude/ralph-loop.local.md` 迭代[^2][^6] |

所以改造策略是：

- 「Initializer Agent」阶段 → 用 **brainstorm + plan-with-files** 做一次性项目拆解，把 feature 列表、策略写入 markdown；
- 「Coding Agent」阶段 → 用 **Ralph-loop** 驱动循环，每轮迭代都先读 plan-with-files 的 plan/progress 文件，再小步推进。

不再自己定义一堆 SKILL.md，只是把这些技能的「调用顺序和用法」固化在一个 Subagent 的 prompt + 文件约定里。

***

## 步骤 1：安装 / 启用这些技能

1. **Superpowers 插件 / 技能**
    - 按官方 Superpowers 安装说明，把 plugin 安装到 Claude（一般是插件市场或 GitHub 仓库里有一步安装脚本）。[^7][^8][^9][^10]
    - 确保在 Claude Code 里能看到 `/superpowers:brainstorm`、`/superpowers:write-plan`、`/superpowers:execute-plan` 这几个命令。[^3][^8]
2. **Planning with Files**（推荐用 plugin 版而不是裸 skill）
    - GitHub `planning-with-files` 仓库里有 `.claude-plugin/` 和 `planning-with-files/SKILL.md`，按 README 的「Claude 插件」安装步骤来。[^5]
    - 安装后通常会有 `/planning-with-files:start` 和 `/planning-with-files:plan` 之类命令，并在当前项目创建 `task_plan.md / findings.md / progress.md` 等文件。[^1][^5]
3. **Brainstorming skill**
    - 如果你用的是 MCP Market 的「Brainstorming Claude Code Skill」或类似版本，按指引安装到 `.claude/skills/` 或插件目录。[^4][^11]
    - 常见用法是 `/brainstorm` 或 `/brainstorming:design` 之类，它会生成 3–5 套技术方案 + 风险/工作量矩阵。[^11][^4]
4. **Ralph-loop skill / 插件**
    - 按 LobeHub 或 skill 市场说明安装 `ralph-loop`，它依赖 git 仓库 + `.claude/ralph-loop.local.md` 做状态记录。[^2][^6]
    - 常见入口是 `/ralph-loop "task"`，会在每一轮读取状态文件并继续迭代，直到满足完成条件（比如 TODO.md 里的 ALL_TASKS_COMPLETE 标记）。[^6][^2]

***

## 步骤 2：用现成技能实现「Initializer 阶段」

不写自定义 SKILL，而是把「初始化流程」写在 Subagent / CLAUDE.md 里，引导它调用这些现有技能。

你可以新建一个 **Initializer 子代理**（或者简单点直接在主 CLAUDE.md 里写指令），大概逻辑：

> 1. 用 `/superpowers:brainstorm` + Brainstorming skill 把需求从「idea」变成「技术方案 + 模块划分」。[^12][^3][^4]
> 2. 用 `/superpowers:write-plan` 生成详细实现计划：阶段、里程碑、粗粒度 feature 列表、测试策略等，落盘成一个 `implementation_plan.md` 或类似文件。[^13][^3]
> 3. 调用 `/planning-with-files:start` 把这个计划拆到 `task_plan.md / progress.md / findings.md` 等规划文件中，成为规范的持久「工作内存」。[^5][^1]
> 4. 初始化 git 仓库，把上述计划和初始 scaffold 提交一次（可以直接让 Claude 用 Bash 工具做）。

实际使用时，你可以在 Claude 会话里给个 meta 指令，比如：

```text
对当前项目执行「初始化阶段」：

1. 使用 /superpowers:brainstorm 和 Brainstorming skill，把这个产品想法展开成系统架构、模块、关键技术选型。
2. 用 /superpowers:write-plan 生成一份 implementation_plan.md，包含：
   - 分阶段 roadmap
   - 每阶段的功能列表（粒度以「几小时内可完成」为单位）
   - 每个功能的验收标准（测试思路）
3. 用 /planning-with-files:start 启动规划，把计划内容同步进 task_plan.md、progress.md、findings.md 等文件。
4. 建立 git 仓库，提交一次「chore: initialize plan and scaffold」。
```

这样「feature_list.json + claude-progress.txt」的职责就由 `task_plan.md + progress.md` 这些 Planning with Files 的标准文件替代了。[^1][^5]

***

## 步骤 3：用 Planning with Files 替代手写 progress harness

「Effective harnesses」里最关键的是把上下文记忆写到磁盘并有结构化的进度记录。
`planning-with-files` 已经实现了这一套 Manus-style 规范：[^5][^1]

- `task_plan.md`：任务树、checkbox、阶段分解[^1][^5]
- `progress.md`：每个 session 的日志、完成度、失败记录[^5][^1]
- `findings.md`：研究结论、决策理由、踩坑记录[^1][^5]

你只需要在 Claude 的提示里强调：

- 「任何关键决策都要写入 `task_plan.md` 或 `findings.md`」；
- 「每次 session 结束前必须更新 `progress.md`」。

Planning with Files 还自带 **PreToolUse / PostToolUse hooks**，在大操作前强制重新阅读 plan，并在写文件后提醒更新状态，这刚好对应了论文中的「强制自我对齐 + 避免重复犯错」的部分。[^5][^1]

***

## 步骤 4：用 Ralph-loop 实现「Coding Agent 循环」

论文里的 Coding Agent 本质是「读 progress → 选一个 feature → 实现 + 测试 → 更新进度 → 下一个」的循环。
Ralph-loop 已经帮你实现了「循环+状态」这层框架：[^2][^6]

- 状态持久化在 `.claude/ralph-loop.local.md`（记录是否 active、当前 iteration、max_iterations）；[^2]
- 依赖 git，确保每轮迭代都有 commit、可回滚；[^2]
- 可以配合 TODO.md / 计划文件控制停止条件。[^6][^2]

典型使用方式是：

```text
/ralph-loop "在当前项目中，按照 planning-with-files 生成的 task_plan.md，从最高优先级的未完成任务开始，一次实现一个任务。每一轮迭代必须：
1. 先阅读 task_plan.md 和 progress.md，确认下一项任务。
2. 实现这项任务所需的最小改动。
3. 运行必要的测试。
4. 更新 progress.md 和 task_plan.md 的勾选状态。
5. 提交 git commit，附带任务编号和简要说明。"
```

你可以在 `.claude/CLAUDE.md` 或某个 dev 文档里写死这段流程，让 Claude 每次进入 Ralph-loop 前都按照这个「微型 harness」执行。

如果希望完全自动化，不用每次手动输命令，可以参考 Reddit 上那种「让 Claude 自己触发 Ralph-loop 的 skill」思路：有人写了一个 Skill，让 Claude 能在需要时调用 `/ralph-loop "..."` 而不是你来敲命令。你可以直接复用那种技能，或者稍微改一下模板（仍然是基于现有 Ralph-loop 插件）。[^6]

***

## 步骤 5：把这一切封装进一个 Subagent，而不是新 Skill

你希望「尽量不重写 skills」，那就把「使用这些 skills 的方法」写进一个 Subagent 定义，而不是在 filesystem 里堆新的 SKILL.md。

示例思路（伪 frontmatter）：

```markdown
---
name: long-running-coder
description: Use Superpowers, Planning with Files, Brainstorming and Ralph-loop to implement features incrementally for long-running projects.
tools: Read, Write, Edit, Bash, Glob, Grep
# 不额外绑定 skills，这样只用插件里已有的 /superpowers, /planning-with-files, /ralph-loop
---

你是一个长时运行的编码 Agent，必须严格遵循以下流程：

# 初始化阶段（只在项目第一次配置时执行）
- 如果没有 task_plan.md、progress.md：
  1. 调用 /superpowers:brainstorm 以及 Brainstorming skill，将用户给出的 idea 展开为多种架构和实现选项，并选定一个。
  2. 调用 /superpowers:write-plan，生成 implementation_plan.md，包含分阶段任务列表和验收标准。
  3. 调用 /planning-with-files:start，把计划导入 task_plan.md / progress.md / findings.md。
  4. 初始化 git 仓库并进行首次提交。

# 每个工作 session
- 始终遵循：
  1. 使用 planning-with-files 提供的命令，重新阅读 task_plan.md、progress.md。
  2. 选择一个尚未完成且依赖满足的任务。
  3. 进入 Ralph-loop 或使用 /ralph-loop "…" 调用，让自己在迭代模式下实现该任务：
     - 每轮仅修改少量代码。
     - 每轮后运行测试。
     - 更新 progress.md，并为完成的任务打勾。
     - 提交 git commit。
  4. 当该任务完成并验证通过后，结束当前 Ralph-loop。
  5. 如果所有任务都已完成，则在计划文件中写入 ALL_TASKS_COMPLETE 并停止。
```

依赖点：

- 你不新造任何 skill，只是要求这个 Subagent「正确地使用 /superpowers, /planning-with-files, /ralph-loop 命令」；
- 状态持久化完全由 `planning-with-files` 和 `ralph-loop` 提供的文件/状态文件负责。[^2][^1][^5]

***

## 你可以直接这样用（操作建议）

在你现有项目里，大致按这个顺序试一把：

1. 安装上述四个技能 / 插件；
2. 在 `.claude/CLAUDE.md` 顶部写一小段说明，告诉 Claude「本项目的长时运行策略就是：Superpowers + Planning with Files + Ralph-loop」；
3. 开一个新 Claude Code 会话，在项目根目录，输入中文指令，比如：

```text
我要实现一个长时运行的开发 agent，不写自定义 SKILL。请：
1. 用 /superpowers:brainstorm 和 Brainstorming skill，把 spec.md 里的需求展开成可实现架构。
2. 用 /superpowers:write-plan 生成 implementation_plan.md。
3. 用 /planning-with-files:start 启动规划，把计划写入 task_plan.md、progress.md 等文件。
4. 然后配置 TODO.md 和 .claude/ralph-loop.local.md，使得 /ralph-loop 可以从 task_plan.md 和 TODO 列表驱动迭代，直到 ALL_TASKS_COMPLETE。
5. 接下来，我只需要调用 /ralph-loop \"完成整个实现\"，你就按这个流程不断迭代，直到任务完成。
```

4. 后续你只需要重复调用 `/ralph-loop "继续实现计划中的下一项任务"`，就相当于论文里的 Coding Agent 在一个 harness 中稳定推进。[^6][^2]

***

如果你愿意，我可以帮你针对「某个具体 repo」写一段完全可复制的中文「项目级指令块」，专门告诉 Claude 如何串联这四个技能来实现 feature-by-feature 的长期开发，而完全不新增 SKILL 文件。
<span style="display:none">[^14][^15]</span>

<div align="center">⁂</div>

[^1]: https://mcpmarket.com/tools/skills/planning-with-files-1

[^2]: https://lobehub.com/skills/belumume-claude-skills-ralph-loop

[^3]: https://www.trevorlasn.com/blog/superpowers-claude-code-skills

[^4]: https://mcpmarket.com/tools/skills/brainstorming-decision-making

[^5]: https://github.com/OthmanAdi/planning-with-files

[^6]: https://www.reddit.com/r/ClaudeAI/comments/1q6jgnl/skill_that_lets_claude_code_invoke_its_own/

[^7]: https://github.com/obra/superpowers

[^8]: https://www.youtube.com/watch?v=vfVQP2AbUHo

[^9]: https://blog.fsck.com/2025/10/09/superpowers/

[^10]: https://claude.com/plugins/superpowers

[^11]: https://mcpmarket.com/tools/skills/brainstorming-agent

[^12]: https://www.youtube.com/watch?v=901VMcZq8X4

[^13]: https://www.youtube.com/watch?v=98e8lpOtaWc

[^14]: https://www.reddit.com/r/ClaudeCode/comments/1r9y2ka/claude_codes_superpowers_plugin_actually_delivers/

[^15]: https://code.claude.com/docs/en/skills

