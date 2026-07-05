# Minecraft269 Skills

Minecraft269 的 Claude Code 技能合集，想到什么就创建什么，也欢迎社区贡献。

## 技能联动

完整安装本插件包后，六个技能会自动发现彼此并在关键工作流节点联动：

- **Git 提交助手** — 提交完成后有 GitHub remote 时提示 PR 管理，涉及代码时提示审查
- **环境自检** — 发现缺失工具时引导安装，环境就绪后触发能力发现
- **项目启动与发现** — 关键词预判用户意图（启动/开发/审查/修复/探索/Fork），意图不明确时询问；审查代码支持本地/远程 PR、在线快速审查或 clone 本地深度审查，审查前确认模型；Fork 模式支持 fork → clone → 分析 → 贡献引导五步流程；新项目执行六步启动检查流程（MVP/风险/路线图/CLAUDE.md）；已吸收原 proactive-skill-discovery 能力
- **PR 管理器** — 克隆 PR 后提醒新贡献者使用项目启动流程，检测新项目类型时触发能力发现
- **PR 审查器** — 与 PR 管理器共享上下文，审查完成后提示相关操作
- **插件安装器** — 安装完成后自动提示运行项目启动与能力发现

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
/discover                            # 运行技能发现（已合并至 universal-project-kickoff，自动扫描项目并推荐匹配技能）
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
| [`universal-project-kickoff`](docs/universal-project-kickoff.md) | 通用项目启动与能力发现：意图探测 + 目标确认 + Fork 模式（参与开源贡献）+ 7 步能力发现（深度探索/优先推荐/指令发现/全量导出/持久化）+ 六步启动流程 |
| [`github-pr-manager`](docs/github-pr-manager.md) | GitHub PR 全功能管理器：列出、查看、克隆、分析 PR |
| [`quick-plugin-installer`](docs/quick-plugin-installer.md) | 快速安装插件：MCP Server 和 SKILL 的统一安装入口 |
| [`github-pr-reviewer`](docs/github-pr-reviewer.md) | GitHub PR 代码审查器：逐行 inline 评论，完整 pending review 工作流 |
| [`git-commit-helper`](docs/git-commit-helper.md) | Git 提交规范化助手：基于 staged diff 自动生成 Conventional Commits 消息 |
| [`env-health-check`](docs/env-health-check.md) | 跨平台环境自检：检测 git/gh/jq/claude 可用性，输出健康报告 |

---

## 许可证

MIT License — 详见 [LICENSE](LICENSE)
