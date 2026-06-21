# github-pr-reviewer — GitHub PR 代码审查器

在 GitHub Pull Request 上执行代码审查，使用 GitHub MCP 工具创建 **逐行 inline 审查评论**。

## 功能

- ✅ 自动拉取 PR diff 和上下文（文件列表、已有审查、评论）
- ✅ 按 P0-P5 优先级分析代码变更
- ✅ 创建 pending review → 逐行 inline 评论 → 提交审查结论
- ✅ 支持 APPROVE / REQUEST_CHANGES / COMMENT 三种审查结论
- ✅ 与 github-pr-manager 上下文联动
- ✅ MCP 不可用时自动降级到 `gh` CLI
- ✅ 审查结果标注审查模型

## 前置依赖

- GitHub MCP Server（`plugin:github:github`）
- `gh` CLI（可选，降级方案）

## 用法

```
review #5                          # 审查当前仓库的 PR #5
review owner/repo #123             # 审查指定仓库的 PR
review --thorough                  # 全面审查（含 P3-P5 建议）
review --summary-only              # 仅输出审查摘要，不发布
```

## 三阶段工作流

```
阶段 0: 识别 PR → 阶段 1: 拉取 diff + 上下文 → 阶段 2: 逐行 inline 评论 → 阶段 3: 提交审查
```

审查预览会完整展示每条评论的内容、代码上下文，用户确认后才发布到 GitHub。

## 与现有审查技能的区别

| 特性 | github-pr-reviewer | code-review | pr-review-toolkit |
|------|-------------------|-------------|-------------------|
| inline 评论（add_comment_to_pending_review） | ✅ | ❌ | ❌ |
| 完整 pending review 生命周期 | ✅ | ❌ | ❌ |
| 用户审核后发布 | ✅ | ❌ | ❌ |
| 审查模型标注 | ✅ | ❌ | ❌ |
| diff 代码上下文展示 | ✅ | 部分 | 部分 |
