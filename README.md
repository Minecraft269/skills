# Minecraft269 Skills

Minecraft269 的 Claude Code 技能合集，包含三个实用技能，提升 Claude Code 在日常开发中的工作效率。

## 技能列表

### 1. github-pr-manager

GitHub PR 全功能管理器 — 在终端中列出、查看、克隆、分析 GitHub Pull Request。

**核心功能：**
- 列出仓库所有开放 PR（表格展示，支持翻页）
- 查看 PR 完整信息：详情、diff、评论、审查状态、提交历史
- 克隆 PR 到本地并自动检测项目类型（Node/Python/Rust/Go/Java）初始化环境
- CI 状态查看和失败原因分析
- 多仓库切换和批量操作

**前置依赖：** `gh` (GitHub CLI ≥ 2.0.0)、`git`、`jq`

### 2. proactive-skill-discovery

主动技能发现引擎 — 在项目启动、复杂任务等关键节点自动扫描并推荐匹配的 Skills、Plugins 和 Commands。

**核心功能：**
- 自动检测项目语言、框架、构建工具
- 并行扫描已安装的技能和插件并评分匹配
- 交互式推荐（优先推荐 + 技能 + 插件 + 深度资源）
- 指令发现（MCP 工具和 Slash 命令）
- 支持全量能力导出（技能/插件/指令清单）

### 3. universal-project-kickoff

通用项目快速启动规则 — 适用于任何类型项目的启动阶段，执行六步强制流程。

**核心流程：**
- 澄清项目"为什么"与"是什么"
- 圈定边界，明确"不做什么"
- 快速风险摸底
- 利益相关者与期望对齐
- 绘制粗糙路线图（3-5 个里程碑）
- 调用 /init 将思考成果固化到 CLAUDE.md

**适用场景：** 新项目启动、功能规划、AI Agent 设计、项目计划审查

---

## 安装

### 方式一：通过 GitHub 安装

```bash
claude plugins install Minecraft269/skills
```

### 方式二：手动安装

```bash
git clone https://github.com/Minecraft269/skills.git
cp -r skills ~/.claude/skills/
```

然后在 Claude Code 中运行 `/reload-skills`。

---

## 许可证

MIT License — 详见 [LICENSE](LICENSE)
