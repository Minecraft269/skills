---
name: proactive-skill-discovery
description: "主动发现并推荐适用于当前项目的 SKILLS、PLUGINS 和指令（Commands）。分析项目特征（语言、框架、文件结构），扫描已安装的能力库（技能、插件、MCP 工具、Slash 命令），生成匹配推荐，提升 Claude Code 的工具利用率和项目适配度。支持交互式推荐确认、全量能力导出及任意语言输出。"
category: meta
risk: safe
source: community
tags: "[discovery, recommendation, skills, plugins, commands, mcp-tools, slash-commands, project-analysis, onboarding, productivity]"
---

# proactive-skill-discovery

## Purpose

让 Claude Code 在关键节点（项目启动、复杂任务、项目类型变化）主动扫描、匹配并推荐当前可用的技能（Skills）、插件（Plugins）和指令（Commands — 含 MCP 工具和 Slash 命令），避免能力闲置，提升开发效率。

## When to Use This Skill

This skill should be invoked when:

- 用户打开一个项目（session 启动时）
- 用户提出复杂任务且未明确指定使用哪个技能或插件
- 用户输入 `/discover` 或明确要求推荐技能/插件
- 检测到项目类型发生显著变化（如从前端切换到后端子项目）
- 用户询问"有哪些可用的技能/插件"或类似问题

Do NOT invoke this skill when:
- 用户已经明确指定了要使用的具体技能
- 对话仅为简单问答，不涉及项目开发任务
- 用户明确表示不需要推荐

## Core Capabilities

1. **项目识别** — 自动检测项目语言、框架、构建工具、依赖等特征
2. **能力扫描** — 并行扫描 Skills（`~/.claude/skills/`）和 Plugins（MCP 配置 + 本地插件目录），解析元数据
3. **智能匹配** — 基于标签/关键词/框架名称，对技能和插件进行评分匹配
4. **交互式推荐** — 展示推荐清单（技能+插件），**必须询问用户**是否启用
5. **指令发现** — **用户选择技能/插件后**，扫描所选工具的可用指令（MCP 工具 + Slash 命令），展示作用和适用场景
6. **全量导出** — 按用户需求将全部技能、插件和指令清单导出到指定目录
7. **上下文记忆** — 记录用户选择，避免重复打扰，支持重新发现

## Workflow

When invoked, follow this 7-step process. Proceed through each step in order — do not skip steps unless the user explicitly requests it.

### Step 1: Project Identification

Analyze the current project to build a technology profile.

**What to scan (check existence of these files):**

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
| `docker-compose.yml` / `Dockerfile` | DevOps / Container |
| `next.config.*` | Next.js |
| `vite.config.*` | Vite |
| `tailwind.config.*` | Tailwind CSS |
| `astro.config.*` | Astro |
| `app/` or `src/` subdirectories | 补充目录结构信息 |

**How to scan (use in this order):**
1. Use `Glob` to check for the files above
2. If `package.json` found, use `Read` to extract `dependencies` and `devDependencies` keys for framework detection
3. If `pom.xml` found, use `Grep` for `<artifactId>` and `<parent>` to detect Spring Boot, Quarkus, etc.

**Output:** Build a project fingerprint as comma-separated tags (e.g., `java, spring-boot, maven, postgresql`).

### Step 2: Capability Inventory — Skills AND Plugins

Scan BOTH skills and plugins with equal weight. These are parallel tasks.

#### 2a. Scan Skills

**Skills directory:** `~/.claude/skills/` (or the configured skills path from settings)

For each skill subdirectory, read its `SKILL.md` frontmatter (the YAML block between `---` delimiters) to extract:
- `name` — skill identifier
- `description` — one-line summary
- `tags` — applicability tags (JSON array string)
- `category` — skill category (e.g., `dev`, `meta`, `ops`)
- `source` — origin (`community`, `official`, `custom`)

**How:** Use `Glob` to list `~/.claude/skills/*/SKILL.md`, then use `Grep` with pattern `^---$` to locate frontmatter, or `Read` the first ~10 lines of each file to parse the YAML header.

#### 2b. Scan Plugins

**Two sources to scan:**

**Source 1 — MCP 配置:** Read `~/.claude/settings.json` → `mcpServers` section. For each server entry, extract:
- Server name (key)
- `type` — protocol type (stdio, sse, streamable-http, etc.)
- `command` — executable path
- `description` — if available in the entry

**Source 2 — 本地插件目录:** Check `~/.claude/plugins/` for locally installed plugin files. Each plugin subdirectory is a plugin. Extract metadata from `plugin.json` or `package.json`.

#### 2c. Deep Exploration — Unindexed Plugin Resources

Some plugins contain important files that are NOT automatically loaded or indexed — they exist on disk but Claude Code won't discover them unless explicitly scanned. This step finds those hidden capabilities.

**Priority plugins and their unindexed resources:**

| 插件 | 未加载的关键文件 | 类型 |
|------|---------------|------|
| **everything-claude-code (ECC)** | `SOUL.md`, `RULES.md`, `AGENTS.md`, `CLAUDE.md`, `COMMANDS-QUICK-REF.md`, `WORKING-CONTEXT.md`, `the-security-guide.md`, `agent.yaml` | 行为准则/安全指南/指令参考/Agent配置 |
| **ECC 嵌套技能** | `.agents/skills/*/SKILL.md` (数十个) | 插件内置技能，可能未出现在 `~/.claude/skills/` |
| **superpowers** | `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `hooks/hooks.json` | 多平台 Agent 行为配置/Hooks |
| **andrej-karpathy-skills** | `CLAUDE.md`, `CURSOR.md`, `.cursor/rules/karpathy-guidelines.mdc`, `skills/karpathy-guidelines/SKILL.md` | RULES 行为准则/嵌套技能 |

**How to deep-explore:**
1. For each plugin in `~/.claude/plugins/`, list root-level `.md`, `.json`, `.yaml`, `.yml`, `.mdc` files (skip `node_modules`, `.git`, `package-lock.json`)
2. Read the first 5-10 lines of each `.md` file to identify its purpose (SOUL/RULES/AGENTS/CLAUDE/etc.)
3. For nested skills (`.agents/skills/*/SKILL.md`), read frontmatter same as Step 2a
4. For `.mdc` (Cursor rules) files, extract rule name and description

**Output of 2c:** "Deep Resources" — tagged with `source: deep-exploration` and `plugin: <plugin-name>`. Each entry has: name, type (soul/rules/agents/claude-md/commands-ref/nested-skill), description, and path.

**Parallelize:** Run 2a, 2b, and 2c concurrently.

### Step 3: Match & Rank

Match the project fingerprint against skills and plugins:

**For Skills:**
- **Direct match (score +3):** Skill tag directly matches a detected technology (e.g., project has `java` → skill tagged `[java, ...]`)
- **Framework match (score +3):** Skill name or tag contains a detected framework name (e.g., `springboot-patterns` for Spring Boot)
- **Category match (score +1):** Skill category aligns with project domain
- **Generic/utility (score +0):** Universally useful skills (e.g., `git-workflow`, `commit`, `code-review`)

**For Plugins:**
- **Tool match (score +3):** Plugin name/command aligns with project toolchain (e.g., `playwright` plugin for a frontend project, `github` plugin for any dev project)
- **Domain match (score +1):** Plugin provides capabilities relevant to the project type (e.g., `context7` for documentation-heavy projects, `postgres` for database projects)
- **Generic/utility (score +0):** Plugins useful across all projects

#### Priority Boost System

Certain plugins provide foundational capabilities that enhance all workflows. When detected, these receive a **+10 priority boost** to guarantee top placement — regardless of project match score:

| 优先级插件 | 提升原因 |
|-----------|---------|
| `everything-claude-code` (ECC) | 提供 SOUL/RULES/AGENTS 行为准则、嵌套技能、安全指南 — 是 Claude Code 的"操作系统"级插件 |
| `superpowers` | 提供核心工作流技能（TDD/调试/规划/代码审查）+ 多平台适配 |
| `andrej-karpathy-skills` | Karpathy 编码准则 — 提升所有代码输出质量 |
| Any deep resource from Step 2c | 被发现的未加载资源（SOUL/RULES/嵌套技能等） |

**How the boost works:**
1. After scoring, check if any of the above plugins/resources exist
2. If found: their base score = `max(normal_score, 10)`, placing them at or near the top
3. Mark them with ⭐ in the recommendation display to indicate priority status

**Combine and sort by score descending. Produce THREE separate lists:**
1. ⭐ Priority Recommendations (boosted skills/plugins + deep resources — always first)
2. Recommended Skills (top 5-10, project-matched)
3. Recommended Plugins (top 3-5, project-matched)

Store remaining unmatched items separately for Step 6 (full export).

### Step 4: Interactive Recommendation

**⚠️ THIS STEP IS MANDATORY. You MUST ask the user after displaying recommendations.**

Display results using this template:

```markdown
## 🔍 项目识别结果

**项目:** [项目名或路径]
**技术栈:** [语言] + [框架] + [构建工具]
**检测依据:** [发现的配置文件列表]

## ⭐ 优先推荐（核心能力增强）

> 以下插件/资源提供基础能力增强，无论项目类型都强烈建议启用。

| # | 名称 | 类型 | 描述 | 包含的未加载资源 |
|---|------|------|------|----------------|
| 1 | `everything-claude-code` | 插件 | AI 行为配置/安全指南 | SOUL.md, RULES.md, AGENTS.md, COMMANDS-QUICK-REF.md, 嵌套技能 |
| 2 | `superpowers` | 插件 | 核心工作流技能 | AGENTS.md, hooks.json, GEMINI.md |
| 3 | `andrej-karpathy-skills` | 插件 | Karpathy 编码准则 | CURSOR.md, karpathy-guidelines.mdc |

## 📋 推荐技能（按匹配度排序）

| # | 名称 | 描述 | 匹配理由 | 来源 |
|---|------|------|---------|------|
| 1 | `[skill-name]` | [description] | [reason] | [source] |
| 2 | ... | ... | ... | ... |

## 🔌 推荐插件（按匹配度排序）

| # | 名称 | 描述 | 匹配理由 | 类型 |
|---|------|------|---------|------|
| 1 | `[plugin-name]` | [description] | [reason] | [type] |
| 2 | ... | ... | ... | ... |
```

> 💡 如插件列表为空，则显示："未检测到与当前项目强相关的插件。"

**After displaying the tables, use AskUserQuestion to ask:**

> **"以上是根据当前项目为您推荐的技能、插件和未加载资源，请问您希望如何处理？"**

提供以下选项：
- **一键启用所有推荐** — 在后续对话中主动使用所有推荐项（优先+技能+插件+深度资源）
- **逐项选择** — 由用户指定启用哪些（可输入编号）
- **跳过，本次不启用** — 记录选择，本次会话不再重复推荐
- **了解更多** — 展开某个技能/插件/深度资源的详细说明（用户指定名称）
- **加载未加载资源** — 对深度探索发现的 SOUL/RULES/AGENTS 等文件，询问是否需要手动加载/激活

### Step 5: Command Discovery — AFTER User Selection

**⚠️ This step executes ONLY after the user has made a selection in Step 4. If user chose "跳过", skip to Step 6.**

After the user has selected which skills/plugins to use, scan those **selected items** for their available commands and display them with descriptions.

#### 5a. Discover Commands for Selected Plugins (MCP Tools)

For each MCP plugin the user selected, discover its available tools:

**How to discover:**
1. Use `ListMcpResourcesTool` to enumerate available MCP resources
2. Alternatively, scan the system prompt for tools prefixed with `mcp__` (e.g., `mcp__plugin_github_github__create_pull_request`)
3. Filter to only show tools belonging to the **selected** plugins
4. For each tool, infer from its name:
   - **作用** — what the tool does (e.g., `create_pull_request` → "创建 GitHub Pull Request")
   - **适用场景** — when to use it (e.g., "当你需要提交代码合并请求时")

#### 5b. Discover Relevant Slash Commands

Scan for Slash commands relevant to the selected skills/plugins:

**How to discover:**
1. In the system prompt, locate the "available skills" section for slash commands (format: `- name: description`)
2. Match commands to the selected skills' categories/capabilities
3. Also include universally useful commands
4. For each command:
   - **作用** — from the system prompt description
   - **适用场景** — derive from description and command name

#### 5c. Display Commands

```markdown
## 🔧 所选工具的可用指令

根据您选择的 [skill-names] 和 [plugin-names]，以下是可用的指令：

### 🛠 MCP 工具指令

#### [Selected Plugin Name]
| 工具名称 | 作用 | 适用场景 |
|---------|------|---------|
| `mcp__plugin_*__tool_name` | [一句话描述] | [什么情况下使用] |

### ⌨️ 相关 Slash 命令

| 命令 | 作用 | 适用场景 |
|------|------|---------|
| `/command-name` | [功能描述] | [什么情况下使用] |
```

> 💡 如果选中的插件没有 MCP 工具或当前无 MCP 连接，显示："所选插件当前无可用的 MCP 工具指令。"
> 💡 Slash 命令始终可用，至少列出与所选技能相关的通用命令。

### Step 6: Optional Full Export

**⚠️ MUST ASK FIRST — do not export without user consent.**

After Step 5, ask the user:

> **"是否需要将所有已安装的技能、插件和指令完整列表导出到文件？这样您可以离线浏览所有可用能力。"**

If user says YES, follow up with these questions (use AskUserQuestion):

1. **目标导出目录** — 让用户输入路径（如 `D:\docs\skills-list\`）
2. **输出语言** — 让用户自由输入任意语言（如 `中文`、`English`、`日本語`、`Français`、`Deutsch`、`한국어` 等），默认跟随当前对话语言
3. **输出格式** — `Markdown`（推荐）/ `JSON` / `纯文本`

**Export content per skill:**

| 字段 | 说明 |
|------|------|
| 名称 | Skill name |
| 类别 | category（dev / meta / ops / ...） |
| 来源 | source（community / official / custom） |
| 描述 | description（翻译为用户指定语言） |
| 适用场景标签 | tags |
| 文件路径 | 安装路径 |

**Export content per plugin:**

| 字段 | 说明 |
|------|------|
| 名称 | Plugin / MCP server name |
| 类型 | 协议类型（stdio / sse / streamable-http） |
| 命令 | command / executable |
| 描述 | 功能描述（如 settings.json 中有提供） |
| 来源 | MCP 配置 / 本地插件目录 |

**Export content per command (MCP Tool):**

| 字段 | 说明 |
|------|------|
| 工具名称 | Full MCP tool name |
| 所属插件 | Parent MCP server |
| 作用 | 一句话描述功能 |
| 适用场景 | 在什么开发场景下使用该工具 |

**Export content per command (Slash Command):**

| 字段 | 说明 |
|------|------|
| 命令 | `/command-name` |
| 作用 | 功能描述 |
| 适用场景 | 在什么开发场景下使用该命令 |
| 分类 | Git / 审查 / 开发 / 调试 / 会话 / 设置 |

**Organize the export in sections:**
```markdown
# [标题 — 使用用户指定语言]

> 导出时间: [timestamp]
> 项目: [project path]
> 总计: [N] 个技能, [M] 个插件, [K] 个指令
> 语言: [用户指定的语言]

## 📋 技能 (Skills) — 按分类

### [Category translated, e.g., 开发类 / Development]
| 名称 | 描述 | 标签 | 来源 |
| ... | ... | ... | ... |

## 🔌 插件 (Plugins) — 按类型

### [Type, e.g., MCP Servers]
| 名称 | 类型 | 命令 | 描述 |
| ... | ... | ... | ... |

## 🔧 指令 (Commands)

### 🛠 MCP 工具指令 — 按插件分组

#### [Plugin Name]
| 工具名称 | 作用 | 适用场景 |
|---------|------|---------|
| [tool-name] | [what it does] | [when to use it] |

### ⌨️ Slash 命令 — 按分类

#### [Category, e.g., Git 操作 / 代码审查 / 开发流程]
| 命令 | 作用 | 适用场景 |
|------|------|---------|
| /[command] | [what it does] | [when to use it] |
```

### Step 7: Context Persistence

Record the user's choices to avoid repeated interruptions:

1. **If user chose "跳过":** Write a brief note to project memory: `~/.claude/projects/<project-hash>/memory/` recording that discovery was declined for this project context
2. **If user chose specific skills/plugins:** Note which were accepted and show their available commands (Step 5) for future reference
3. **Re-discover trigger:** When project fingerprint changes significantly (new framework detected, new subproject opened), re-run discovery. Do NOT re-run for the same fingerprint unless user explicitly requests it

## Output Templates

### Full Export Structure (Step 5)

```markdown
# 已安装技能、插件和指令完整清单

> 导出时间: [timestamp] | 项目: [path] | 总计: [N] 技能, [M] 插件, [K] 指令

## 📋 技能 (Skills)

### 开发类
| 名称 | 描述 | 标签 | 来源 |
|------|------|------|------|

### 运维类
...

### 元技能
...

## 🔌 插件 (Plugins)

### MCP Servers
| 名称 | 类型 | 命令 | 描述 |
|------|------|------|------|

### 本地插件
| 名称 | 描述 | 路径 |
|------|------|------|

## 🔧 指令 (Commands)

### 🛠 MCP 工具指令

#### plugin:github:github
| 工具名称 | 作用 | 适用场景 |
|---------|------|---------|
| create_pull_request | 创建 Pull Request | 提交代码后需要发起合并请求时 |
| search_code | 搜索代码 | 需要查找特定代码模式时 |

#### plugin:context7:context7
...

### ⌨️ Slash 命令

#### Git 操作
| 命令 | 作用 | 适用场景 |
|------|------|---------|
| /commit | 规范化提交代码 | 完成代码修改需要提交时 |
| /create-pr | 创建 Pull Request | 需要发起代码合并请求时 |

#### 代码审查
| 命令 | 作用 | 适用场景 |
|------|------|---------|
| /code-review | 审查代码差异 | 完成代码编写需要审查时 |
| /review | 全面代码审查 | PR 提交前做最终检查时 |
```

## Examples

### Example 1: Java Spring Boot Project

**Input:** User opens project with `pom.xml`, Spring Boot starter dependencies.

**Project fingerprint:** `java, spring-boot, maven`

**Recommended Skills (top 5):**
| # | 名称 | 描述 | 匹配理由 | 来源 |
|---|------|------|---------|------|
| 1 | `springboot-patterns` | Spring Boot 开发模式 | Spring Boot 框架直接匹配 | community |
| 2 | `java-pro` | Java 专业开发 | Java 语言匹配 | community |
| 3 | `springboot-tdd` | TDD 开发流程 | Spring Boot + 测试匹配 | community |
| 4 | `springboot-security` | Spring Boot 安全 | Spring Boot 框架匹配 | community |
| 5 | `git-workflow` | Git 工作流 | 通用开发技能 | community |

**Recommended Plugins:**
| # | 名称 | 描述 | 匹配理由 | 类型 |
|---|------|------|---------|------|
| 1 | `plugin:github:github` | GitHub PR/Issue 管理 | 通用开发插件 | MCP |
| 2 | `plugin:context7:context7` | 文档查询 | 查阅 Spring Boot 文档 | MCP |

*After user selects both plugins, Step 5 would show their available commands (e.g., `mcp__github__create_pull_request`, `mcp__context7__query-docs`) plus relevant slash commands (`/commit`, `/code-review`, `/create-pr`).*

### Example 2: React + Vite Frontend Project

**Input:** User opens project with `package.json` (react, vite deps) and `vite.config.ts`.

**Project fingerprint:** `javascript/typescript, react, vite, nodejs`

**Recommended Skills (top 5):**
| # | 名称 | 描述 | 匹配理由 | 来源 |
|---|------|------|---------|------|
| 1 | `react-best-practices` | React 最佳实践 | React 框架直接匹配 | community |
| 2 | `frontend-patterns` | 前端开发模式 | 前端领域匹配 | community |
| 3 | `javascript-pro` | JS 专业开发 | JavaScript 语言匹配 | community |
| 4 | `vite-patterns` | Vite 构建模式 | Vite 工具匹配 | community |
| 5 | `ui-ux-designer` | UI/UX 设计 | 前端领域相关 | community |

**Recommended Plugins:**
| # | 名称 | 描述 | 匹配理由 | 类型 |
|---|------|------|---------|------|
| 1 | `plugin:playwright:playwright` | 浏览器自动化测试 | 前端 E2E 测试 | MCP |
| 2 | `plugin:github:github` | PR 管理 | 通用开发插件 | MCP |

*After user selects, Step 5 shows: `mcp__github__search_code`, `mcp__github__create_pull_request` plus slash commands `/frontend-design`, `/code-review`, `/commit`.*

### Example 3: Unknown/Empty Project

**Input:** Empty or unrecognized directory structure.

**Behavior:**
- Display: "🆕 未检测到已知项目类型。以下是通用推荐："
- Skills: `git-workflow`, `code-review`, `commit`, `file-organizer`
- Plugins: `plugin:github:github` (PR/Issue), `plugin:longhand:longhand` (session 记忆)
- Selected commands (Step 5): `/commit`（提交代码时）、`/code-review`（审查代码时）、`/discover`（重新发现时）
- Offer: "如需查看所有已安装的能力，我可以为您导出完整列表。"

## Customization & Extension

### Custom Discovery Rules

Users can create `~/.claude/skills/.discovery-rules.json` to customize matching:

```json
{
  "always_recommend": ["git-workflow", "code-review"],
  "never_recommend": ["some-skill-name"],
  "always_recommend_plugins": ["plugin:github:github"],
  "never_recommend_plugins": ["some-plugin-name"],
  "always_show_commands": ["/commit", "/code-review"],
  "never_show_commands": ["/some-command"],
  "priority_boost_plugins": [
    "everything-claude-code",
    "superpowers",
    "andrej-karpathy-skills"
  ],
  "deep_explore_plugins": [
    "everything-claude-code",
    "superpowers",
    "andrej-karpathy-skills",
    "oh-my-claudecode"
  ],
  "deep_explore_patterns": [
    "SOUL.md",
    "RULES.md",
    "AGENTS.md",
    "CLAUDE.md",
    "COMMANDS-QUICK-REF.md",
    ".cursor/rules/*.mdc"
  ],
  "category_weights": {
    "dev": 3,
    "ops": 1,
    "meta": 0
  },
  "export_defaults": {
    "language": "zh",
    "format": "markdown"
  }
}
```

- `priority_boost_plugins` — 这些插件存在时自动获得 +10 优先推荐分
- `deep_explore_plugins` — 对这些插件目录执行深度探索
- `deep_explore_patterns` — 深度探索时查找的文件名模式
- `always_recommend` / `never_recommend` — 技能白名单/黑名单
- `always_recommend_plugins` / `never_recommend_plugins` — 插件白名单/黑名单
- `always_show_commands` / `never_show_commands` — 命令白名单/黑名单

### Future Skill & Plugin Sources

The scanning logic in Step 2 is designed to be extensible. When new sources emerge (marketplace APIs, team-shared repositories, remote registries, OCI artifacts), extend Step 2 by:
1. Adding the new source URL/endpoint to scan targets
2. Following the same metadata extraction pattern (name, description, tags, category, source)
3. Appending discovered items to the combined recommendation pool

## Critical Rules

1. **Correct order** — Step 1→2→3→4 (recommend, ask user) → Step 5 (only after selection, show commands) → Step 6 (export) → Step 7 (persist)
2. **Step 2c deep exploration is REQUIRED** — always deep-scan ECC/superpowers/andrej-karpathy for SOUL.md, RULES.md, AGENTS.md, nested skills, and other unindexed resources
3. **Priority boost** — ECC, superpowers, andrej-karpathy-skills always get ⭐ top placement with their unindexed resources listed
4. **Step 5 commands come AFTER selection** — never show MCP tools or slash commands in Step 4's initial recommendation
5. **Each command MUST include "作用" and "适用场景"** — describe what it does and when to use it
6. **Step 4 is MANDATORY** — always ask user after displaying recommendations
7. **Step 6 requires consent** — always ask before exporting
8. **Respect "skip"** — don't re-recommend in the same session unless project context changes
9. **Be concise** — show top 5-10 matches; offer "show more" option; never dump 100+ entries at once
