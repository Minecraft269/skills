---
name: github-pr-reviewer
description: >
  GitHub PR 代码审查器 — 使用 GitHub MCP 工具在 PR 上创建逐行 inline 审查评论。
  自动拉取 PR diff、分析代码变更、创建 pending review、逐行添加 inline 评论、
  提交审查结论（APPROVE/REQUEST_CHANGES/COMMENT）。
  当你需要审查 PR、检查代码质量、review 代码、或对 PR 提出具体行级建议时使用此技能。
  即使用户只说「帮我 review 这个 PR」或「看看这个代码有什么问题」也应触发。
capabilities: ["pr-review", "code-review", "inline-comments"]
integrates_with: ["pr-management", "skill-discovery"]
metadata:
  compatibility: "需要 GitHub MCP Server（plugin:github:github）"
  risk: safe
---

# GitHub PR 审查器

在 GitHub Pull Request 上执行代码审查，使用 GitHub MCP 工具创建 **逐行 inline 评论**——这是本技能与现有审查技能的核心区别。

## 前置条件

- **必须**：GitHub MCP Server（`plugin:github:github`）已配置并连接
- **可选降级**：`gh` CLI（≥ 2.0.0）— 当 MCP 不可用时作为降级方案

启动时先验证 MCP 工具可用性：

```
方法：尝试调用 pull_request_read 获取任意公开 PR 的元信息
如果失败 → 提示用户配置 GitHub MCP Server，同时启用 gh CLI 降级模式
```

## 包联动

本技能支持在 minecraft269-skills 插件包内与兄弟技能联动。

**联动钩子（仅 PACKAGE_MODE = true 时执行）：**

检测方法：
1. 搜索 `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json` 是否存在
2. 如存在 → PACKAGE_MODE = true，执行以下联动逻辑
3. 如不存在 → PACKAGE_MODE = false，跳过所有联动引用

### 阶段 0 联动：从 github-pr-manager 获取上下文

当 PACKAGE_MODE = true 且对话上下文中存在以下信号时，用户可能已通过 github-pr-manager 选中了 PR：

- 对话中最近出现了 `pull_request_read` 或 `gh pr view` 调用
- 用户输入了 PR 编号但未指定仓库
- 对话上下文中有 `owner/repo` 格式的仓库标识

**联动操作：**
```
如果检测到上述信号 → 主动询问用户：
「检测到你正在查看 [owner/repo] 的 PR #[N]。是否对此 PR 执行代码审查？」
- 如果用户确认 → 直接进入阶段 1，跳过仓库/PR 询问
- 如果用户拒绝 → 照常询问仓库和 PR 编号
```

### 审查完成后联动

审查提交后，扫描兄弟技能的 capabilities：

- 匹配 `pr-management` → 提示：「💡 可使用 **GitHub PR 管理器** 查看其他 PR 或克隆此 PR 到本地」
- 匹配 `skill-discovery` → 提示：「💡 可运行 **主动技能发现** 获取当前项目的更多工具推荐」

独立模式（PACKAGE_MODE = false）时，上述联动提示完全不显示。

---

## 三阶段审查工作流

以下三个阶段必须严格按顺序执行。每个阶段完成后才能进入下一阶段。

### 阶段 0：识别目标 PR

确定要审查的 PR 身份。按以下优先级获取：

1. **联动上下文**（PACKAGE_MODE = true）：从 github-pr-manager 的会话上下文提取仓库和 PR 编号
2. **用户直接提供**：用户说了目标仓库和 PR 编号（如「审查 Minecraft269/skills #5」）
3. **主动询问**：如果以上都不可用，询问用户：
   ```
   「请提供要审查的 PR：
   - 仓库：owner/repo
   - PR 编号：#N」
   ```

获取后立即验证 PR 存在：
```
pull_request_read(method="get", owner, repo, pullNumber)
```
如果返回错误 → 提示用户检查仓库名和 PR 编号。

### 阶段 1：获取审查上下文

在开始审查前，并行获取 PR 的完整上下文。以下四个调用可以同时进行：

```
pull_request_read(method="get_diff", owner, repo, pullNumber)
  → 获取完整 unified diff — 这是审查的核心材料

pull_request_read(method="get_files", owner, repo, pullNumber)
  → 获取变更文件列表（含每个文件的 additions/deletions/changes 统计）

pull_request_read(method="get_review_comments", owner, repo, pullNumber)
  → 获取已有 inline 审查评论 — 用于避免重复评论同一位置

pull_request_read(method="get_reviews", owner, repo, pullNumber)
  → 获取整体审查状态（已 APPROVED / CHANGES_REQUESTED / 无审查）
```

**输出：** 汇总 PR 上下文信息给用户：

| 指标 | 数值 |
|------|------|
| 变更文件 | N 个 |
| 新增行 | +M |
| 删除行 | -K |
| 已有审查 | X 条（状态） |
| 已有 inline 评论 | Y 条 |

### 阶段 2：分析代码并发布 inline 评论

这是本技能的核心价值——**逐行 inline 评论**。

#### 2a. 分析 diff，生成审查发现

根据 `references/review-checklist.md` 中的检查清单分析 diff。每条发现记录：

| 字段 | 说明 | 示例 |
|------|------|------|
| `path` | 文件相对路径 | `src/auth/login.ts` |
| `line` | **diff 中的行号**（见下方重要说明） | `42` |
| `side` | `"LEFT"`（旧代码）或 `"RIGHT"`（新代码） | `"RIGHT"` |
| `body` | 评论正文（结构化 Markdown） | 见下方模板 |
| `severity` | `critical` / `warning` / `suggestion` / `praise` | `warning` |
| `category` | `bug` / `security` / `performance` / `design` / `best-practice` / `nitpick` | `security` |

**⚠️ 行号至关重要：** `add_comment_to_pending_review` 的 `line` 参数必须使用 **PR diff 中的行号**，而非源文件行号。详见 `references/diff-line-mapping.md`。核心规则：

- Unified diff 中 `@@ -a,b +c,d @@` 标记了 hunk 位置
- 新代码（`+` 开头）的 diff 行号 ≠ 源文件行号
- 使用 `scripts/parse_diff_lines.sh` 脚本辅助提取
- 如果无法确定正确的 diff 行号，降级为文件级评论（`subjectType="FILE"`）

#### 2b. 展示完整审查预览（必须向用户展示并获得确认）

**在调用任何 GitHub API 之前**，必须将每条审查发现以完整的格式化预览展示给用户。**禁止以 MCP 工具调用参数格式展示**——用户需要看到的是最终会出现在 PR 上的完整评论内容。

审查预览格式如下：

```
## 🔍 PR 审查预览

**审查仓库：** owner/repo
**审查 PR：** #[N] — PR 标题
**审查模型：** <当前模型名称>  ← 从系统提示中提取实际模型名
**审查时间：** <当前时间>

---

### 发现 #1 — 🔒 安全 · critical

**文件：** `src/auth/login.ts`
**diff 行号：** 第 42 行（RIGHT 侧 — 新增代码）
**类别：** security
**严重程度：** critical

---

📝 **将发布的 inline 评论内容：**

当前代码在 `password` 为 `null` 或 `undefined` 时会直接传递给 `hashPassword()`，
可能导致运行时异常或不安全的哈希结果。

**建议修复：**
```typescript
if (!password) {
  throw new BadRequestError('密码不能为空');
}
const hashed = await hashPassword(password);
```

📋 **相关 diff 上下文：**
```diff
@@ -38,6 +38,8 @@ export async function login(username: string, password: string) {
   // 验证用户名
   const user = await db.findUser(username);
-  const hashed = await hashPassword(password);
-  return { id: user.id, token: generateToken(user) };
+  if (!password) {
+    throw new BadRequestError('密码不能为空');
+  }
+  const hashed = await hashPassword(password);
+  return { id: user.id, token: generateToken(user), hashed };
 }
```

---

### 发现 #2 — 🐛 Bug · critical

**文件：** `src/api/handler.ts`
**diff 行号：** 第 108 行（RIGHT 侧 — 新增代码）
**类别：** bug
**严重程度：** critical

---

📝 **将发布的 inline 评论内容：**

`processData()` 在 `result.data` 为空数组时返回 `undefined`，
而调用方未处理此情况，导致后续 `.map()` 抛出 TypeError。

**建议修复：**
```typescript
const data = processData(input) ?? [];
return data.map(item => transform(item));
```

📋 **相关 diff 上下文：**
```diff
@@ -105,3 +105,6 @@ async function handleRequest(input: RequestInput) {
   const result = await fetchData(input.query);
-  return result.data.map(item => transform(item));
+  const data = processData(input) ?? [];
+  return data.map(item => transform(item));
 }
```

---

### 发现 #3 — ⚡ 性能 · warning

...（每条发现完整展开）

---

## 📊 审查统计

| 严重程度 | 数量 |
|---------|------|
| 🔴 critical | X 条 |
| 🟡 warning | Y 条 |
| 🔵 suggestion | Z 条 |
| 🟢 praise | P 条 |
| **合计** | **N 条** |

- **覆盖文件：** F 个
- **审查模型：** <模型名>
- **默认发布：** P0-P2（共 X 条）→ 回复 `--all` 可发布全部 N 条

---

## ⏳ 等待确认

以上评论将以 **inline 评论** 形式逐条发布到 GitHub PR 的对应代码行。

你可以：
- 回复「**确认**」或「**发布**」→ 按默认范围（P0-P2）开始发布
- 回复 `--all` → 发布所有发现（含 P3-P5）
- 回复 `--select 1,3,5` → 仅发布指定编号
- 回复 `--skip 2` → 跳过指定发现
- 回复「**修改 #N**」→ 编辑第 N 条发现的评论文本
```

**重要规则：**
- 每条发现必须 **完整展开** 评论文本（问题描述 + 建议修复 + 代码示例）——用户看到的预览就是 PR 上会出现的最终内容
- 每条发现必须附带 **相关 diff 上下文**（`📋 相关 diff 上下文`），展示被评论代码的周围 diff 行（含 `@@` hunk 头部），让用户看到代码全貌
- **审查模型名称**必须从系统提示上下文中获取实际值（如 `Claude Opus 4.8`、`Claude Sonnet 4.6`），不可编造
- **必须等待用户确认**后才能进入阶段 2c
- 如果用户要求修改某条发现，修改后重新展示该条，直到用户满意

#### 2c. 创建 pending review

```
pull_request_review_write(
  method="create",
  owner, repo, pullNumber,
  body="正在审查中..."
)
```

**不传 `event` 参数** — 这创建一个待定（pending）状态的 review，后续 inline 评论将添加到这个 pending review 中。

**如果返回错误（已有 pending review）：**
- 先调用 `pull_request_review_write(method="delete_pending", ...)` 删除旧 review
- 再重新创建

#### 2d. 逐条添加 inline 评论

对每条审查发现，调用：

```
add_comment_to_pending_review(
  owner, repo, pullNumber,
  path=<文件路径>,
  body=<评论正文>,
  line=<diff 行号>,
  side=<"LEFT"|"RIGHT">,
  subjectType="LINE"
)
```

**评论正文模板：**

```
**🔒 [安全] 密码验证缺少空值检查**

当前代码在 `password` 为 `null` 或 `undefined` 时会直接传递给 `hashPassword()`，
可能导致运行时异常或不安全的哈希结果。

**建议修复：**
```typescript
if (!password) {
  throw new BadRequestError('密码不能为空');
}
const hashed = await hashPassword(password);
```
```

**类别图标映射：**

| 类别 | 图标 |
|------|------|
| bug | 🐛 |
| security | 🔒 |
| performance | ⚡ |
| design | 🏗️ |
| best-practice | 📐 |
| nitpick | 💭 |
| praise | 👍 |

**添加策略：**
- 按严重程度排序添加：critical → warning → suggestion → praise
- 每条之间轻微间隔，避免触发 GitHub API rate limit
- 如果某条添加失败（如行号无效），记录失败条目，继续添加下一条
- 对于已存在评论的位置，跳过（避免重复）

### 阶段 3：提交审查结论

#### 3a. 汇总并确认

向用户展示审查完成统计：

```
## 审查完成

| 指标 | 数值 |
|------|------|
| inline 评论 | N 条（成功）/ M 条（失败）/ K 条（跳过） |
| 覆盖文件 | F 个 |
| 严重问题 | C 条 |
| 建议 | S 条 |

请选择审查结论：
```

使用 `AskUserQuestion` 提供三个选项：
- **Approve** — 批准合并（代码质量良好，无阻塞问题）
- **Request Changes** — 要求修改（存在需要修复的严重问题）
- **Comment** — 仅提建议（中立，不阻塞合并）

#### 3b. 提交审查

```
pull_request_review_write(
  method="submit_pending",
  owner, repo, pullNumber,
  event=<用户选择>,
  body=<审查总结>
)
```

#### 3c. 输出最终结果

```
✅ 审查已提交

PR [#N](https://github.com/owner/repo/pull/N) 审查完成
- 结论：{APPROVED | CHANGES_REQUESTED | COMMENTED}
- inline 评论：N 条，覆盖 M 个文件
- 审查模型：<模型名>
```

---

## 审查焦点

详细检查清单见 `references/review-checklist.md`。审查时按优先级聚焦：

| 优先级 | 类别 | 默认行为 |
|--------|------|---------|
| P0 | 正确性缺陷 | **始终审查** |
| P1 | 安全问题 | **始终审查** |
| P2 | 性能问题 | **始终审查** |
| P3 | 设计问题 | 仅 `--thorough` 模式 |
| P4 | 最佳实践 | 仅 `--thorough` 模式 |
| P5 | 锦上添花 | 仅 `--thorough` 模式 |

---

## 错误处理与降级

### 错误场景速查

| 错误 | 原因 | 处理 |
|------|------|------|
| PR 不存在 | 编号错误或无权限 | 提示用户确认仓库和 PR 编号 |
| `add_comment_to_pending_review` 失败 | 无 pending review | 先创建 pending review，再重试 |
| `pull_request_review_write("create")` 冲突 | 已有旧 pending review | 先删除旧的，再创建新的 |
| 行号无效 | diff 行号计算错误 | 检查行号 → 重试 → 仍失败则降级为文件级评论 |
| MCP 工具调用全部失败 | GitHub MCP 未配置 | 切换到 `gh` CLI 降级模式（见下方） |
| API rate limit | 请求过多 | 等待 60s 后重试 |

### gh CLI 降级模式

当 GitHub MCP 不可用时：

```
# 替代阶段 1 — 获取 diff
gh pr diff <NUMBER> --repo <owner/repo>

# 替代阶段 2+3 — 发布审查（仅整体评论，无 inline）
gh pr review <NUMBER> --repo <owner/repo> --approve/--request-changes/--comment --body "..."
```

降级模式下无法发布 inline 评论。告知用户这一限制，并提供审查报告的 Markdown 文本供用户手动发布。

---

## 命令速查

| 用户输入 | 说明 |
|---------|------|
| `review <owner/repo> #<N>` | 审查指定仓库的指定 PR |
| `review #<N>` | 审查当前仓库的 PR（需联动上下文） |
| `review` | 审查当前 PR（需联动上下文） |
| `review --thorough` | 全面审查模式（含 P3-P5） |
| `review --summary-only` | 仅输出审查摘要，不发布到 GitHub |

## 脚本

- `scripts/parse_diff_lines.sh` — 从 unified diff 输出中提取文件路径和对应的 diff 行号。用于辅助 `add_comment_to_pending_review` 的行号参数计算。

## 参考文档

- `references/review-checklist.md` — 代码审查检查清单，按 P0-P5 优先级分层。审查时对照此清单逐项检查。
- `references/diff-line-mapping.md` — Unified diff 格式解析与行号映射技术指南。解释 PR diff 行号与源文件行号的区别，以及如何正确计算 inline 评论所需的 diff 行号。
