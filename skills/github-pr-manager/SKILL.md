---
name: github-pr-manager
description: >
  GitHub PR 全功能管理器 — 指定仓库、列出 PR、查看详情和 diff、查看评论和审查状态、
  查看提交历史、克隆 PR 代码到本地 owner/repo-pr-N 目录并自动初始化开发环境，支持多仓库切换
  和批量操作。当你需要管理 GitHub 拉取请求、克隆 PR、查看代码审查、检查 PR 提交、
  批量处理多个 PR、或者任何与 GitHub pull request 相关的操作时使用此技能 — 即使用户
  没有明确说"PR 管理"，只要涉及 GitHub 仓库的拉取请求就应触发。
metadata:
  compatibility: "需要 gh (GitHub CLI ≥ 2.0.0), git, jq"
---

# GitHub PR 管理器

管理任意 GitHub 仓库的 Pull Request：列出、查看详情/diff/评论/提交、克隆到本地、批量操作。

## 核心理念

本技能让你像操作本地 git 分支一样操作远程 PR。每个 PR 被克隆到独立目录 `<owner>-<repo>-pr-<编号>`，
互不干扰，多仓库并行管理时目录不会混淆。

## 前置条件

- `gh` (GitHub CLI ≥ 2.0.0)：`gh auth status` 确认已登录
- `git`、`jq`（用于 JSON 格式化，缺失时回退到原始输出）

## 核心工作流

### 1. 设定仓库

用户必须以 `owner/repo` 格式指定仓库。如果用户没有提供，主动询问：

> "请提供 GitHub 仓库（格式：owner/repo，例如 facebook/react）"

支持 `/set-repo owner/repo` 切换仓库。多仓库场景下，记住最近使用过的仓库列表。

设定仓库后，**自动执行 `/list-pr` 展示当前所有开放 PR。**

### 2. 列出 PR

```bash
gh pr list --repo <repo> --state open --json number,title,author,headRefName,createdAt,labels --limit 50
```

展示为清晰的表格：

```
📋 仓库: owner/repo | 开放 PR 列表
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #1234  feat: add new button component    @john_doe   🏷 enhancement  2天前
  #1235  fix: resolve memory leak          @jane_dev   🐛 bug         5小时前
  #1236  docs: update API reference        @dev_sam    📖 docs        1周前
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
共 3 个开放 PR
```

**用户可选操作（对话式，无需记忆命令）：**
- 输入 PR 编号（如 `1234`）→ 查看该 PR 完整信息（详情 + diff + 评论 + 提交）
- `c <编号>` → 克隆 PR 并初始化开发环境
- `d <编号>` → 仅查看 PR 详情
- `diff <编号>` → 查看 PR 代码变更摘要
- `comments <编号>` → 查看 PR 评论和审查状态
- `commits <编号>` → 查看 PR 提交历史
- `batch clone <编号1>,<编号2>,...` → 批量克隆多个 PR
- `r` → 刷新列表
- `repo <owner/repo>` → 切换仓库

### 3. PR 完整信息（默认行为）

当用户输入 PR 编号时，一次性展示：

#### 3a. 基本信息

```bash
gh pr view <编号> --repo <repo> --json title,body,author,state,mergeable,changedFiles,commits,url,headRefName,baseRefName,createdAt,labels
```

#### 3b. 代码变更 (diff)

```bash
gh pr diff <编号> --repo <repo> | head -200
```

展示变更文件列表和关键差异（截断到 200 行，提示用户可查看完整 diff）。

#### 3c. 评论和审查

```bash
gh pr view <编号> --repo <repo> --json reviews,comments
```

展示审查状态（APPROVED/CHANGES_REQUESTED/COMMENTED）和最新评论摘要。

#### 3d. 提交历史

```bash
gh pr view <编号> --repo <repo> --json commits --jq '.commits[] | "\(.oid[:7]) \(.author.name) \(.messageHeadline)"'
```

展示提交者、简短 hash 和提交信息。

### 4. 克隆 PR 到本地

```bash
# 参见 scripts/clone_pr.sh — 完整的克隆和初始化流程
```

流程：
1. 检查 `<owner>-<repo>-pr-<编号>` 是否已存在 → 存在则询问覆盖/跳过
2. 执行 `gh pr checkout <编号> --repo <repo>` 或手动 fetch + checkout
3. 展示克隆结果：路径、分支、大小
4. 检测项目类型并引导初始化：
   - **Node.js** (`package.json`) → 询问是否 `npm install`
   - **Python** (`requirements.txt`/`pyproject.toml`) → 询问是否创建 venv
   - **Rust** (`Cargo.toml`) → 询问是否 `cargo build`
   - **其他** → 提示手动初始化

### 5. 批量操作

**批量克隆：** `batch clone 1234,1235,1236`

对每个 PR 依次执行克隆流程，汇总展示结果：

```
🚀 批量克隆 3 个 PR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ #1234 → ./facebook-react-pr-1234  (Node.js, 已 npm install)
✅ #1235 → ./facebook-react-pr-1235  (Python, 已创建 venv)
❌ #1236 → 目录已存在，跳过
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**批量查看：** `batch view 1234,1235,1236` — 依次展示每个 PR 的摘要信息。

## 命令速查

| 输入 | 说明 |
|------|------|
| `<编号>` | 查看 PR 完整信息（默认行为） |
| `/set-repo <owner/repo>` | 设置/切换仓库 |
| `c <编号>` | 克隆 PR 并初始化 |
| `d <编号>` | 仅查看详情 |
| `diff <编号>` | 查看代码变更 |
| `comments <编号>` | 查看评论和审查 |
| `commits <编号>` | 查看提交历史 |
| `batch clone <n1>,<n2>` | 批量克隆 |
| `batch view <n1>,<n2>` | 批量查看 |
| `r` | 刷新 PR 列表 |
| `repo <owner/repo>` | 切换仓库 |

## 脚本

- `scripts/list_prs.sh` — 列出仓库开放 PR（JSON → 格式化表格，支持 `-a` 翻页）
- `scripts/view_pr.sh` — 获取 PR 完整信息（详情+diff+评论+提交，支持 `-d`/`-v`/`-a`）
- `scripts/clone_pr.sh` — 克隆 PR 并检测项目类型，支持多语言自动初始化
- `scripts/ci_pr.sh` — 查看 CI 状态，分析失败原因，重跑失败 Job（`--analyze`/`--rerun`/`--wait`）

## 详细参考

- `references/workflows.md` — 完整工作流细节、示例对话、多仓库管理
- `references/error-handling.md` — 所有错误场景及处理方式
