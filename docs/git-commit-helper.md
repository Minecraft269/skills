# git-commit-helper

基于 `git diff --staged` 分析变更，自动生成符合 [Conventional Commits](https://www.conventionalcommits.org/) 规范的提交信息。

## 前置条件

- `git`

## 触发方式

直接说「帮我提交代码」「生成 commit message」「提交变更」即可触发。

## 工作流

1. 检测暂存区（`git status --short`）
2. 分析 `git diff --staged` 推断类型（feat/fix/docs 等）和 scope
3. 预览生成的 commit message，等待确认
4. 执行 `git commit` 并联动 PR 管理/审查

## 交互选项

| 选项 | 动作 |
|------|------|
| ✅ 确认 | 直接提交 |
| ✏️ 编辑 | 修改 type/scope/描述 |
| 🔄 重试 | 重新分析 |
| 📝 手写 | 完全手写 |
| ❌ 取消 | 不提交 |

## 联动

- 提交完成后，有 GitHub remote 时提示 **PR 管理**
- 涉及代码变更时提示 **代码审查**
