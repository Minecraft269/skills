# Changelog

本文件记录 Minecraft269-skills 插件包的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] — 2026-06-21

### 新增
- `github-pr-manager` — GitHub PR 全功能管理器（列出、查看、克隆、分析 PR）
- `proactive-skill-discovery` — 主动技能发现引擎（7 步工作流，项目识别→推荐→导出）
- `universal-project-kickoff` — 通用项目快速启动（六步强制流程，15 分钟关键决策）
- `quick-plugin-installer` — 快速插件安装器（MCP Server + SKILL 统一入口）
- `github-pr-reviewer` — GitHub PR 代码审查器（逐行 inline 评论，完整 pending review 工作流）
- PACKAGE_MODE 联动框架：包上下文检测协议 + 动态能力发现
- 循环触发防护机制
- CI/CD 自动检查工作流（frontmatter 验证 + ShellCheck + 文档链接验证）
- `.github/` Issue/PR 模板
- `SECURITY.md` 安全策略

### 变更
- 无（初始版本）

## [4.0.0] — 2026-07-05

### 新增
- `universal-project-kickoff` 新增 🍴 Fork 模式（5 步子程序：获取仓库 → Fork → Clone → 项目分析 → 贡献工作流引导）
- 新增 `fork-workflow` 能力标签

### 变更
- `universal-project-kickoff` 版本 3.0.0 → 4.0.0
- `plugin.json` / `marketplace.json` 描述更新

### 移除
- 删除已废弃的 `proactive-skill-discovery` 技能目录及文档
- 将残留引用转为历史说明和迁移指南（CLAUDE.md 项目结构树标注"已吸收"、scanner-patterns.md/hook-config.md 保留合并迁移说明）
