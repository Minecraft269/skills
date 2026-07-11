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
2. Glob 扫描 `skills/*/SKILL.md`（**排除自身 SKILL.md**，通过对比 `name` frontmatter 字段实现）
3. 对每个兄弟 SKILL.md，解析 frontmatter 中的 `capabilities` 字段
4. 将本技能的 `integrates_with` 与兄弟技能的 `capabilities` 做交集匹配
5. 对匹配到的每个兄弟技能，提取其 `name` 和 `description`
6. 在当前工作流节点生成条件性推荐

**自我过滤规则**：技能绝不应通过联动发现推荐自身。在步骤 2 的 Glob 结果中，必须排除 `name` 字段与当前技能 `name` 完全相同的 SKILL.md。
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

## 六、循环触发防护

为防止技能联动形成无限循环，所有技能必须遵循以下规则：

### 防护规则

1. **上下文标记**：每次触发联动后，在对话上下文中记录 `_LINKED_FROM: ["<触发技能名>"]` 标记
2. **循环检测**：执行联动前检查标记 — 如果标记中存在当前技能名，跳过该次联动
3. **深度限制**：联动链深度不超过 2 层（直接联动 + 二级联动），超过则截断
4. **频次限制**：同一技能在单次会话中最多触发 3 次联动，达到上限后静默跳过

### 实现提示

```
触发联动前:
  1. 检查 _LINKED_CHAIN 深度计数器 (初始 0)
  2. 若深度 >= 2 → 跳过，不触发联动
  3. 检查 _TRIGGERED_SKILLS 频次记录
  4. 若本技能已触发 >= 3 次 → 跳过
  5. 执行联动，深度 +1，频次 +1
  
完成后:
  6. 深度 -1（退出当前联动层级）
```

### 示例

```
github-pr-manager 克隆 PR → 触发联动 → universal-project-kickoff (深度 1)
  → 初始化 + 能力推荐完成 → 触发联动 → quick-plugin-installer (深度 2)
    → 安装完成 → 触发联动 → 深度已达上限，跳过
```

## 七、依赖健康检查

为确保 PACKAGE_MODE 联动发现能正常工作，建议在首次加载 package-context.md 时执行轻量级健康检查：

### 检查步骤

1. Glob 扫描 `skills/*/SKILL.md` 获取所有技能
2. 验证每个 SKILL.md 的 frontmatter 可解析（至少包含 `name` 字段）
3. 若任何 SKILL.md 的 frontmatter 格式错误，记录警告但不中断
4. 对比 `capabilities` 标签与 CONTRIBUTING.md 中的标签注册表
5. 若发现未注册标签，提示开发者更新注册表

### 降级策略

如果健康检查发现任何声明 `capabilities: ["skill-discovery"]` 的技能的 SKILL.md 格式异常（该能力被多个技能依赖），其他技能应：
- 静默跳过 `skill-discovery` 联动（不报错）
- 继续执行自身核心功能
- 在首次遇到需要联动的节点时给出一次性提示："部分技能联动暂不可用"

## 八、联动链扩展

联动可以链式传播，但遵循层级限制：

| 联动层级 | 描述 | 是否允许 |
|---------|------|---------|
| 一级联动 | 技能 A 完成 → 推荐技能 B | ✅ 允许 |
| 二级联动 | 技能 B 完成 → 推荐技能 C | ✅ 允许 |
| 三级及以上 | 技能 C 完成 → 推荐技能 D | ❌ 禁止（截断） |

### 典型联动链示例

```
1. github-pr-manager 克隆陌生项目 PR
   → 一级联动: 推荐 universal-project-kickoff 初始化项目

2. universal-project-kickoff 完成 CLAUDE.md 生成 + 能力推荐
   → 二级联动: 推荐 quick-plugin-installer 安装缺失工具

3. quick-plugin-installer 安装完成后
   → 三级联动: 应再次推荐能力发现 → ❌ 截断
   → 替代方案: 在二级联动结果中一次性列出所有后续建议
```

三级及以上联动应被替换为"一次性建议列表"：在二级联动的结果中，将所有可能需要的后续操作以列表形式呈现，而非链式触发。
