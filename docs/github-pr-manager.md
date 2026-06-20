# github-pr-manager

GitHub PR 全功能管理器 — 在终端中列出、查看、克隆、分析 GitHub Pull Request。

## 核心功能

- 列出仓库所有开放 PR（表格展示，支持翻页）
- 查看 PR 完整信息：详情、diff、评论、审查状态、提交历史
- 克隆 PR 到本地并自动检测项目类型（Node/Python/Rust/Go/Java）初始化环境
- CI 状态查看和失败原因分析
- 多仓库切换和批量操作

## 前置依赖

- `gh` (GitHub CLI ≥ 2.0.0)
- `git`
- `jq`

## 命令速查

| 输入 | 说明 |
|------|------|
| `<编号>` | 查看 PR 完整信息（默认行为） |
| `c <编号>` | 克隆 PR 并初始化 |
| `d <编号>` | 仅查看详情 |
| `diff <编号>` | 查看代码变更 |
| `comments <编号>` | 查看评论和审查 |
| `commits <编号>` | 查看提交历史 |
| `batch clone <n1>,<n2>` | 批量克隆 |
| `batch view <n1>,<n2>` | 批量查看 |
| `r` | 刷新 PR 列表 |
| `repo <owner/repo>` | 切换仓库 |
