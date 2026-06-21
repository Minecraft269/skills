# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定义

为使用 Claude Code 的开发者解决跨项目复用技能和主动发现工具的痛点，通过持续创作和维护高质量 Claude Code 技能并通过 Marketplace 分发。想到什么就创建什么，也欢迎社区贡献。不设禁区，但在创建涉及外部 API、付费服务、敏感操作的技能时需在 frontmatter 中声明。

## 项目结构

```
.claude-plugin/                  # 插件清单 + Marketplace 注册
├── plugin.json
└── marketplace.json
docs/                            # 技能详细文档（README 链接指向此处）
skills/                          # 所有技能（每个子目录一个技能）
├── _shared/                      # 包级共享资源（检测协议、通用模板）
├── github-pr-manager/           # GitHub PR 全功能管理器
├── proactive-skill-discovery/   # 主动技能发现引擎
├── universal-project-kickoff/   # 通用项目快速启动规则
├── quick-plugin-installer/      # 快速安装插件（MCP + SKILL）
└── github-pr-reviewer/          # GitHub PR 审查器（逐行 inline 评论）
CONTRIBUTING.md                  # 贡献指南
```

## 创建新技能

**必须使用 `/skill-creator` 创建新技能。** 使用前确认已安装 skill-creator 插件。

创建完成后将技能目录放入 `skills/<skill-name>/`，每个技能至少包含一个 `SKILL.md`（YAML frontmatter + Markdown 正文）。同步在 `docs/<skill-name>.md` 创建技能文档。

## 代码风格

- 缩进：2 空格（与 skill-creator 生成的标准一致）
- 注释：头部写用途和用法，关键逻辑写注释，自解释代码不写
- 技能目录命名：`kebab-case`（如 `github-pr-manager`）
- frontmatter `name`：与目录名一致
- frontmatter 联动字段：`capabilities`（提供的能力标签）、`integrates_with`（需要配合的能力标签）— 可选，用于包内技能动态发现
- 脚本文件：`snake_case.sh`
- 所有面向用户的内容使用中文，技术术语保留英文
- 跨技能引用必须通过 PACKAGE_MODE 检测门控，独立安装时静默降级

## 风险与预案

| 风险 | B 计划 |
|------|--------|
| 合规踩坑（License 冲突、引用未授权代码） | 每个新技能发布前做 License 审查；工具依赖统一声明 |
| Claude Code 版本升级导致技能不兼容 | 技能中写明最低兼容版本；新版发布后优先跑一遍核心路径 |
| 社区贡献失控（PR 质量参差、风格不统一） | CONTRIBUTING.md + PR 模板把关；核心技能自己审核 |

## 路线图

| 里程碑 | 状态 | 产出物 |
|--------|------|--------|
| M1 — Marketplace 可用 | ✅ 完成 | 3 个技能可安装可触发 |
| M2 — 扩展强化 | ✅ 完成 | +quick-plugin-installer、CONTRIBUTING.md、docs/ |
| M3 — 技能联动 | ✅ 完成 | 通用联动框架（capabilities/integrates_with）、包级检测门控、技能间动态发现 |

## 发布流程

```bash
# 1. 本地测试 / 命令可正常触发
git add skills/<skill-name>/
git commit -m "feat: add <skill-name> skill"
git push
# 2. 推送到 GitHub 后 Marketplace 自动同步
```

## 前置依赖

安装此插件的用户需要：
- Claude Code CLI
- 各技能声明的前置工具（如 `gh`、`git`、`jq`）
