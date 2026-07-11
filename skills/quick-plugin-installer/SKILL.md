---
name: quick-plugin-installer
description: >
  Quick plugin installer (MCP Server and SKILL plugins) — unified entry point,
  automatic type detection, registration, installation, auto-update configuration,
  and MCP connection verification. Use this skill when you need to install any
  Claude Code plugin, MCP Server, SKILL skill, or Marketplace extension. Supports
  GitHub repo, Marketplace name, local path, MCP Registry, and other sources.
capabilities: ["plugin-installation", "mcp-setup"]
integrates_with: ["skill-discovery"]
metadata:
  compatibility: "Requires gh (GitHub CLI), jq, claude CLI"
  risk: safe
---

# Quick Plugin Installer

One-click discovery, registration, installation, and auto-update configuration for Claude Code plugins (MCP Server and SKILL plugins).

## Package Linking

This skill supports automatic linking with other skills in the minecraft269-skills plugin package. The following detection is performed:

1. Glob search for `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. If found → `PACKAGE_MODE = true`, enabling discovery and linking of sibling skills
3. If not found → `PACKAGE_MODE = false`, skipping all cross-skill logic (silent degradation)

When `PACKAGE_MODE = true`:
- After installation, can link with `integrates_with: skill-discovery`
- Scans sibling SKILL.md `capabilities` fields for matches against this skill's `integrates_with` tags
- Only displays linking hints when a match is found

See `_shared/package-context.md` for details.

## Core Workflow

### 1. Identify Plugin Type

The user only needs to provide an identifier; the skill automatically determines the target type.

**Trigger Methods:**
- User directly inputs a source: `/install-plugin <source>`
- Or natural language: "Install GitHub MCP", "Help me install Minecraft269/skills"

**Detection Logic:**

| Characteristic | Type |
|------|------|
| Source contains `mcp`, `server`, `MCP Server` or similar keywords | **MCP Server** |
| Source is a GitHub repo format (`owner/repo`) described as a skill/plugin marketplace | **SKILL Plugin (Marketplace)** |
| Source is a local path (`./xxx`, `/xxx`, `D:\xxx`) | **SKILL Plugin (Local)** |
| Cannot determine automatically | Ask the user interactively |

**Interactive Prompt Template:**
> "Cannot automatically determine the type of `{source}`. Please select:
> 1. SKILL Plugin (from Marketplace or local directory)
> 2. MCP Server (requires configuration in settings.json)
> 3. View details and decide later"

### 2. Existing Installation Detection (Must Perform Before Installation)

Before installing, check whether the target already exists:

- **SKILL Plugin**: Check `~/.claude/plugins/<plugin-name>/` directory or `claude plugins list` output
- **MCP Server**: Check whether `mcpServers.<server-name>` already exists in `~/.claude/settings.json`

If already installed, prompt the user interactively for the next action:

```markdown
⚠️ {plugin-name} is already installed.

Current Status:
- 📛 Name: {name}
- 📂 Location: {install path}
- 🔢 Version: {version} (if available)

Please choose an action:
1. 🔄 Reinstall (overwrite current version)
2. ⬆️ Update to latest version
3. 🗑️ Uninstall this plugin
4. 📋 View details (install path, config, dependencies)
5. ✅ Skip, keep as is
```

**Execute the Corresponding Action:**

| User Choice | Action |
|---------|------|
| Reinstall | Uninstall first, then install (preserve config) |
| Update | SKILL: `claude plugins update <name>`; MCP: run update check script |
| Uninstall | SKILL: `claude plugins uninstall <name>`; MCP: remove config from `settings.json` |
| View Details | Show install path, config file content, last updated time |
| Skip | End the flow, make no changes |

### 3. SKILL Plugin Installation Flow

#### 3a. Register Marketplace

If not a local path, first register the source Marketplace:

```bash
claude plugins marketplace add <source>
```

- If the Marketplace is already registered, detect via `known_marketplaces.json` and skip this step
- Display Marketplace information after successful registration

#### 3b. Install Plugin

```bash
claude plugins install <plugin-name>
```

Common mappings (extract plugin name from source):

| Source | Plugin Name |
|------|--------|
| `Minecraft269/skills` | `minecraft269-skills` |
| `Minecraft269/skills.git` | `minecraft269-skills` |
| Local `./my-skill/` | Extract from `plugin.json` → `name` field |

The plugin name is extracted first from the `name` field in `plugin.json`, and secondarily inferred from the directory name.

#### 3c. Auto-Update Configuration

Check and enable auto-update:

`known_marketplaces.json` location: `~/.claude/known_marketplaces.json`

Processing logic:
1. Read `known_marketplaces.json`
2. Find the matching source URL
3. Set `"autoUpdate": true` (add if not present)
4. Write back to the file

**If the Marketplace does not support auto-update** (local install or unknown source), notify the user:
- "This source does not support auto-update. You will need to manually run `claude plugins update <name>` to update."
- Suggest setting up periodic reminders or a cron task

### 4. MCP Server Installation Flow

#### 4a. Collect MCP Configuration Information

Collect necessary information from the user (if not automatically detected from the source):

```
Please provide the following MCP Server configuration information:

1. Transport protocol (default: stdio):
   - stdio (local command line)
   - sse (Server-Sent Events)
   - streamable-http

2. Start command (e.g., npx, uvx, node, etc.)

3. Command arguments (if any)

4. Environment variables (e.g., API keys)
```

#### 4b. Generate and Write MCP Configuration

Based on the collected information, add the configuration to the `mcpServers` section in `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "<server-name>": {
      "type": "<stdio|sse|streamable-http>",
      "command": "<command>",
      "args": ["<arg1>", "<arg2>"],
      "env": {
        "<KEY>": "<value>"
      }
    }
  }
}
```

**Important:** Read the existing `settings.json` first, merge the new configuration, then write back. Do not overwrite existing MCP Server configurations.

#### 4c. MCP Connection Verification

After writing the configuration:

1. **Check whether required environment variables** are set (e.g., `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`, etc.)
2. **Prompt the user to restart Claude Code** or reload the MCP connection
3. **Provide a quick test command**: Tell the user how to verify whether the MCP is working

```markdown
> ✅ MCP configuration has been written. Please restart Claude Code to load the new MCP Server.
>
> After restart, you can verify by:
> - Checking whether the MCP tools appear in the available tools list
> - Attempting to call an MCP tool (e.g., `mcp__<server>__<tool>`)
```

#### 4d. MCP Update Check

Since MCP Server does not have a built-in auto-update mechanism, this skill provides update check capability:

**Built-in script `scripts/check-mcp-updates.sh`:**
- Checks the latest version on GitHub releases, npm registry, or pip
- Compares with the version recorded in the local configuration
- Outputs update suggestions

Users can run it manually or set up a cron task for periodic execution.

### 5. Output Confirmation Summary

After each installation, output a formatted summary:

```markdown
✅ Installation Complete

| Item | Details |
|------|------|
| 📦 Type | {MCP Server / SKILL Plugin} |
| 📛 Name | {plugin name or MCP Server name} |
| 🔗 Source | {GitHub repo / local path / Registry URL} |
| 🔄 Auto-Update | {Enabled / Not enabled + reason / Manual check required (MCP script)} |
| ⚠️ Notes | {env vars / authentication / compatibility reminders} |
| 📝 Next Steps | {restart Claude Code / run verification command / configure API Key} |
```

After installation, recommend that the user run the following command to verify:

```bash
claude plugins list    # Confirm the plugin is in the list
/discover              # Run skill discovery (merged into universal-project-kickoff)
```

**Linking Hook (executed only when PACKAGE_MODE = true):**

After installation, scan sibling skills' `capabilities` for matches against `integrates_with: skill-discovery`:
- Match found → Prompt the user: "Installation complete. Would you like to run **Project Kickoff and Capability Discovery** to scan the current project and see how the newly installed capabilities match your tech stack?"
- User agrees → Trigger the skill discovery flow

### 6. Common MCP Server Quick Install Templates

Built-in configuration templates for several commonly used MCP Servers, simplifying installation:

#### GitHub MCP Server

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "<your-github-token>"
      }
    }
  }
}
```

#### Context7 MCP Server

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

#### Playwright MCP Server

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp-server"]
    }
  }
}
```

More templates can be found in `references/mcp-templates.md`.

## Error Handling

| Scenario | Handling Method |
|------|---------|
| Marketplace already registered | Skip registration step, install directly |
| Plugin already installed | Prompt the user and ask whether to reinstall/update |
| `claude` CLI not available | Guide the user to install Claude Code CLI first |
| `settings.json` does not exist | Automatically create the basic structure |
| `settings.json` format is corrupted | Back up the original file and rebuild |
| MCP Server fails to start | Check whether the command exists, network is reachable, and environment variables are set |
| Insufficient permissions | Prompt for admin privileges or use `sudo` |

## Scripts

- `scripts/check-mcp-updates.sh` — MCP Server update check script (checks GitHub/npm/pip for new versions)
- `scripts/toggle-autoupdate.sh` — Toggles the `autoUpdate` status for a specified source in `known_marketplaces.json`

## References

- `references/mcp-templates.md` — Complete configuration template library for common MCP Servers
