## 变更说明

简要描述此 PR 的内容和目的。

## 变更类型

- [ ] 新技能
- [ ] 技能增强
- [ ] Bug 修复
- [ ] 文档更新
- [ ] CI/CD / 基础设施
- [ ] 其他：

## Checklist

### 技能相关（新增或修改技能时填写）

- [ ] 使用 `/skill-creator` 创建技能
- [ ] `SKILL.md` 包含完整的 YAML frontmatter（`name`、`description` 必填）
- [ ] 如适用，声明 `capabilities` 和 `integrates_with` 字段
- [ ] 新标签已注册到 `CONTRIBUTING.md` 标签注册表
- [ ] 已创建 `docs/<skill-name>.md` 文档
- [ ] 已在 `README.md` 技能列表中添加条目
- [ ] 已测试核心工作流可正常触发
- [ ] 如果技能涉及外部 API/付费服务/敏感操作，已在 frontmatter 中声明
- [ ] 独立安装时联动功能可静默降级（PACKAGE_MODE 检测）

### 脚本相关（修改 `scripts/*.sh` 时填写）

- [ ] Shell 语法正确（`bash -n` 通过）
- [ ] 用户输入参数已做正则验证
- [ ] 外部命令使用 `--` 分隔符
- [ ] 已处理错误场景（依赖缺失、网络超时、权限不足等）

### 通用

- [ ] 所有面向用户的内容使用中文

## 验证方式

描述如何验证此 PR 的变更。

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
