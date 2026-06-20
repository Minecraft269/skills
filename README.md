# Minecraft269 Skills

Minecraft269 的 Claude Code 技能合集，包含三个实用技能，提升 Claude Code 在日常开发中的工作效率。

## 技能列表

| 技能 | 简介 | 文档 |
|------|------|------|
| `github-pr-manager` | GitHub PR 全功能管理器：列出、查看、克隆、分析 PR | [→](docs/github-pr-manager.md) |
| `proactive-skill-discovery` | 主动技能发现引擎：扫描项目、推荐匹配的技能和插件 | [→](docs/proactive-skill-discovery.md) |
| `universal-project-kickoff` | 通用项目快速启动：六步流程帮你 15 分钟完成关键决策 | [→](docs/universal-project-kickoff.md) |
| `quick-plugin-installer` | 快速安装插件：MCP Server 和 SKILL 的统一安装入口 | [→](docs/quick-plugin-installer.md) |

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

## 许可证

MIT License — 详见 [LICENSE](LICENSE)
