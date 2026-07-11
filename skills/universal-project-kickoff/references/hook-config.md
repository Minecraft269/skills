# Hook Configuration Guide

This document provides optional Claude Code hook configurations to let `universal-project-kickoff` trigger automatically at key moments.

## Usage

Add the following configuration snippets to the `hooks` field of `~/.claude/settings.json` (create the file if it does not exist).

## Recommended Configurations

### Auto-trigger on Session Start

Runs project kickoff and capability discovery once each time a project is opened:

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

### Trigger on New Project Type Detection

Fires when Glob/Read discovers new configuration files:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Glob",
        "hooks": [
          {
            "type": "command",
            "command": "if echo \"$CLAUDE_TOOL_OUTPUT\" | grep -qE 'package\\.json|Cargo\\.toml|pom\\.xml|go\\.mod'; then echo '[MAGIC KEYWORD: project-kickoff]'; fi"
          }
        ]
      }
    ]
  }
}
```

### Combined Configuration

Both hooks can coexist:

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
            "command": "if echo \"$CLAUDE_TOOL_OUTPUT\" | grep -qE 'package\\.json|Cargo\\.toml|pom\\.xml|go\\.mod'; then echo '[MAGIC KEYWORD: project-kickoff]'; fi"
          }
        ]
      }
    ]
  }
}
```

## Natural Language Triggers

This skill supports the following natural language triggers (no hook configuration needed -- use directly in conversation):

- "I want to start a new project", "Help me plan a new feature", "I want to kick off an AI Agent"
- "What skills/plugins are available", "Recommend some tools", "/discover"
- "Help me review code", "Help me fix a bug", "I need to develop a new feature"
- "Check my project plan", "Help me organize my thoughts", "How to start a new project"

Natural language triggers are more flexible and recommended for everyday use.

## Notes

- `[MAGIC KEYWORD: project-kickoff]` is the keyword that triggers the `universal-project-kickoff` skill
- Hook configuration takes effect after restarting Claude Code
- If triggers fire too frequently, remove the `PostToolUse` hook and keep only `SessionStart`
- The skill has built-in context awareness -- it will not repeat recommendations for the same project in a short period

## Verification

After configuration:
1. Restart Claude Code
2. Open a project
3. Observe whether project kickoff and capability discovery trigger automatically
4. If not triggered, check `settings.json` for correct JSON syntax

## Migration from Legacy proactive-skill-discovery

If you previously configured hooks for `proactive-skill-discovery` (using `[MAGIC KEYWORD: discover]`), update as follows:
- Keyword: `[MAGIC KEYWORD: discover]` → `[MAGIC KEYWORD: project-kickoff]`
- Skill name: Replace all references to `proactive-skill-discovery` with `universal-project-kickoff`
- ⚠️ `proactive-skill-discovery` was removed in v4.0.0 -- migrate your hook configuration immediately.
