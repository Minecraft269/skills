# quick-plugin-installer

快速安装插件 — 统一入口，一键完成 Claude Code 插件（MCP Server 和 SKILL 插件）的发现、注册、安装、自动升级配置。

## 核心功能

- 自动识别插件类型（MCP Server vs SKILL 插件 vs 本地目录）
- 已有安装检测 → 交互式操作（重装/更新/卸载/查看/跳过）
- Marketplace 注册 + 安装 + 自动升级配置
- MCP Server 配置生成、写入、接入验证
- MCP 更新检查脚本（npm/本地命令）
- 16 个 MCP 配置模板（GitHub/Context7/Playwright/Postgres/Jira/Slack...）
- 跨平台兼容（Linux/macOS/Windows Git Bash）

## 六步工作流

| 步骤 | 说明 |
|------|------|
| 1. 识别类型 | MCP / SKILL / 本地，无法判断时交互询问 |
| 2. 已有检测 | 检查是否已安装，询问下一步操作 |
| 3. SKILL 安装 | Marketplace 注册 → 安装 → autoUpdate |
| 4. MCP 安装 | 收集配置 → 写入 settings.json → 验证 |
| 5. 输出摘要 | 格式化展示安装结果 |
| 6. 快速模板 | 16 个常用 MCP Server 一键配置 |

## 前置依赖

- `gh` (GitHub CLI)
- `jq`
- `claude` CLI

## 相关技能

本技能属于 [minecraft269-skills](https://github.com/Minecraft269/skills) 插件包。当完整安装插件包时，本技能可与其他包内技能自动联动：

- 安装完成后自动提示运行技能发现
- 被主动技能发现引擎引导，安装用户选择的缺失能力

独立安装本技能时，上述联动功能静默关闭，不影响核心安装功能。

