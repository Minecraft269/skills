---
name: git-commit-helper
description: >
  Git 提交规范化助手 — 基于 staged diff 自动分析变更类型，生成符合 Conventional Commits
  规范的提交信息。当你需要提交代码、编写规范的 commit message、整理 git 暂存区、
  或不确定 commit 怎么写时使用此技能。
capabilities: ["git-commit"]
integrates_with: ["pr-management", "code-review"]
metadata:
  compatibility: "需要 git"
---

# Git 提交规范化助手

基于 staged diff 智能分析变更，生成符合 [Conventional Commits](https://www.conventionalcommits.org/) 规范的提交信息。纯 AI 驱动，无需额外脚本依赖。

## 包联动

1. Glob 搜索 `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. 若找到 → `PACKAGE_MODE = true`，可发现并联动兄弟技能
3. 若未找到 → `PACKAGE_MODE = false`，跳过所有跨技能逻辑（静默降级）

当 `PACKAGE_MODE = true` 时：
- 提交完成后可联动 `integrates_with: pr-management`（PR 管理）
- 提交完成后可联动 `integrates_with: code-review`（代码审查）
- 扫描兄弟 SKILL.md 的 `capabilities` 字段做交集匹配

详见 `_shared/package-context.md`。

## 核心工作流

### 1. 检测暂存状态

```bash
git status --short
git diff --staged --stat
git diff --staged
```

首先检查暂存区是否有变更。如果没有，提示用户：

```markdown
📭 暂存区为空。请先使用 `git add <文件>` 将要提交的变更添加到暂存区。

当前工作区变更（unstaged）：
<git status --short 的输出>

是否需要我帮你整理暂存区？
```

### 2. 分析变更生成消息

基于 `git diff --staged` 的内容分析变更，生成 Conventional Commits 格式的提交信息。

**分析维度：**
- **类型推断**：根据变更性质确定 type
- **scope 提取**：从变更文件路径中提取影响范围
- **主体编写**：一句话描述核心变更 + 可选的多行要点

**类型推断规则：**

| 类型 | 判断依据 |
|------|---------|
| `feat` | 新增功能、新文件、新 API 端点、新组件 |
| `fix` | 修复 bug、修正逻辑错误、修复空指针/空值 |
| `docs` | 仅修改文档（`*.md`、注释、README） |
| `style` | 格式化、空格、分号等不影响代码逻辑的调整 |
| `refactor` | 重构（既无新功能也不修 bug，但改动代码结构） |
| `perf` | 性能优化（减少循环、缓存、算法改进） |
| `test` | 添加或修改测试 |
| `chore` | 构建配置、依赖更新、CI/CD、`.gitignore` 等杂务 |
| `ci` | CI/CD 流水线变更 |
| `build` | 构建系统或外部依赖变更 |

**scope 提取规则：**
- 从变更文件路径中提取共同前缀（如 `skills/github-pr-manager` → `github-pr-manager`）
- 单文件变更：用文件名作为 scope
- 多模块变更：用最高频路径或 `multiple`
- 无明确 scope 时可省略

**生成格式：**
```
<type>(<scope>): <简短描述>

<详细说明（可选，多行要点）>

BREAKING CHANGE: <破坏性变更说明（如有）>
```

**示例输出：**
```
feat(git-commit-helper): 添加基于 staged diff 的提交信息自动生成

- 自动分析变更类型推断 type 和 scope
- 支持 Conventional Commits 规范
- 提交前交互式预览和编辑
- 提交后联动 PR 管理和代码审查
```

### 3. 预览与确认

生成消息后，以完整格式化预览展示给用户：

```markdown
## 📝 提交预览

```
feat(git-commit-helper): 添加基于 staged diff 的提交信息自动生成

- 自动分析变更类型推断 type 和 scope
- 支持 Conventional Commits 规范
- 提交前交互式预览和编辑
```

| 项目 | 详情 |
|------|------|
| 📂 变更文件 | N 个 |
| 🏷️ 类型 | feat |
| 🎯 scope | git-commit-helper |
| 📏 行数 | +X / -Y |

---

请选择：
1. ✅ **确认提交** — 直接执行 `git commit`
2. ✏️ **编辑修改** — 修改 type / scope / 描述
3. 🔄 **重新生成** — 换用另一种角度重新分析
4. 📝 **手动输入** — 你自己手写 commit message
5. ❌ **取消** — 不做任何操作
```

**重要：必须等待用户选择后才执行下一步。**

### 4. 执行提交并联动

**确认后执行：**
```bash
git commit -m "<消息>"
```

**提交成功后联动（仅 PACKAGE_MODE = true 时）：**

检查是否有 GitHub remote：
```bash
git remote get-url origin 2>/dev/null
```

- 如果有 GitHub remote → 提示：`💡 变更已提交。是否需要推送并创建 PR？`（匹配 `pr-management`）
- 如果涉及功能性代码变更 → 提示：`💡 是否需要在推送 PR 前运行代码审查？`（匹配 `code-review`）

## Conventional Commits 规范速查

### 格式
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 类型速查
- `feat` — 新功能
- `fix` — Bug 修复
- `docs` — 文档
- `style` — 格式调整（不影响代码逻辑）
- `refactor` — 重构
- `perf` — 性能优化
- `test` — 测试
- `chore` — 构建/工具/依赖
- `ci` — CI/CD
- `build` — 构建系统

### Breaking Change
- 正文末尾或 footer 中以 `BREAKING CHANGE:` 开头
- 或在 type/scope 后追加 `!`：`feat(api)!: 重新设计用户接口`

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| 暂存区为空 | 显示 unstaged 变更，提示用户 `git add` |
| 不在 git 仓库中 | 提示初始化 `git init` 或切换到仓库目录 |
| diff 过大（>500 行） | 截取前 500 行分析，标注「仅分析前 500 行」 |
| 变更类型难以判断 | 列出 2-3 个可能类型，让用户选择 |
| `git commit` 失败 | 显示错误信息，提供重试或手动输入 |
| pre-commit hook 失败 | 显示 hook 输出，提示修复后重试 |
