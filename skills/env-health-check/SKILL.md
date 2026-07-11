---
name: env-health-check
description: >
  Cross-platform environment health check tool — detects the availability, version, and auth status
  of core dependencies such as git, gh, jq, and claude, and scans MCP Server configuration integrity.
  Use this skill after first installing the plugin package, when encountering "command not available" errors,
  or when you want to confirm whether the development environment is ready.
capabilities: ["env-check"]
integrates_with: ["skill-discovery", "plugin-installation"]
metadata:
  compatibility: "Cross-platform (Windows/macOS/Linux)"
---

# Environment Health Check

Cross-platform detection of Claude Code and common toolchain availability, outputting a formatted health report. Purely AI-driven, no additional dependencies required.

## Package Linking

1. Glob search for `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. If found → `PACKAGE_MODE = true`, can link with sibling skills
3. If not found → `PACKAGE_MODE = false`, silent degradation

When `PACKAGE_MODE = true`:
- Problems found → link to `integrates_with: plugin-installation` (install missing tools)
- Environment ready → link to `integrates_with: skill-discovery` (scan project and recommend skills)

See `_shared/package-context.md` for details.

## Core Workflow

### 1. Detect Core Dependencies in Parallel

Run detection commands for the following tools in parallel:

| Tool | Detection Command | Required |
|------|-------------------|----------|
| git | `command -v git && git --version` | Yes |
| gh | `command -v gh && gh --version` | Recommended |
| jq | `command -v jq && jq --version` | Recommended |
| claude | `command -v claude && claude --version` | Yes |
| node | `command -v node && node --version` | Recommended |
| python | `command -v python3 \|\| command -v python` | Optional |

### 2. Check Service Status

If critical tools are available, perform further checks:

```bash
# gh auth status
gh auth status 2>&1

# claude CLI availability
claude --version 2>&1

# MCP Server configuration (if settings.json exists)
jq -r '.mcpServers // {} | keys[]' ~/.claude/settings.json 2>/dev/null
```

### 3. Output Health Report

Display as a formatted table, with status and action suggestions for each item:

```markdown
## 🔍 Environment Health Report

### Core Dependencies

| Tool | Status | Version | Location |
|------|--------|---------|----------|
| git | ✅ | 2.45.0 | /usr/bin/git |
| gh | ✅ | 2.55.0 | /usr/bin/gh |
| jq | ✅ | 1.7.1 | /usr/bin/jq |
| claude | ✅ | 0.14.0 | ~/.local/bin/claude |
| node | ⚠️ | — | Not installed |
| python | ✅ | 3.12.3 | /usr/bin/python3 |

### Service Status

| Service | Status | Details |
|---------|--------|---------|
| gh auth | ✅ | Logged in |
| MCP Server | — | No MCP Servers configured |

### Suggestions

- ⚠️ **node** not installed — some MCP Servers require Node.js
  - Install: `winget install OpenJS.NodeJS` (Windows) / `brew install node` (macOS)

```

**Status icon rules:**
- ✅ Installed and available
- ⚠️ Not installed or unrecommended version (provide install command)
- ❌ Required tool missing (blocking)
- `—` Not applicable or not configured

**Install commands for missing tools should cover all three major platforms:**

| Tool | Windows | macOS | Linux |
|------|---------|-------|-------|
| git | `winget install Git.Git` | Built-in | `apt install git` |
| gh | `winget install GitHub.cli` | `brew install gh` | `apt install gh` |
| jq | `winget install jqlang.jq` | `brew install jq` | `apt install jq` |
| node | `winget install OpenJS.NodeJS` | `brew install node` | `apt install nodejs` |

## Linkage (PACKAGE_MODE = true only)

After outputting the report:

- If **tools are missing** → prompt: "💡 Would you like me to install the missing tools?" (matches `plugin-installation`)
- If **environment is ready** → prompt: "✅ Environment ready. Would you like to scan the current project for matching skill recommendations?" (matches `skill-discovery`)

## Error Handling

| Scenario | Handling |
|----------|----------|
| Not in terminal environment | Skip `command -v`, prompt user to check manually |
| settings.json does not exist | Mark as "Not configured", do not error |
| Detection timeout | Per-tool timeout 5s, mark as ⚠️ and continue to next |
