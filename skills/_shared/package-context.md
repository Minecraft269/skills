# 包上下文检测协议

本文件定义 minecraft269-skills 插件包内所有技能的通用包检测和联动发现协议。
每个技能在启动时引用本协议，无需修改即可适配未来新增的技能。

## 一、PACKAGE_MODE 检测

### 检测步骤

```
1. 搜索 ~/.claude/plugins/ 下是否存在含 .claude-plugin/plugin.json 的子目录
2. 使用 Glob 查找 ~/.claude/plugins/*/.claude-plugin/plugin.json
3. 若找到，Read 该 plugin.json，检查 name 字段
4. 若 name 为 "minecraft269-skills" → PACKAGE_MODE = true（高联系模式）
5. 否则 → PACKAGE_MODE = false（独立模式）
```

### 模式行为差异

| 行为 | 高联系模式 (PACKAGE_MODE = true) | 独立模式 (PACKAGE_MODE = false) |
|------|--------------------------------|-------------------------------|
| 技能间引用 | 主动发现并建议兄弟技能联动 | 完全不提及任何兄弟技能 |
| 跨技能命令提示 | 可用 | 静默隐藏 |
| 包级共享资源 | 可加载 `_shared/` 中的资源 | 仅使用本技能内置资源 |
| 动态能力发现 | 扫描兄弟 SKILL.md 的 capabilities 字段 | 跳过扫描 |

### 安全默认值

**独立模式是安全默认值。** 任何检测失败（文件不存在、权限错误、解析失败）都应降级为 PACKAGE_MODE = false，不得报错或中断。

## 二、运行时联动发现

### 算法

当 PACKAGE_MODE = true 且技能执行到关键节点时：

```
1. 确定本技能所在的插件包根目录
2. Glob 扫描 skills/*/SKILL.md（排除自身）
3. 对每个兄弟 SKILL.md，解析 frontmatter 中的 capabilities 字段
4. 将本技能的 integrates_with 与兄弟技能的 capabilities 做交集匹配
5. 对匹配到的每个兄弟技能，提取其 name 和 description
6. 在当前工作流节点生成条件性推荐
```

### 标签匹配示例

```
本技能 integrates_with: ["skill-discovery", "plugin-installation"]

兄弟技能 A: capabilities: ["skill-discovery", "project-analysis"]  → 匹配 "skill-discovery" ✅
兄弟技能 B: capabilities: ["pr-management", "ci-analysis"]         → 无匹配 ❌
兄弟技能 C: capabilities: ["plugin-installation", "mcp-setup"]      → 匹配 "plugin-installation" ✅
```

结果：推荐兄弟技能 A 和 C。

## 三、Frontmatter 扩展规范

每个技能可在 SKILL.md frontmatter 中声明以下字段以参与联动：

```yaml
capabilities: ["<标签>", ...]     # 本技能提供的能力
integrates_with: ["<标签>", ...]  # 本技能需要配合的能力类型
```

两个字段均为可选。未声明 `integrates_with` 的技能不会主动发起联动；未声明 `capabilities` 的技能不会被其他技能发现。

标签命名约定：
- 使用 `kebab-case`（如 `pr-management`、`skill-discovery`）
- 语义明确，不分词过细
- 优先复用已有标签（参见 CONTRIBUTING.md 中的标签注册表）

## 四、联动触发时机指南

| integrates_with 标签 | 建议触发时机 |
|----------------------|-------------|
| `skill-discovery` | 当前技能完成主要操作后（安装完成、初始化完成、克隆完成） |
| `project-setup` | 检测到用户首次接触项目（克隆陌生仓库、进入新目录） |
| `plugin-installation` | 发现用户缺少工具/插件/MCP Server |
| `pr-management` | 检测到 GitHub remote 且有活跃开发活动 |
| `code-review` | 完成代码修改后 |
| `testing` | 完成功能实现后 |

## 五、扩展性

当新技能加入包时：
1. 在 SKILL.md frontmatter 声明 `capabilities` 和 `integrates_with`
2. 在 CONTRIBUTING.md 标签注册表中注册新标签（如使用新标签）
3. 在合适的工作流节点插入联动发现步骤

**无需修改本文件或其他已有技能。** 运行时发现机制会自动识别新技能。
