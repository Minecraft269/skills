# Hook 配置指南

本文件提供可选的 Claude Code hook 配置，让 `universal-project-kickoff` 在关键时机自动触发。

## 使用方式

将以下配置片段添加到 `~/.claude/settings.json` 的 `hooks` 字段中（如不存在则创建）。

## 推荐配置

### 会话启动时自动触发项目启动与发现

每次打开项目时自动运行一次项目启动检查与能力发现：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[MAGIC KEYWORD: project-kickoff]'"
          }
        ]
      }
    ]
  }
}
```

### 检测到新项目类型时触发

当 Glob/Read 发现新的配置文件时触发：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Glob",
        "hooks": [
          {
            "type": "command",
            "command": "if echo \"$CLAUDE_TOOL_OUTPUT\" | grep -qE 'package\.json|Cargo\.toml|pom\.xml|go\.mod'; then echo '[MAGIC KEYWORD: project-kickoff]'; fi"
          }
        ]
      }
    ]
  }
}
```

### 合并配置

两个 hook 可以共存：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[MAGIC KEYWORD: project-kickoff]'"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Glob|Read",
        "hooks": [
          {
            "type": "command",
            "command": "if echo \"$CLAUDE_TOOL_OUTPUT\" | grep -qE 'package\.json|Cargo\.toml|pom\.xml|go\.mod'; then echo '[MAGIC KEYWORD: project-kickoff]'; fi"
          }
        ]
      }
    ]
  }
}
```

## 自然语言触发词

本技能支持以下自然语言触发（无需 hook 配置，直接在对话中使用）：

- "我要开始一个新项目"、"帮我规划一个新功能"、"想启动一个 AI Agent"
- "有哪些可用的技能/插件"、"推荐什么工具"、"/discover"
- "帮我审查代码"、"帮我修 Bug"、"我要开发一个新功能"
- "检查一下我的项目计划"、"帮我理一理思路"、"新项目怎么开始"

使用自然语言触发更为灵活，推荐在日常使用中优先采用。

## 注意事项

- `[MAGIC KEYWORD: project-kickoff]` 是触发 `universal-project-kickoff` 技能的关键词
- Hook 配置需要重启 Claude Code 后生效
- 如果发现频率过高，可移除 `PostToolUse` hook，仅保留 `SessionStart`
- 技能内置了上下文记忆机制，相同项目不会在短期内重复推荐

## 验证

配置完成后：
1. 重启 Claude Code
2. 打开一个项目
3. 观察是否自动触发项目启动与能力发现
4. 如未触发，检查 `settings.json` 格式是否正确（注意 JSON 语法）

## 从旧版 proactive-skill-discovery 迁移

如果你之前配置了 `proactive-skill-discovery` 的 hook（使用 `[MAGIC KEYWORD: discover]`），请更新为：
- 关键词：`[MAGIC KEYWORD: discover]` → `[MAGIC KEYWORD: project-kickoff]`
- 技能名称：所有引用 `proactive-skill-discovery` 的地方改为 `universal-project-kickoff`
- ⚠️ `proactive-skill-discovery` 技能已于 v4.0.0 删除，请立即迁移你的 hook 配置。
