# 贡献指南

感谢你对 Minecraft269 Skills 的关注！本文件帮助你了解如何参与贡献。

## 快速开始

1. **Fork** 本仓库
2. 创建功能分支：`git checkout -b feat/your-skill-name`
3. 完成开发后提交 PR 到 `main` 分支
4. 等待维护者审核

## 创建新技能

**推荐方式：使用 `skill-creator` 技能创建。**

> ⚠️ 使用前请确认已安装 `skill-creator` 插件。如未安装，先在 Claude Code 中安装该插件。

确认安装后，在 Claude Code 中运行 `/skill-creator`，它会引导你完成技能创建的标准流程。创建完成后，将生成的技能目录放入 `skills/<skill-name>/`。

### 技能目录结构

```
skills/
├── _shared/               # 包级共享资源（检测协议、通用模板等）
│   ├── package-context.md # 包上下文检测协议
│   └── ...
├── <skill-name>/          # 单个技能目录
│   ├── SKILL.md           # 技能入口文件（必需）
│   ├── references/        # 参考资料（可选）
│   │   └── *.md
│   ├── scripts/           # 可执行脚本（可选）
│   │   └── *.sh
│   └── README.md          # 技能说明（可选）
└── ...
```

### SKILL.md 格式

- 使用 YAML frontmatter（`---` 包裹），包含 `name`、`description` 字段
- 可选字段：`capabilities`（本技能提供的能力标签）、`integrates_with`（本技能需要配合的能力标签）
- 正文使用 Markdown，中文为主
- 代码块标注语言类型
- 缩进使用 2 空格

### 命名规范

- 技能目录：`kebab-case`（如 `github-pr-manager`）
- frontmatter `name`：与目录名一致
- 脚本文件：`snake_case.sh`

### 技能联动规范

本插件包支持技能间互相配合。为确保独立安装用户不受影响，所有跨技能引用必须遵循以下规范。

#### 包上下文检测

每个技能在执行前需检测是否处于完整插件包环境：

1. Glob 搜索 `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. 找到 → **高联系模式**（`PACKAGE_MODE = true`），可引用兄弟技能
3. 未找到 → **独立模式**（`PACKAGE_MODE = false`），静默跳过所有跨技能引用

详见 `skills/_shared/package-context.md`。

#### Frontmatter 联动字段

在 SKILL.md 的 YAML frontmatter 中声明联动意愿：

```yaml
capabilities: ["<能力标签>", ...]     # 本技能提供的能力
integrates_with: ["<需求标签>", ...]  # 本技能需要配合的能力类型
```

- `capabilities`：声明本技能能做什么，供其他技能发现
- `integrates_with`：声明本技能在工作流中需要什么类型的配合
- 两个字段均为可选 — 不声明则跳过联动
- 标签应优先使用已有标签（见下方注册表），避免重复定义

#### 条件性联动写法

在 SKILL.md 中添加"包联动"章节，描述 PACKAGE_MODE 检测逻辑。联动钩子放在关键工作流步骤末尾：

```
**联动钩子（仅 PACKAGE_MODE = true 时执行）：**
扫描兄弟技能的 capabilities，匹配本技能的 integrates_with 标签...
```

如果 PACKAGE_MODE = false，完全跳过联动段落 — 不显示任何跨技能提示。

#### 能力标签注册表

新技能应优先使用已有标签。如需新标签，请在此注册并说明语义。

| 标签 | 语义 | 已有使用者 |
|------|------|-----------|
| `pr-management` | PR 的查看/克隆/审查/CI 管理 | github-pr-manager |
| `ci-analysis` | CI 状态检查与失败分析 | github-pr-manager |
| `code-cloning` | 将远程代码克隆到本地并初始化环境 | github-pr-manager |
| `skill-discovery` | 扫描项目、发现并推荐匹配能力 | proactive-skill-discovery |
| `capability-scanning` | 扫描已安装的技能/插件/MCP | proactive-skill-discovery |
| `project-analysis` | 分析项目技术栈和结构 | proactive-skill-discovery |
| `plugin-installation` | 安装 MCP/SKILL 插件 | quick-plugin-installer |
| `mcp-setup` | MCP Server 配置与验证 | quick-plugin-installer |
| `project-setup` | 项目启动的六步决策流程 | universal-project-kickoff |
| `risk-assessment` | 项目风险识别与预案 | universal-project-kickoff |
| `mvp-planning` | MVP 范围圈定与路线图 | universal-project-kickoff |
| `pr-review` | PR 代码审查与 inline 评论工作流 | github-pr-reviewer |
| `code-review` | 代码质量审查（通用） | github-pr-reviewer |
| `inline-comments` | 逐行 inline PR 评论发布 | github-pr-reviewer |
| `git-commit` | Git 提交规范化与 commit message 生成 | git-commit-helper |
| `env-check` | 跨平台环境自检与依赖可用性诊断 | env-health-check |

#### 共享资源

`skills/_shared/` 目录存放包级公共资源：
- `package-context.md` — 包上下文检测协议
- 未来可扩展：通用模板、共享脚本、公共常量等

各技能可通过相对路径引用 `_shared/` 中的资源。新增共享资源时需在本文件中说明用途。

### 提交信息

使用约定式提交格式：

```
feat: 添加 xxx 技能
fix: 修复 xxx 问题
docs: 更新 xxx 文档
refactor: 重构 xxx
```

## 技能审核标准

提交 PR 前请确认：

- [ ] SKILL.md 包含完整的 frontmatter（name、description）
- [ ] 如技能属于本插件包，已声明 `capabilities` 和 `integrates_with`（如适用）
- [ ] 跨技能引用使用 PACKAGE_MODE 门控，独立安装时静默降级
- [ ] 技能可通过 `/` 命令正常触发
- [ ] 引用的外部工具/依赖在 frontmatter 中声明
- [ ] 无侵犯他人 License 的内容
- [ ] 已在本地实际测试过核心路径

## 报告问题

通过 [GitHub Issues](https://github.com/Minecraft269/skills/issues) 提交：

- **Bug 报告**：描述遇到的问题、复现步骤、预期行为
- **功能建议**：描述使用场景、期望的效果
- **技能请求**：说明你需要的技能及使用场景

## License

本项目的所有贡献均遵循 [MIT License](LICENSE)。
