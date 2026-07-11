# env-health-check

Cross-platform detection of core tool availability (git, gh, jq, claude, etc.), outputting a formatted health report.

## Trigger

Say "check environment", "env health check", or "is my toolchain ready" to trigger.

## Detection Scope

| Category | Items Checked |
|----------|---------------|
| Core Dependencies | git, gh, jq, claude, node, python |
| Service Status | gh auth, MCP Server configuration |
| Install Suggestions | Win/macOS/Linux install commands for missing tools |

## Workflow

1. Run `command -v` + `--version` for all tools in parallel
2. Check `gh auth status` and MCP configuration
3. Output formatted health report (✅/⚠️/❌)

## Linkage

- Missing tools → suggest **Plugin Installer**
- Environment ready → suggest **Skill Discovery**
