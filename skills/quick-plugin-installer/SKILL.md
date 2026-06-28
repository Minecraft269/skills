---
name: quick-plugin-installer
description: >
  快速安装插件（MCP Server 与 SKILL 插件）— 统一入口，自动识别类型，完成注册、安装、自动升级配置、
  MCP 接入验证。当你需要安装任何 Claude Code 插件、MCP Server、SKILL 技能、或 Marketplace 来源
  的扩展时使用此技能。支持 GitHub repo、Marketplace 名称、本地路径、MCP Registry 等多种来源。
capabilities: ["plugin-installation", "mcp-setup"]
integrates_with: ["skill-discovery"]
metadata:
  compatibility: "需要 gh (GitHub CLI)、jq、claude CLI"
  risk: safe
---

# 快速安装插件

一键完成 Claude Code 插件（MCP Server 和 SKILL 插件）的发现、注册、安装、自动升级配置。

## 包联动

本技能支持与 minecraft269-skills 插件包内其他技能自动联动。执行以下检测：

1. Glob 搜索 `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. 若找到 → `PACKAGE_MODE = true`，可发现并联动兄弟技能
3. 若未找到 → `PACKAGE_MODE = false`，跳过所有跨技能逻辑（静默降级）

当 `PACKAGE_MODE = true` 时：
- 安装完成后可联动 `integrates_with: skill-discovery`（技能发现）
- 扫描兄弟 SKILL.md 的 `capabilities` 字段，匹配本技能的 `integrates_with` 标签
- 仅在匹配成功时显示联动提示

详见 `_shared/package-context.md`。

## 核心工作流

### 1. 识别插件类型

用户只需提供一个标识符，技能自动判断目标类型。

**触发方式：**
- 用户直接输入来源：`/install-plugin <来源>`
- 或自然语言：「安装 GitHub MCP」「帮我装 Minecraft269/skills」

**判断逻辑：**

| 特征 | 类型 |
|------|------|
| 来源包含 `mcp`、`server`、`MCP Server` 等关键字 | **MCP Server** |
| 来源是 GitHub 仓库格式（`owner/repo`）且描述为技能/插件集市 | **SKILL 插件（Marketplace）** |
| 来源是本地路径（`./xxx`、`/xxx`、`D:\xxx`） | **SKILL 插件（本地）** |
| 无法自动判断 | 交互式询问用户 |

**交互式询问模板：**
> "无法自动判断 `{来源}` 的类型。请选择：
> 1. SKILL 插件（来自 Marketplace 或本地目录）
> 2. MCP Server（需要在 settings.json 中配置）
> 3. 查看详情后再决定"

### 2. 已有安装检测（安装前必须执行）

在正式安装前，先检查目标是否已存在：

- **SKILL 插件**：检查 `~/.claude/plugins/<插件名>/` 目录或 `claude plugins list` 输出
- **MCP Server**：检查 `~/.claude/settings.json` 中 `mcpServers.<server-name>` 是否已存在

如果已安装，必须交互式询问用户下一步操作：

```markdown
⚠️ {插件名} 已经安装。

当前状态：
- 📛 名称: {name}
- 📂 位置: {安装路径}
- 🔢 版本: {version}（如可获取）

请选择操作：
1. 🔄 重新安装（覆盖当前版本）
2. ⬆️ 更新到最新版本
3. 🗑️ 卸载此插件
4. 📋 查看详情（安装路径、配置、依赖）
5. ✅ 跳过，保持现状
```

**执行对应操作：**

| 用户选择 | 执行 |
|---------|------|
| 重新安装 | 先卸载 → 再安装（保留配置） |
| 更新 | SKILL：`claude plugins update <name>`；MCP：运行更新检查脚本 |
| 卸载 | SKILL：`claude plugins uninstall <name>`；MCP：从 `settings.json` 移除配置 |
| 查看详情 | 展示安装路径、配置文件内容、最近更新时间 |
| 跳过 | 结束流程，不做任何更改 |

### 3. SKILL 插件安装流程

#### 3a. 注册 Marketplace

如果不是本地路径，先注册来源 Marketplace：

```bash
claude plugins marketplace add <来源>
```

- 如果 Marketplace 已注册，检测 `known_marketplaces.json` 跳过此步
- 注册成功后展示 Marketplace 信息

#### 3b. 安装插件

```bash
claude plugins install <插件名>
```

常见映射（从来源提取插件名）：

| 来源 | 插件名 |
|------|--------|
| `Minecraft269/skills` | `minecraft269-skills` |
| `Minecraft269/skills.git` | `minecraft269-skills` |
| 本地 `./my-skill/` | 从 `plugin.json` → `name` 字段提取 |

插件名优先从 `plugin.json` 的 `name` 字段提取，其次从目录名推断。

#### 3c. 自动升级配置

检查并启用自动升级：

`known_marketplaces.json` 位置：`~/.claude/known_marketplaces.json`

处理逻辑：
1. 读取 `known_marketplaces.json`
2. 查找匹配的 source URL
3. 设置 `"autoUpdate": true`（如不存在则添加）
4. 写回文件

**如果 Marketplace 不支持自动升级**（本地安装或未知来源），提示用户：
- 「此来源不支持自动升级，需要手动执行 `claude plugins update <name>` 来更新」
- 建议用户设置定期提醒或 cron 任务

### 4. MCP Server 安装流程

#### 4a. 收集 MCP 配置信息

向用户收集必要信息（如未在来源中自动检测到）：

```
请提供以下 MCP Server 配置信息：

1. 传输协议 (默认: stdio)：
   - stdio（本地命令行）
   - sse（Server-Sent Events）
   - streamable-http

2. 启动命令（如 npx、uvx、node 等）

3. 命令参数（如有）

4. 环境变量（如 API keys）
```

#### 4b. 生成并写入 MCP 配置

根据收集的信息，在 `~/.claude/settings.json` 的 `mcpServers` 中添加配置：

```json
{
  "mcpServers": {
    "<server-name>": {
      "type": "<stdio|sse|streamable-http>",
      "command": "<command>",
      "args": ["<arg1>", "<arg2>"],
      "env": {
        "<KEY>": "<value>"
      }
    }
  }
}
```

**重要：** 先读取现有 `settings.json`，合并新配置后再写回，不要覆盖已有的其他 MCP Server 配置。

#### 4c. MCP 接入验证

配置写入后：

1. **检查必要环境变量**是否已设置（如 `GITHUB_TOKEN`、`ANTHROPIC_API_KEY` 等）
2. **提示用户重启 Claude Code** 或重新加载 MCP 连接
3. **提供快速测试命令**：告诉用户如何验证 MCP 是否正常工作

```markdown
> ✅ MCP 配置已写入。请重启 Claude Code 以加载新的 MCP Server。
>
> 重启后，可以通过以下方式验证：
> - 查看 MCP 工具是否出现在可用工具列表中
> - 尝试调用 MCP 工具（如 `mcp__<server>__<tool>`）
```

#### 4d. MCP 更新检查

由于 MCP Server 没有内置的自动升级机制，本技能提供更新检查能力：

**内置脚本 `scripts/check-mcp-updates.sh`**：
- 检查 GitHub releases、npm registry、或 pip 上的最新版本
- 与本地配置中记录的版本比较
- 输出更新建议

用户可手动运行或设置 cron 定期执行。

### 5. 输出确认摘要

每次安装完成后，输出格式化摘要：

```markdown
✅ 安装完成

| 项目 | 详情 |
|------|------|
| 📦 类型 | {MCP Server / SKILL 插件} |
| 📛 名称 | {插件名或 MCP Server 名} |
| 🔗 来源 | {GitHub repo / 本地路径 / Registry URL} |
| 🔄 自动升级 | {已启用 / 未启用 + 原因 / 需手动检查（MCP 脚本）} |
| ⚠️ 注意事项 | {环境变量 / 认证 / 兼容性提醒} |
| 📝 下一步 | {重启 Claude Code / 运行验证命令 / 配置 API Key} |
```

安装完成后建议用户运行以下命令验证：

```bash
claude plugins list    # 确认插件在列表中
/discover              # 运行技能发现（已合并至 universal-project-kickoff）
```

**联动钩子（仅 PACKAGE_MODE = true 时执行）：**

安装完成后，扫描兄弟技能的 `capabilities`，匹配 `integrates_with: skill-discovery`：
- 匹配成功 → 提示用户："💡 安装完成。是否需要运行 **项目启动与能力发现** 来扫描当前项目，查看新安装的能力如何匹配你的技术栈？"
- 用户同意 → 触发技能发现流程

### 6. 常见 MCP Server 快速安装模板

内置几个常用 MCP Server 的配置模板，简化安装：

#### GitHub MCP Server

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "<your-github-token>"
      }
    }
  }
}
```

#### Context7 MCP Server

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

#### Playwright MCP Server

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp-server"]
    }
  }
}
```

更多模板参见 `references/mcp-templates.md`。

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| Marketplace 已注册 | 跳过注册步骤，直接安装 |
| 插件已安装 | 提示用户并询问是否重新安装/更新 |
| `claude` CLI 不可用 | 引导用户先安装 Claude Code CLI |
| `settings.json` 不存在 | 自动创建基础结构 |
| `settings.json` 格式损坏 | 备份原文件并重建 |
| MCP Server 启动失败 | 检查命令是否存在、网络是否可达、环境变量是否设置 |
| 权限不足 | 提示需要管理员权限或使用 `sudo` |

## 脚本

- `scripts/check-mcp-updates.sh` — MCP Server 更新检查脚本（检查 GitHub/npm/pip 新版本）
- `scripts/toggle-autoupdate.sh` — 切换 `known_marketplaces.json` 中指定来源的 `autoUpdate` 状态

## 参考

- `references/mcp-templates.md` — 常见 MCP Server 的完整配置模板库
