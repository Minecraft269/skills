---
name: universal-project-kickoff
description: >
  通用型项目启动与能力发现规则。合并了原 proactive-skill-discovery 的工具发现能力。
  当用户说以下任何话时，**必须**触发此技能：
  "我要开始一个新项目"、"帮我规划一个新功能"、"想启动一个 AI Agent"、
  "如何着手做 X"、"不知道从哪开始"、"帮我搭个架子"、"项目初始化"、
  "检查一下我的项目计划"、"帮我理一理思路"、"新项目怎么开始"、
  "打算搞个 side project"、"帮我做项目风险排查"、
  "有哪些可用的技能/插件"、"推荐什么工具"、"/discover"、
  "帮我审查代码"、"帮我修 Bug"、"我要开发一个新功能"。
  本技能先探测用户意图（启动项目/开发功能/审查代码/修复Bug/探索工具），
  再分流到对应子流程。启动新项目时执行六步强制流程（为什么-是什么-边界-风险-利益-里程碑-固化CLAUDE.md）
  + 代码风格确认 + 能力推荐，最后调用 /init 生成项目的 CLAUDE.md 将思考成果永久固化。
  其他意图则根据技术栈推荐匹配的技能和插件。
  即使用户没有明确说"启动检查"，只要涉及从零规划任何项目或需要工具推荐，就应触发。
version: "3.0.0"
risk: safe
source: community
capabilities: ["project-setup", "risk-assessment", "mvp-planning", "skill-discovery", "capability-scanning", "project-analysis"]
integrates_with: ["plugin-installation", "pr-management"]
metadata:
  category: meta
  tags: [project-startup, planning, checklist, mvp-definition, risk-assessment, init, code-style, discovery, recommendation, skills, plugins, commands]
  compatibility: 需要 /init 命令（Claude Code 内置），无其他外部依赖
---

# 通用型项目启动与能力发现

## 核心原则

**先开枪，后瞄准，但开枪前得知道靶子大概在哪个方向。**  
本技能帮助你在 15 分钟内完成启动前的关键决策，避免"热情直冲"带来的返工。同时，**全程保留项目的代码风格（包括注释、命名、格式等）** —— 这意味着在生成任何代码示例、项目结构或脚手架时，都要主动询问或推断用户既有的风格规范，并严格遵循。

本技能已合并原 `proactive-skill-discovery` 的工具发现能力。在开始前，会先探测你的意图——是启动新项目、开发功能、审查代码、修复 Bug 还是探索工具——然后推荐最匹配的技能和插件。

## 不触发条件

以下情况**不要**触发本技能：
- 用户已明确指定要使用的具体技能（如 `/github-pr-reviewer`）
- 对话仅为简单问答，不涉及项目开发任务
- 用户在当前会话中已明确表示不需要推荐或启动检查

## 参考文件

本技能附带六份参考文档，在技能执行过程中按以下规则加载：

- **`references/project-checklist.md`**：通用项目启动检查清单完整版。当用户对某一步骤要求更详细的解释、希望看到完整开工 Checklist 原文、或需要确认是否遗漏检查项时加载。
- **`references/ai-agent-checklist.md`**：AI Agent 项目专项检查清单。当用户确认项目类型为 AI Agent、询问 Agent 特有的风险或注意事项、或需要设计 Agent 的"大脑"架构时加载。
- **`references/scanner-patterns.md`**：项目指纹检测矩阵、评分算法公式、插件映射表和命令发现参考。执行技术栈确认和能力匹配时参考。
- **`references/language-guide.md`**：编程语言优劣势参考表。当用户不确定用什么语言时加载。
- **`references/hook-config.md`**：可选的 Claude Code hook 配置指南。当用户希望在新会话启动或检测到新项目时自动触发本技能，参考此文档配置 SessionStart/PostToolUse hook。
- **`references/validation-scenarios.md`**：验证场景集合。执行完技能后进行 LLM 自检时参考，确保推荐结果与预期一致。覆盖 8 种典型项目类型和 7 种边界情况。

## 包联动

本技能支持与 minecraft269-skills 插件包内其他技能自动联动。执行以下检测：

1. Glob 搜索 `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. 若找到 → `PACKAGE_MODE = true`，可发现并联动兄弟技能
3. 若未找到 → `PACKAGE_MODE = false`，跳过所有跨技能逻辑（静默降级）

当 `PACKAGE_MODE = true` 时：
- 识别项目技术栈后可联动 `integrates_with: plugin-installation`（快速安装插件）
- CLAUDE.md 生成后可提示用户运行能力扫描（本技能已内置，无需跨技能联动）
- 扫描兄弟 SKILL.md 的 `capabilities` 字段，匹配本技能的 `integrates_with` 标签
- 仅在匹配成功时显示联动提示

详见 `_shared/package-context.md`。**任何检测失败都默认 PACKAGE_MODE = false，不得报错或中断。**

---

## 使用流程

### Step 0：意图探测

**先推断，后询问。** 从用户的原始消息中提取关键词预判意图，只有无法确定时才弹出 `AskUserQuestion`。

#### 0.1 意图预判（关键词匹配）

从用户消息中匹配以下模式（大小写不敏感）：

| 关键词组合 | 推断意图 | 直接分流 |
|-----------|---------|---------|
| "启动" / "开始" / "新建" / "创建" / "初始化" / "搭个" / "从零" **+** "项目" | 🚀 启动新项目 | → Step 0b 语言确认 → 强制六步流程 |
| "开发" / "添加" / "实现" / "做" **+** "功能" / "feature" | 💻 开发新功能 | → Step 0c 技术栈确认 + 能力推荐 |
| "审查" / "review" / "检查" **+** "代码" / "PR" / "pull request" | 🔍 审查代码 | → Step 0a 目标确认 |
| "修复" / "修" / "改" / "fix" / "debug" **+** "bug" / "问题" / "报错" | 🐛 修复 Bug | → Step 0a 目标确认 |
| "有什么" / "推荐" / "哪些" / "可用" / "discover" **+** "技能" / "插件" / "工具" / "能力" | 🔧 探索工具 | → Step 0c 完整能力扫描 |

**匹配规则：**
- 若匹配到**唯一意图** → 直接分流，跳过 AskUserQuestion，在分流前用一句话确认（如"识别到你想要[意图]，直接开始…"）
- 若**多个意图匹配**或**无匹配** → 使用 `AskUserQuestion` 询问

#### 0.2 交互式询问（仅在意图不明确时使用）

> "你想要做什么？"

| 选项 | 说明 | 后续分流 |
|------|------|---------|
| 🚀 **启动新项目** | 从零开始一个项目 | → 追问语言/框架 → Step 0b 语言确认 → 进入强制六步流程 |
| 💻 **开发新功能** | 在现有项目中添加功能 | → 进入 Step 0c 技术栈确认 + 能力推荐 |
| 🔍 **审查代码** | Review PR 或代码变更 | → Step 0a 目标确认 → Step 0c 技术栈确认 + 审查工具推荐 |
| 🐛 **修复 Bug** | 排查和修复问题 | → Step 0a 目标确认 → Step 0c 技术栈确认 + 调试工具推荐 |
| 🔧 **探索工具** | 看看有什么可用的技能/插件/命令 | → 进入 Step 0c 完整能力扫描 |
| 📋 **其他** | 用户自由输入 | → 根据输入内容智能匹配分流 |

#### Step 0a：目标确认（仅「审查代码」/「修复 Bug」时执行）

##### 审查代码分支（4 层追问）

「审查代码」意图需要先确认审查目标和方式，再决定是否执行技术栈扫描。

**第 1 层 — 询问审查场景：**

使用 `AskUserQuestion`：
> "你要审查的是什么？"

| 选项 | 说明 |
|------|------|
| 📁 **本地项目** | 审查当前工作区的代码变更（unstaged / 分支 diff / 最近 commit） |
| ☁️ **远程 PR** | 审查 GitHub 上的 Pull Request |

**第 2 层（仅远程 PR）— 询问目标 PR：**

> "请提供 PR URL（如 `https://github.com/owner/repo/pull/123`）或 `owner/repo#number`"

解析 PR URL → 提取 `owner`、`repo`、`pr_number`。

**第 3 层（仅远程 PR）— 询问审查方式：**

使用 `AskUserQuestion`：
> "你想怎么审查这个 PR？"

| 选项 | 说明 | 后续 |
|------|------|------|
| ⚡ **在线快速审查** | 直接通过 GitHub MCP 获取 PR diff/files/commits，在线审查，无需 clone | → 使用 `gh pr view/diff` 或 GitHub MCP 工具获取 PR 内容 → 审查完成后输出结论 → **不执行 Step 0c** |
| 💻 **Clone 到本地详细审查** | clone 仓库到本地，执行完整技术栈扫描 + 深度审查 | → 对比本地 git remote：`git remote get-url origin 2>/dev/null \|\| echo "NOT_A_GIT_REPO"` → 不匹配则引导 clone（`gh repo clone owner/repo` 或 `git clone`）→ 执行 Step 0c |

**第 4 层（仅本地项目）— 确认审查范围：**

> "审查当前工作区的哪些变更？"

| 选项 | 说明 |
|------|------|
| 📝 **Unstaged 变更** | 工作区中尚未 staged 的修改 |
| 🌿 **分支对比** | 当前分支 vs 目标分支（如 `main`）的 diff |
| 📦 **最近 commit** | 审查最近 N 个 commit 的变更 |

确认范围后 → 进入第 5 层。

**第 5 层（所有审查路径）— 审查模型确认：**

在开始审查前，确认使用的 AI 模型。不同模型在审查深度、速度和成本上有差异。

1. **获取当前默认模型**：从会话上下文中读取当前模型名称（如系统提示中的 model 信息）
2. **展示并确认**：
   > "当前默认审查模型为 **[模型名称]**。是否使用此模型进行审查？"

   | 选项 | 说明 |
   |------|------|
   | ✅ **使用当前模型** | 直接使用默认模型开始审查 |
   | 🔄 **更换模型** | 让用户指定其他模型 |

3. **更换模型时**：
   > "请输入你想使用的模型名称（如 `sonnet`、`opus`、`haiku`、`fable`，或具体模型 ID）"
   - 用户输入后记录到审查上下文，后续 Agent 调用时使用该模型

4. **进入审查** → 执行 Step 0c 技术栈扫描 → 推荐技能时优先匹配 `pr-review`、`code-review` 能力。

##### 修复 Bug 分支

「修复 Bug」意图需要先确认目标项目。

**1. 追问目标：**

使用 `AskUserQuestion` 询问：
> "你要在哪个项目中修 Bug？是当前工作区的项目，还是其他项目？"

**2. 检查本地状态：**

- 从用户提供的项目信息对比当前工作区的 git remote
- 若目标项目不在本地 → 引导 clone
- Clone 完成后切换到目标项目目录

**3. 进入 Step 0c：**

- 在正确的项目目录中执行技术栈扫描
- 推荐技能时优先匹配调试工具 + 通用代码分析技能

#### Step 0b：语言/框架确认（仅「启动新项目」时追问）

> "你想用什么编程语言/框架？"

| 选项 | 说明 |
|------|------|
| 🟢 **Python** | AI/ML、数据分析、Web 后端、脚本自动化 |
| 🟡 **JavaScript/TypeScript** | Web 全栈、前端、跨平台 |
| 🔵 **Java/Kotlin** | 企业级后端、Android |
| 🟣 **Rust** | 系统编程、高性能场景 |
| ⚪ **Go** | 云原生、微服务、CLI 工具 |
| 🟠 **C# (.NET)** | Windows 桌面、游戏、企业应用 |
| 🔴 **Swift** | Apple 生态 (iOS/macOS) |
| 🤔 **我不确定，帮我推荐** | → 追问项目类型 → 加载 `references/language-guide.md` → 列出优劣势 + 推荐 |

**「我不确定」分支的推荐逻辑：**

1. 追问项目类型：Web 应用 / 移动 App / 桌面应用 / CLI 工具 / AI/ML / 游戏 / 嵌入式
2. 追问关注点：开发速度 / 运行性能 / 生态丰富度 / 学习曲线
3. 加载 `references/language-guide.md`，输出推荐表：

```
## 语言推荐

根据你的需求（[项目类型] + [关注点]），推荐以下语言：

| 语言 | 适合度 | 优势 | 劣势 |
|------|--------|------|------|
| [语言A] | ⭐⭐⭐⭐⭐ | [优势] | [劣势] |
| [语言B] | ⭐⭐⭐⭐ | [优势] | [劣势] |
| [语言C] | ⭐⭐⭐ | [优势] | [劣势] |

**推荐首选：[语言]** — [一句话理由]
```

用户确认语言后，进入强制六步流程。

#### Step 0c：技术栈确认 + 能力发现（7 步子程序）

详细算法参见 `references/scanner-patterns.md`。

---

**0c-1. 项目指纹扫描**

**扫描前 — 缓存检查：**

1. 检查会话上下文中是否存在 `_SCAN_CACHE` 记录（包含 `timestamp` 和 `fingerprint`）
2. 若存在缓存记录：
   - 读取 `.discovery-rules.json` 中的 `cache_ttl_hours`（默认 24 小时）
   - 若距上次扫描未超过 TTL → 复用缓存指纹和扫描结果，跳过 0c-1 和 0c-2，直接进入 0c-3
   - 若已超过 TTL → 继续执行完整扫描
3. 若不存在缓存记录（首次扫描）→ 继续执行完整扫描

对已有项目执行扫描。使用 `Glob` 检查以下文件（扩展的检测矩阵在 `references/scanner-patterns.md` §Fingerprint Detection Map）：

| 文件 | 推断结果 |
|------|---------|
| `pom.xml` | Java + Maven |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin + Gradle |
| `package.json` | Node.js / JavaScript / TypeScript |
| `tsconfig.json` | TypeScript |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `requirements.txt` / `pyproject.toml` / `setup.py` | Python |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `*.sln` / `*.csproj` | .NET / C# |
| `CMakeLists.txt` | C/C++ |
| `pubspec.yaml` | Flutter/Dart |
| `Package.swift` / `*.xcodeproj` | Swift / Apple 生态 |
| `docker-compose.yml` / `Dockerfile` | DevOps / Container |
| `next.config.*` | Next.js |
| `vite.config.*` | Vite |
| `tailwind.config.*` | Tailwind CSS |
| `astro.config.*` | Astro |
| `nx.json` / `turbo.json` | Monorepo (Nx/Turborepo) |
| `pnpm-lock.yaml` | pnpm |
| `bun.lockb` | Bun |
| `deno.json` | Deno |
| `schema.prisma` | Prisma |
| `schema.graphql` | GraphQL |

- 如果 `package.json` 存在，`Read` 其 `dependencies` 和 `devDependencies` 提取框架关键词
- 如果 `pom.xml` 存在，`Grep` 查找 `<artifactId>` 和 `<parent>` 检测 Spring Boot、Quarkus 等
- 检测 `app/` 或 `src/` 子目录作为补充信号

**对全新项目：** 直接使用 Step 0b 选择的语言/框架。

**输出：** 项目指纹（逗号分隔标签，如 `java, spring-boot, maven, postgresql`）。

**联动钩子（仅 PACKAGE_MODE = true）：** 检测 `.git/config` 中 GitHub remote，若存在则匹配 `integrates_with: pr-management`，提示 "💡 检测到 GitHub 项目。推荐使用 **GitHub PR 管理器** 来管理此仓库的 Pull Request。"

---

**0c-2. 能力清单扫描（并行执行）**

加载 `references/scanner-patterns.md` 进行并行三路扫描。

**扫描前 — 读取深度探索配置：**

1. 尝试读取 `~/.claude/skills/.discovery-rules.json`
2. 若文件存在且定义了 `deep_explore_plugins`（字符串数组）→ 使用该列表作为深度探索目标
3. 若文件存在且定义了 `priority_boost_plugins`（字符串数组）→ 使用该列表作为优先级加成插件
4. 若文件不存在或字段缺失 → 使用内置默认值：
   - `deep_explore_plugins`: `["everything-claude-code", "superpowers", "andrej-karpathy-skills", "oh-my-claudecode"]`
   - `priority_boost_plugins`: `["everything-claude-code", "superpowers", "andrej-karpathy-skills"]`

**2a. 技能扫描：** Glob `~/.claude/skills/*/SKILL.md`，解析 frontmatter 提取 name、description、tags、category、source。

**2b. 插件扫描：**
- MCP 配置：读取 `~/.claude/settings.json` → `mcpServers`，提取 server name、type、command、description
- 本地插件：Glob `~/.claude/plugins/*/plugin.json` 或 `package.json`

**2c. 深度探索（必需，参见 scanner-patterns.md §Deep Exploration Reference）：**
对上一步确定的深度探索目标插件列表执行深度探索：
- 列出根级 `.md`/`.json`/`.yaml`/`.yml`/`.mdc` 文件（跳过 node_modules、.git）
- 读取每个 `.md` 文件前 5-10 行识别用途
- 扫描嵌套技能（`.agents/skills/*/SKILL.md`）
- 提取 `.mdc` 规则文件名和描述
- 输出格式：tagged with `source: deep-exploration` and `plugin: <name>`，每项含 name、type (soul/rules/agents/claude-md/commands-ref/nested-skill)、description、path

---

**0c-3. 匹配与排序**

加载 `references/scanner-patterns.md` §Skill-to-Project Matching Algorithm + §Priority Boost System。

**技能评分：** 标签匹配 +3、框架匹配 +3、类别对齐 +1、通用 +0
**插件评分：** 工具匹配 +3、领域匹配 +1、通用 +0

**优先级加成系统（Priority Boost）：**
检测到 ECC、superpowers、andrej-karpathy-skills、oh-my-claudecode 或深度资源时 → base score = max(normal_score, 10)，标记 ⭐ 置顶。

**按意图过滤：**

| 意图 | 优先推荐 | 降权 |
|------|---------|------|
| 开发新功能 | 对应语言的开发技能、代码生成工具 | 审查/调试类 |
| 审查代码 | 代码审查、PR 审查、lint 技能 | — |
| 修复 Bug | 调试、错误追踪、测试技能 | — |
| 探索工具 | 不做过滤，展示全部匹配结果 | — |

**输出三个独立列表（始终按此顺序）：**
1. ⭐ 优先推荐（加成插件/深度资源 — 始终最先）
2. 📋 推荐技能（top 5-10，项目匹配）
3. 🔌 推荐插件（top 3-5，项目匹配）

未匹配项保留给 Step 0c-6 全量导出。

---

**0c-4. 交互式推荐（⚠️ 强制步骤）**

展示推荐结果，使用以下模板：

```markdown
## 🔍 项目识别结果

**项目:** [项目名或路径]
**技术栈:** [语言] + [框架] + [构建工具]
**检测依据:** [发现的配置文件列表]

## ⭐ 优先推荐（核心能力增强）

> 以下插件/资源提供基础能力增强，无论项目类型都强烈建议启用。

| # | 名称 | 类型 | 描述 | 包含的未加载资源 |
|---|------|------|------|----------------|
| 1 | `everything-claude-code` | 插件 | AI 行为配置/安全指南 | SOUL.md, RULES.md, AGENTS.md, COMMANDS-QUICK-REF.md, WORKING-CONTEXT.md, the-security-guide.md, agent.yaml, 嵌套技能 |
| 2 | `superpowers` | 插件 | 核心工作流技能 | AGENTS.md, hooks.json, GEMINI.md |
| 3 | `andrej-karpathy-skills` | 插件 | Karpathy 编码准则 | CURSOR.md, karpathy-guidelines.mdc |
| 4 | `oh-my-claudecode` | 插件 | 多 Agent 编排 | 数十个嵌套技能 (`.agents/skills/*/SKILL.md`) |

## 📋 推荐技能（按匹配度排序）

| # | 名称 | 描述 | 匹配理由 | 来源 |
|---|------|------|---------|------|

## 🔌 推荐插件（按匹配度排序）

| # | 名称 | 描述 | 匹配理由 | 类型 |
|---|------|------|---------|------|
```

> 💡 如插件列表为空，则显示："未检测到与当前项目强相关的插件。"

**使用 `AskUserQuestion` 询问：**
> "以上是根据当前项目为您推荐的技能、插件和未加载资源，请问您希望如何处理？"

提供以下选项：
- **一键启用所有推荐** — 在后续对话中主动使用所有推荐项
- **逐项选择** — 由用户指定启用哪些（可输入编号）
- **跳过，本次不启用** — 记录选择，本次会话不再重复推荐
- **了解更多** — 展开某个技能/插件/深度资源的详细说明（用户指定名称）
- **加载未加载资源** — 对深度探索发现的 SOUL/RULES/AGENTS 等文件，询问是否需要手动加载

**联动钩子（仅 PACKAGE_MODE = true）：**

对推荐列表中未安装的插件标记 🆕。用户选择后，匹配 `integrates_with: plugin-installation`：
- 若用户选择了未安装的能力 → 提示："💡 检测到你尚未安装 [name]。是否需要使用 **快速插件安装器** 来安装它？"

---

**0c-5. 指令发现（仅在用户完成 0c-4 选择后执行）**

⚠️ 若用户选择「跳过」→ 跳至 0c-6

加载 `references/scanner-patterns.md` §Command Discovery Reference。

**5a. MCP 工具发现（仅扫描用户已选择的插件）：**
1. 使用 `ListMcpResourcesTool` 枚举 MCP 资源，或扫描系统提示中 `mcp__` 前缀工具
2. 仅过滤属于用户**已选择**插件的工具
3. 每个工具推断：作用（做什么）+ 适用场景（什么时候用）

**5b. Slash 命令发现：**
从系统提示中提取 `/` 命令，匹配所选技能类别/能力

**5c. 展示模板：**

```markdown
## 🔧 所选工具的可用指令

根据您选择的 [skill-names] 和 [plugin-names]，以下是可用的指令：

### 🛠 MCP 工具指令

#### [Selected Plugin Name]
| 工具名称 | 作用 | 适用场景 |
|---------|------|---------|
| `mcp__*__tool_name` | [一句话描述] | [什么情况下使用] |

### ⌨️ 相关 Slash 命令

| 命令 | 作用 | 适用场景 |
|------|------|---------|
| `/command-name` | [功能描述] | [什么情况下使用] |
```

> 💡 如果选中的插件没有 MCP 工具或当前无 MCP 连接，显示："所选插件当前无可用的 MCP 工具指令。"
> 💡 Slash 命令始终可用，至少列出与所选技能相关的通用命令。

---

**0c-6. 全量导出（⚠️ 先问后导）**

必须获得用户同意后才导出。

询问用户：
> "是否需要将所有已安装的技能、插件和指令完整列表导出到文件？这样您可以离线浏览所有可用能力。"

若用户同意，追问三个选项（使用 `AskUserQuestion`）：
1. **目标导出目录** — 输入路径（如 `D:\docs\skills-list\`）
2. **输出语言** — 自由输入任意语言（默认跟随当前对话语言）
3. **输出格式** — `Markdown`（推荐）/ `JSON` / `纯文本`

**导出内容结构：** 加载 `references/scanner-patterns.md` §Export Field Definitions。

导出文件命名：`{project-name}-skills-plugins-export.{format}`

```markdown
# [标题 — 使用用户指定语言]

> 导出时间: [timestamp]
> 项目: [project path]
> 总计: [N] 个技能, [M] 个插件, [K] 个指令
> 语言: [用户指定的语言]

## 📋 技能 (Skills) — 按分类

### [Category]
| 名称 | 描述 | 标签 | 来源 | 文件路径 |
| ... | ... | ... | ... | ... |

## 🔌 插件 (Plugins) — 按类型

### [Type]
| 名称 | 类型 | 命令 | 描述 | 来源 |
| ... | ... | ... | ... | ... |

## 🔧 指令 (Commands)

### 🛠 MCP 工具指令 — 按插件分组

#### [Plugin Name]
| 工具名称 | 作用 | 适用场景 |
|---------|------|---------|

### ⌨️ Slash 命令 — 按分类

#### [Category]
| 命令 | 作用 | 适用场景 |
|------|------|---------|
```

---

**0c-7. 上下文持久化**

- 用户选择「跳过」→ 记录到会话上下文，本次会话不再重复推荐（除非项目指纹显著变化）
- 用户选择特定技能/插件 → 记录接受列表，供后续联动引用
- 项目指纹显著变化时重新触发发现。**显著变化定义为以下任一：**
  - 新增了任意语言/框架配置文件（如新出现 `package.json`、`go.mod`、`Cargo.toml`、`pom.xml` 等）
  - 新增了子目录且子目录包含独立的项目配置文件
  - 用户通过 `git checkout` 切换到了不同技术栈的分支
  - 工作目录切换到了同一 monorepo 的不同子项目
- **仅文件内容修改（不改变技术栈）不触发重新发现**
- 其他包内技能完成主要操作后 → 提示联动发现
- **缓存记录**：扫描完成后，在会话上下文中记录 `_SCAN_CACHE = { timestamp: <当前时间>, fingerprint: <项目指纹标签>, ttl_hours: <从 rules 读取的 cache_ttl_hours，默认 24> }`，供后续调用复用

---

非「启动新项目」意图在此步骤结束，不进入强制六步流程。但能力扫描结果可作为后续工作的上下文。

---

### 强制六步流程（仅「启动新项目」时执行）

以下六步是原 kickoff 的完整流程，**必须按顺序执行**。

### 第一步：澄清"为什么"与"是什么"
向用户提问（至少覆盖以下 3 个问题）：
1. 这个项目解决了谁的什么痛点？不做会有什么损失？
2. 成功的可衡量标准是什么？（例如：日活>1000，成本<0.1元/次，首个付费用户等）
3. 请用一句话填空："我们要为【谁】解决【什么问题】，通过【什么方式】，达到【什么效果】。"

- 如果用户无法回答第 3 问，则引导其先完成"一句话定义"，再继续。
- 如果是 AI Agent 项目，额外追问："不用 Agent 行不行？规则引擎能否解决？"
- 如需更详细的问题定义指导，加载 `references/project-checklist.md` 第一章或 `references/ai-agent-checklist.md` 第一章。

### 第二步：圈定边界 – 明确"不做什么"
要求用户列出第一版的所有想做的功能，然后：
- 强制砍掉 80%，只保留**能验证核心假设的最小集合（MVP）**。
- 明确三重约束（时间、成本/资源、质量/范围），并指出"最多只能同时保两个"。
- 如果是 Agent 项目，额外列出**禁飞区**（例如：不能删除生产数据、不能对外转账、不能发送未审核内容）。
- 边界讨论遇到困难时，加载 `references/project-checklist.md` 第二章。

**联动钩子（仅 PACKAGE_MODE = true 时执行）：**

确认项目技术栈后，扫描兄弟技能的 `capabilities`，匹配 `integrates_with: plugin-installation`：
- 匹配成功 → 提示用户："💡 检测到你的项目使用 [技术栈]。是否需要安装相关的 MCP Server（如 GitHub MCP、Playwright、Context7）来增强开发体验？"

### 第三步：快速风险摸底
让用户回答：
- 技术、人力、市场、合规四方面是否有明显障碍？
- 写下**最可能让项目失败的三件事**，并为每件想一个 B 计划（即便只是"换方案，慢 30%"）。
- 对于 AI Agent：用当前最强模型做"纸上原型"手动模拟 3~5 步，观察是否会跑偏。若跑偏，要求简化任务或增加护栏。
- 详细可行性分析模板参见 `references/project-checklist.md` 第三章；Agent 特有风险评估参见 `references/ai-agent-checklist.md` 第四章。

### 第四步：利益相关者与期望对齐
- 引导用户识别核心圈（执行者）、影响圈（资源方）、外围圈（用户/监管）。
- 强制建议："拿着第一步的'项目定义'和'成功标准'，去跟关键人物口头确认一次，再继续。"
- 完整利益相关者分析指导参见 `references/project-checklist.md` 第四章。

### 第五步：绘制粗糙路线图（仅里程碑）
- 输出 3~5 个里程碑（以周为单位），每个里程碑必须有明确的**产出物**和**验收标准**。
- 最后，要求用户确认以下开工 Checklist：
  - ☑ 项目定义与目标已和关键人确认
  - ☑ MVP 范围已明确（以及不做什么）
  - ☑ 资源（时间、钱、人）已到位或得到承诺
  - ☑ 前三风险已有应对预案
  - ☑ 代码仓库、沟通群组、文档协作工具已就绪
- 路线图设计参考参见 `references/project-checklist.md` 第五章。

### 第六步（关键）：生成 CLAUDE.md —— 将思考成果固化到项目

在完成五步检查并确认代码风格后，**必须**执行以下流程：

#### 6a. 确认用户意愿
向用户确认：
> "我们已经完成了五步启动检查，并确认了项目的代码风格。现在要调用 /init 生成项目的 CLAUDE.md，把刚才讨论的内容 —— 项目定义、MVP 范围、里程碑、风险预案、风格约定 —— 都固化到项目根目录。是否继续？"

- 如果用户同意，继续 6b。
- 如果用户暂不需要，跳至 6d。

#### 6b. 检测已有 CLAUDE.md
检查项目根目录是否已存在 `CLAUDE.md` 文件：
- **若不存在**：直接执行 `/init` 命令。`/init` 是 Claude Code 的内置项目初始化命令，会引导生成标准的 CLAUDE.md 文件。技能已收集的五步检查信息都在对话上下文中，/init 可直接利用。
- **若已存在**：读取现有 CLAUDE.md，执行逐段对比合并：
  1. 提取现有 CLAUDE.md 中的自定义命令、构建步骤、测试框架配置 → **保留不动**
  2. 对比五步检查结果，识别缺失章节（项目定义、MVP 范围、风险预案、风格约定）
  3. 仅补充缺失部分，不覆盖已有内容
  4. 向用户展示合并差异摘要，确认后写入

#### 6c. 验证生成结果
在 `/init` 执行完毕后：
- 检查项目根目录是否已生成或更新了 CLAUDE.md。
- 如果生成成功，向用户展示摘要：
  > "✅ CLAUDE.md 已生成。你的项目现在有了一个包含项目定义、MVP 范围、里程碑、风险预案和代码风格约定的标准入口文件。每次 Claude 进入这个项目时都会自动加载这些上下文。"
- 如果 `/init` 因任何原因未完成（如用户中途退出），使用下面的"输出模板"手动输出一份启动摘要，并告知用户随时可再次运行 `/init`。

**联动钩子（仅 PACKAGE_MODE = true 时执行，在 6c 成功后）：**

CLAUDE.md 生成成功后，本技能已内置完整的技能发现能力（Step 0c），可直接提示用户：
> "✅ CLAUDE.md 已生成。是否需要扫描当前项目技术栈，推荐匹配的技能和插件？"

（无需通过 `integrates_with: skill-discovery` 跨技能联动——此能力内置于本技能中。）
- 同时检查其他兄弟技能的 `integrates_with`，如发现匹配则一并提示

#### 6d. 后备方案
如果用户选择不执行 `/init`，输出完整的启动摘要（见下方模板），并告知：
> "了解。以下是本次启动检查的完整摘要。你可以随时运行 `/init` 来将这些内容固化为正式的 CLAUDE.md。"

---

## 代码风格保留规则（必须执行）

当本项目涉及生成任何代码、配置文件、注释模板或项目脚手架时，**必须**按以下优先级确定并保留风格：

1. **主动探测**：检查用户是否已提供现有代码文件、`.editorconfig`、`eslint`/`prettier` 配置、或口头说明的风格偏好（如"我们用制表符缩进"）。
2. **若无既有风格，则采用行业默认推荐**（例如 Python 用 PEP8，JavaScript 用 2 空格缩进，注释使用 `#` 或 `//` 后跟一个空格），并在生成前向用户确认。
3. **注释规范**：要求用户提供注释密度偏好（关键函数必写 / 仅复杂逻辑写 / 每一行都写）。默认采用"公共 API 和复杂逻辑写注释，自解释的语句不写"。
4. **命名规范**：明确变量、函数、类、文件的命名风格（驼峰、下划线、大驼峰等），并统一应用到所有生成内容。
5. **即使生成示例代码，也要符合上述风格**；若用户未指定，在代码块上方用注释标明"请按你的项目风格调整"。

---

## 针对 AI Agent 项目的额外检查项

若用户确认项目类型为 AI Agent，在完成上述六步后，追加以下问题（详细内容参见 `references/ai-agent-checklist.md`）：
- 记忆系统（短期/长期）如何设计？（参见第三章）
- 规划策略（ReAct / Plan-and-Execute / 多 Agent）选哪一种？（参见第三章）
- 工具集的输入/输出格式是否严格定义？（参见第三章）
- 如何评估"好坏"？（任务成功率、工具调用准确率、成本）（参见第七章）
- 安全与伦理：防注入、权限最小化、透明度、合规是否已考虑？（参见第八章）

并建议用户先实现一个**最小可行性 Agent**（模型调用 + 一个工具），再引入框架。

---

## 输出模板（强制使用）

在完成六步检查后，**必须**使用以下格式输出启动摘要（控制在 500 字以内）：

```markdown
## 项目启动摘要：[项目名称]

### 项目定义
- **一句话**：[填入]
- **成功标准**：[可衡量指标]
- **利益相关者**：核心圈=[...], 影响圈=[...], 外围圈=[...]

### MVP 范围
- **包含**：[功能A, 功能B]
- **不包含**：[功能C, 功能D, 功能E]
- **约束**：时间=[Deadline], 资源=[预算/人力], 质量=[可妥协项]

### 路线图
| 里程碑 | 产出物 | 验收标准 |
|--------|--------|---------|
| W1 | [产出物] | [标准] |
| W2 | [产出物] | [标准] |
| W3 | [产出物] | [标准] |

### 风险预案
| 风险 | 可能性 | B计划 |
|------|--------|-------|
| [风险1] | 高/中/低 | [备选方案] |
| [风险2] | 高/中/低 | [备选方案] |
| [风险3] | 高/中/低 | [备选方案] |

### 代码风格约定
- 缩进：[空格/制表符，数量]
- 注释：[密度与格式]
- 命名：[变量/函数/类规则]

### 开工状态
☑ 全部确认完成 → /init 已调用，CLAUDE.md 已生成 ✅
```

---

## 边界条件处理

### 用户已有 CLAUDE.md
如果检测到项目根目录已存在 CLAUDE.md（在第六步之前或之中检测到），先询问用户是覆盖更新还是合并补充。建议策略：读取现有 CLAUDE.md 内容，与五步检查结果对比，补充缺失的部分而非完全覆盖——CLAUDE.md 中可能已包含项目特有的构建命令、测试框架等不应被覆盖的信息。

### 非项目所有者场景
如果用户明确表示是为他人项目提供建议（如"帮我朋友看看他的项目计划"），则：
- 跳过第六步（/init 调用），不修改他人的 CLAUDE.md
- 跳过代码风格询问（除非用户主动问）
- 集中精力完成五步分析和建议
- 输出启动摘要供用户转发

### 用户只要求部分检查
用户可能只关心某个方面（如"帮我只做风险摸底"）。灵活处理：
- 用户可以选择只走某几个步骤
- 完成所请求的步骤后，简要询问是否需要完成剩余步骤
- 不强制走完六步，但总要提及"如果需要完整启动检查，随时可以说"

### 项目范围极小

满足以下**任意 2 条**即启用极简模式：

1. **任务描述为单文件级**：用户描述为「写一个脚本」「一个工具」「一个函数」「批量处理」等单文件级任务
2. **源代码文件数量少**：项目目录中源代码文件 < 3 个（不含 `README.md`、`.gitignore`、`*.json`/`*.toml`/`*.yaml` 等配置文件）
3. **用户明确要求简化**：用户明确表示「不需要完整流程」「简单弄一下就行」「快速过一遍」

**仅满足 1 条时**，追问用户确认是否启用极简模式。

极简模式内容：
- **执行**：问题定义（一句话）+ 代码风格确认
- **跳过**：MVP 边界圈定（第二步）、利益相关者分析（第四步）、里程碑路线图（第五步）
- **仍执行**：快速风险摸底（第三步，简化为"最可能出错的一件事"）
- **仍执行**：第六步 CLAUDE.md 生成（若项目目录存在）
- 完成后提示："这是一个极简项目。如需完整启动检查流程，随时可以说。"

---

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| `~/.claude/skills/` 不存在或无法读取 | 跳过技能扫描，仅推荐插件和命令，不报错 |
| SKILL.md frontmatter 格式错误 | 跳过该技能，记录名称到跳过列表，继续扫描其他技能 |
| `settings.json` 无 `mcpServers` 字段 | 跳过 MCP 插件扫描，仅扫描本地插件目录 |
| `.discovery-rules.json` JSON 解析失败 | 静默跳过，使用内置默认规则 |
| Glob 操作超时（>5 秒） | 跳过深度探索，标注「部分插件未深度扫描」 |
| 深度探索文件 > 50KB | 仅读前 5 行判断类型，不读取全文 |
| PACKAGE_MODE 检测失败（任何原因） | 降级为 PACKAGE_MODE = false，静默运行 |
| `/init` 执行失败 | 手动输出启动摘要，提示用户可随时重试 |

---

## 交互风格
- 使用简洁的清单式提问，每次最多问 3 个问题，避免信息过载。
- 对用户的回答进行总结并复述，确保对齐。
- 最后输出一份 **< 500 字的启动摘要**，包含：项目定义、MVP 范围、关键里程碑、前三风险、风格约定、CLAUDE.md 生成状态。
- 全程使用中文与用户沟通。
