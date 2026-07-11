---
name: env-health-check
description: >
  跨平台环境自检工具 — 检测 git、gh、jq、claude 等核心依赖的可用性、版本和认证状态，
  扫描 MCP Server 配置完整性。当你首次安装插件包后、遇到"命令不可用"错误、
  或想确认开发环境是否就绪时使用此技能。
capabilities: ["env-check"]
integrates_with: ["skill-discovery", "plugin-installation"]
metadata:
  compatibility: "跨平台（Windows/macOS/Linux）"
locale: zh-CN
---

# 环境健康自检

跨平台检测 Claude Code 及常用工具链的可用性，输出格式化健康报告。纯 AI 驱动，无需额外依赖。

## 包联动

1. Glob 搜索 `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. 若找到 → `PACKAGE_MODE = true`，可联动兄弟技能
3. 若未找到 → `PACKAGE_MODE = false`，静默降级

当 `PACKAGE_MODE = true` 时：
- 发现问题 → 联动 `integrates_with: plugin-installation`（安装缺失工具）
- 环境就绪 → 联动 `integrates_with: skill-discovery`（扫描项目推荐技能）

详见 `_shared/package-context.md`。

## 核心工作流

### 1. 并行检测核心依赖

对以下工具并行运行检测命令：

| 工具 | 检测命令 | 必需 |
|------|---------|------|
| git | `command -v git && git --version` | ✅ |
| gh | `command -v gh && gh --version` | 推荐 |
| jq | `command -v jq && jq --version` | 推荐 |
| claude | `command -v claude && claude --version` | ✅ |
| node | `command -v node && node --version` | 推荐 |
| python | `command -v python3 \|\| command -v python` | 可选 |

### 2. 检测服务状态

如果关键工具可用，进一步检查：

```bash
# gh 认证状态
gh auth status 2>&1

# claude CLI 可用性
claude --version 2>&1

# MCP Server 配置（如 settings.json 存在）
jq -r '.mcpServers // {} | keys[]' ~/.claude/settings.json 2>/dev/null
```

### 3. 输出健康报告

以格式化表格展示，每项给出状态和操作建议：

```markdown
## 🔍 环境健康报告

### 核心依赖

| 工具 | 状态 | 版本 | 位置 |
|------|------|------|------|
| git | ✅ | 2.45.0 | /usr/bin/git |
| gh | ✅ | 2.55.0 | /usr/bin/gh |
| jq | ✅ | 1.7.1 | /usr/bin/jq |
| claude | ✅ | 0.14.0 | ~/.local/bin/claude |
| node | ⚠️ | — | 未安装 |
| python | ✅ | 3.12.3 | /usr/bin/python3 |

### 服务状态

| 服务 | 状态 | 详情 |
|------|------|------|
| gh auth | ✅ | 已登录 |
| MCP Server | — | 未配置任何 MCP Server |

### 建议

- ⚠️ **node** 未安装 — 部分 MCP Server 需要 Node.js
  - 安装: `winget install OpenJS.NodeJS` (Windows) / `brew install node` (macOS)

```

**状态图标规则：**
- ✅ 已安装且可用
- ⚠️ 未安装或不推荐版本（给出安装命令）
- ❌ 必需工具缺失（阻塞性）
- `—` 不适用或未配置

**对缺失工具给出的安装命令尽量覆盖三大平台：**

| 工具 | Windows | macOS | Linux |
|------|---------|-------|-------|
| git | `winget install Git.Git` | 内置 | `apt install git` |
| gh | `winget install GitHub.cli` | `brew install gh` | `apt install gh` |
| jq | `winget install jqlang.jq` | `brew install jq` | `apt install jq` |
| node | `winget install OpenJS.NodeJS` | `brew install node` | `apt install nodejs` |

## 联动（仅 PACKAGE_MODE = true）

输出报告后：

- 如有 **缺失工具** → 提示：「💡 是否需要我帮你安装缺失的工具？」（匹配 `plugin-installation`）
- 如 **环境已就绪** → 提示：「✅ 环境就绪。是否需要扫描当前项目，推荐匹配的技能？」（匹配 `skill-discovery`）

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| 不在终端环境 | 跳过 `command -v`，提示用户手动检查 |
| settings.json 不存在 | 标注"未配置"，不报错 |
| 检测超时 | 单工具超时 5s，标记为 ⚠️ 并继续下一个 |
