# Hook 配置指南

本文件提供可选的 Claude Code hook 配置，让 `proactive-skill-discovery` 在关键时机自动触发。

## 使用方式

将以下配置片段添加到 `~/.claude/settings.json` 的 `hooks` 字段中（如不存在则创建）。

## 推荐配置

### 会话启动时自动发现

每次打开项目时自动运行一次技能发现：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[MAGIC KEYWORD: discover]'"
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
            "command": "if echo \"$CLAUDE_TOOL_OUTPUT\" | grep -qE 'package\\.json|Cargo\\.toml|pom\\.xml|go\\.mod'; then echo '[MAGIC KEYWORD: discover]'; fi"
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
            "command": "echo '[MAGIC KEYWORD: discover]'"
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
            "command": "if echo \"$CLAUDE_TOOL_OUTPUT\" | grep -qE 'package\\.json|Cargo\\.toml|pom\\.xml|go\\.mod'; then echo '[MAGIC KEYWORD: discover]'; fi"
          }
        ]
      }
    ]
  }
}
```

## 注意事项

- `[MAGIC KEYWORD: discover]` 是触发 `proactive-skill-discovery` 技能的关键词
- Hook 配置需要重启 Claude Code 后生效
- 如果发现频率过高，可移除 `PostToolUse` hook，仅保留 `SessionStart`
- 技能内置了上下文记忆机制，相同项目不会在短期内重复推荐

## 验证

配置完成后：
1. 重启 Claude Code
2. 打开一个项目
3. 观察是否自动触发技能发现
4. 如未触发，检查 `settings.json` 格式是否正确（注意 JSON 语法）
