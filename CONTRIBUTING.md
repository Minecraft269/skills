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
skills/<skill-name>/
├── SKILL.md              # 技能入口文件（必需）
├── references/           # 参考资料（可选）
│   └── *.md
├── scripts/              # 可执行脚本（可选）
│   └── *.sh
└── README.md             # 技能说明（可选）
```

### SKILL.md 格式

- 使用 YAML frontmatter（`---` 包裹），包含 `name`、`description` 字段
- 正文使用 Markdown，中文为主
- 代码块标注语言类型
- 缩进使用 2 空格

### 命名规范

- 技能目录：`kebab-case`（如 `github-pr-manager`）
- frontmatter `name`：与目录名一致
- 脚本文件：`snake_case.sh`

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
