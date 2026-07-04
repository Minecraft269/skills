# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定义

为使用 Claude Code 的开发者解决跨项目复用技能和主动发现工具的痛点，通过持续创作和维护高质量 Claude Code 技能并通过 Marketplace 分发。想到什么就创建什么，也欢迎社区贡献。不设禁区，但在创建涉及外部 API、付费服务、敏感操作的技能时需在 frontmatter 中声明。

## 项目结构

```
.claude-plugin/                  # 插件清单 + Marketplace 注册
├── plugin.json
└── marketplace.json
.github/                          # CI/CD 配置
└── workflows/
    └── skill-health.yml          # Frontmatter 格式校验 + 标签一致性检查
docs/                            # 技能详细文档（README 链接指向此处），每技能一份
skills/                          # 所有技能（每个子目录一个技能）
├── _shared/                      # 包级共享资源（检测协议、通用模板）
├── universal-project-kickoff/   # 通用项目启动与能力发现（已合并 proactive-skill-discovery）
│   └── references/               # 6 份参考文件（含 scanner、language、hook-config、validation）
├── github-pr-manager/           # GitHub PR 全功能管理器
├── github-pr-reviewer/          # GitHub PR 审查器（逐行 inline 评论）
├── quick-plugin-installer/      # 快速安装插件（MCP + SKILL）
├── git-commit-helper/           # Git 提交规范化助手（Conventional Commits）
├── env-health-check/            # 跨平台环境自检
└── proactive-skill-discovery/   # ⚠️ 已废弃（仅 SKILL.md 存根，references 已清空）
CONTRIBUTING.md                  # 贡献指南（含能力标签注册表 + 标签决策树）
```

## 创建新技能

**必须使用 `/skill-creator` 创建新技能。** 使用前确认已安装 skill-creator 插件。

创建完成后将技能目录放入 `skills/<skill-name>/`，每个技能至少包含一个 `SKILL.md`（YAML frontmatter + Markdown 正文）。同步在 `docs/<skill-name>.md` 创建技能文档。

## 代码风格

- 缩进：2 空格（与 skill-creator 生成的标准一致）
- 注释：头部写用途和用法，关键逻辑写注释，自解释代码不写
- 技能目录命名：`kebab-case`（如 `github-pr-manager`）
- frontmatter `name`：与目录名一致
- frontmatter `version`：技能版本号，推荐 SemVer（如 `"2.0.0"`），用于追踪重大变更
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
| M4 — 能力合并 | ✅ 完成 | proactive-skill-discovery 合并入 universal-project-kickoff（统一入口，技能数 7→6） |
| M5 — 质量审查 | ✅ 完成 | universal-project-kickoff 12 项增强：迁移残留清理、配置系统、架构修复、检测扩展、质量体系 |

## 本地验证

提交前运行以下命令确保通过 CI：

```bash
# Shell 语法检查
find skills/ -name "*.sh" -exec bash -n {} \;

# 手动验证标签一致性（CI 自动执行）
grep -oP 'capabilities:\s*\[\K[^\]]+' skills/*/SKILL.md | tr '"' '\n' | sort -u
# 对比 CONTRIBUTING.md 中的标签注册表
```

## 发布流程

```bash
# 1. 本地验证：frontmatter 完整性 + 标签一致性 + ShellCheck
find skills/<name>/ -name "*.sh" -exec bash -n {} \;
grep -oP 'capabilities:\s*\[\K[^\]]+' skills/*/SKILL.md | tr '"' '\n' | sort -u

# 2. 提交推送（需同步修改 4 处文件，见「新技能注册清单」）
git add skills/<name>/ docs/<name>.md CONTRIBUTING.md README.md
git commit -m "feat: add <name> skill"
git push

# 3. 推送到 GitHub 后 Marketplace 自动同步
```

## 前置依赖

安装此插件的用户需要：
- Claude Code CLI
- 各技能声明的前置工具（如 `gh`、`git`、`jq`）

## 开发注意事项

- `.git/info/exclude` — 个人本地目录（`.omc/`、`.remember/`、`.impeccable/`）放这里，不提交到 `.gitignore`
- worktree 提交 — 如 `EnterWorktree` 创建的 worktree 中 git 命令不可用（`not a git repository`），使用 `GIT_DIR=../.git GIT_WORK_TREE=<path> git ...` 变通
- 推送后本地同步 — 通过 worktree 提交推送后，主仓库工作树会脱节，执行 `git restore .` 同步
- 不写 `Co-Authored-By` 尾部

## 新技能注册清单

创建新技能需同步修改 4 处：

1. `skills/<name>/SKILL.md` — 技能定义（~150 行，含 frontmatter + 包联动 + 核心工作流 + 错误处理）
2. `CONTRIBUTING.md` — 在「能力标签注册表」表格末尾注册新能力标签
3. `README.md` — 在末尾「技能列表」表格（许可证前面）添加一行
4. `docs/<name>.md` — 精简文档（~40 行，简介 + 前置条件 + 触发方式 + 工作流 + 交互选项）

纯 AI 驱动技能无需 `scripts/` 目录和 `references/` 目录。

## CI 注意事项

- `ludeeus/action-shellcheck@master` 遇 warning 即失败，所有 `*.sh` 必须 `bash -n` + ShellCheck 零 warning
- CI 会验证 CONTRIBUTING.md 标签注册表与所有 `skills/*/SKILL.md` 的 `capabilities` 字段一致性
