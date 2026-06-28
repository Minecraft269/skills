---
name: proactive-skill-discovery
description: "⚠️ 已废弃 — 本技能已合并至 universal-project-kickoff。请使用 universal-project-kickoff 代替。"
category: meta
risk: safe
source: community
tags: "[deprecated, migrated]"
capabilities: []
integrates_with: []
---

# ⚠️ 已废弃

本技能已合并至 **[universal-project-kickoff](../universal-project-kickoff/SKILL.md)**。

## 迁移说明

`proactive-skill-discovery` 的全部能力（项目指纹扫描、能力扫描、匹配评分、交互推荐、命令发现、全量导出）已合并到 `universal-project-kickoff` 中。

合并后的技能提供统一的入口：
- 先探测你的意图（启动项目 / 开发功能 / 审查代码 / 修复 Bug / 探索工具）
- 再根据意图和技术栈推荐匹配的技能和插件
- 如果是启动新项目，还会执行完整的六步启动检查流程

请直接使用 **universal-project-kickoff**，无需额外操作。所有联动标签（`skill-discovery`、`capability-scanning`、`project-analysis`）已由合并技能继承，其他技能无需修改。
