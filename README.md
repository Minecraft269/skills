# Minecraft269 Skills

Minecraft269 的 Claude Code 技能合集，想到什么就创建什么，也欢迎社区贡献。

## 技能联动

完整安装本插件包后，七个技能会自动发现彼此并在关键工作流节点联动：

- **Git 提交助手** — 提交完成后有 GitHub remote 时提示 PR 管理，涉及代码时提示审查
- **环境自检** — 发现缺失工具时引导安装，环境就绪后触发技能发现
- **项目启动** — 识别技术栈后提示安装相关 MCP Server，生成 CLAUDE.md 后触发技能发现
- **技能发现** — 检测 GitHub 项目时推荐 PR 管理器，发现缺失插件时引导安装
- **PR 管理器** — 克隆 PR 后提醒新贡献者使用项目启动流程，检测新项目类型时触发技能发现
- **PR 审查器** — 与 PR 管理器共享上下文，审查完成后提示相关操作
- **插件安装器** — 安装完成后自动提示运行技能发现

> 💡 如果你单独安装了某个技能（而非完整插件包），联动功能会自动静默关闭，核心功能不受影响。

---

## 安装

### 方式一：Marketplace 安装（推荐）

```bash
# 1. 注册 marketplace
claude plugins marketplace add Minecraft269/skills

# 2. 安装插件
claude plugins install minecraft269-skills
```

安装完成后重启 Claude Code 即可。

重启后，输入以下命令确认安装成功：

```bash
claude plugins list                 # 确认 minecraft269-skills 在列表中
/discover                            # 运行技能发现（自动扫描项目并推荐匹配技能）
```

### 方式二：手动安装

适合离线环境或希望直接管理的用户。

```bash
# 1. 克隆仓库
git clone https://github.com/Minecraft269/skills.git

# 2. 复制到 Claude Code plugins 目录
cp -r skills ~/.claude/plugins/minecraft269-skills
```

然后重启 Claude Code，插件即会自动加载。

---

## 技能列表

| 技能 | 简介 |
|------|------|
| [`github-pr-manager`](docs/github-pr-manager.md) | GitHub PR 全功能管理器：列出、查看、克隆、分析 PR |
| [`proactive-skill-discovery`](docs/proactive-skill-discovery.md) | 主动技能发现引擎：扫描项目、推荐匹配的技能和插件 |
| [`universal-project-kickoff`](docs/universal-project-kickoff.md) | 通用项目快速启动：六步流程帮你 15 分钟完成关键决策 |
| [`quick-plugin-installer`](docs/quick-plugin-installer.md) | 快速安装插件：MCP Server 和 SKILL 的统一安装入口 |
| [`github-pr-reviewer`](docs/github-pr-reviewer.md) | GitHub PR 代码审查器：逐行 inline 评论，完整 pending review 工作流 |
| [`git-commit-helper`](docs/git-commit-helper.md) | Git 提交规范化助手：基于 staged diff 自动生成 Conventional Commits 消息 |
| [`env-health-check`](docs/env-health-check.md) | 跨平台环境自检：检测 git/gh/jq/claude 可用性，输出健康报告 |

---

## 许可证

MIT License — 详见 [LICENSE](LICENSE)
