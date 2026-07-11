# quick-plugin-installer

Quick plugin installer — a unified entry point for one-click discovery, registration, installation, and auto-update configuration of Claude Code plugins (MCP Server and SKILL plugins).

## Core Features

- Automatic plugin type detection (MCP Server vs SKILL plugin vs local directory)
- Existing installation detection → interactive actions (reinstall/update/uninstall/view/skip)
- Marketplace registration + installation + auto-update configuration
- MCP Server config generation, writing, and connectivity verification
- MCP update check script (npm/local commands)
- 16 MCP configuration templates (GitHub/Context7/Playwright/Postgres/Jira/Slack...)
- Cross-platform compatibility (Linux/macOS/Windows Git Bash)

## Six-Step Workflow

| Step | Description |
|------|-------------|
| 1. Identify Type | MCP / SKILL / Local; ask interactively when uncertain |
| 2. Existing Check | Check if already installed, ask for next action |
| 3. SKILL Install | Marketplace register → install → autoUpdate |
| 4. MCP Install | Collect config → write settings.json → verify |
| 5. Output Summary | Display installation results in a formatted view |
| 6. Quick Templates | 16 common MCP Server one-click configurations |

## Prerequisites

- `gh` (GitHub CLI)
- `jq`
- `claude` CLI

## Related Skills

This skill is part of the [minecraft269-skills](https://github.com/Minecraft269/skills) plugin package. When the full package is installed, this skill can auto-link with other package skills:

- After installation, automatically suggests running skill discovery
- Guided by the proactive skill discovery engine to install user-selected missing capabilities

When installed standalone, the above linkage features are silently disabled, with no impact on core installation functionality.
