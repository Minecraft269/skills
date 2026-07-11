# Minecraft269 Skills


> 🌐 [中文版本](README.cn.md)
A collection of Claude Code skills by Minecraft269 — create whatever comes to mind, community contributions welcome.

## Skill Linkage

When the full plugin package is installed, the six skills automatically discover each other and link at key workflow nodes:

- **Git Commit Helper** — after committing, suggests PR management when a GitHub remote exists; suggests code review when code changes are involved
- **Environment Health Check** — guides installation when missing tools are found; triggers capability discovery when environment is ready
- **Project Kickoff & Discovery** — pre-detects user intent via keywords (start/develop/review/fix/explore/Fork); asks when intent is ambiguous; code review supports local/remote PR, quick online review or clone-local deep review, with model confirmation before review; Fork mode supports fork → clone → analyze → contribution guide 5-step flow; new projects execute 6-step mandatory kickoff (MVP/risk/roadmap/CLAUDE.md); has absorbed former proactive-skill-discovery capabilities
- **PR Manager** — reminds new contributors to use project kickoff flow after cloning a PR; triggers capability discovery when detecting new project types
- **PR Reviewer** — shares context with PR Manager; suggests related actions after review completion
- **Plugin Installer** — after installation, automatically suggests running project kickoff and capability discovery

> 💡 If you installed a skill individually (not the full plugin package), linkage features are silently disabled; core functionality is unaffected.

---

## Installation

### Method 1: Marketplace Install (Recommended)

```bash
# 1. Register marketplace
claude plugins marketplace add Minecraft269/skills

# 2. Install plugin
claude plugins install minecraft269-skills
```

Restart Claude Code after installation.

After restart, run these commands to confirm successful installation:

```bash
claude plugins list                 # Confirm minecraft269-skills is in the list
/discover                            # Run skill discovery (merged into universal-project-kickoff, auto-scans project and recommends matching skills)
```

### Method 2: Manual Install

For offline environments or users who prefer direct management.

```bash
# 1. Clone the repository
git clone https://github.com/Minecraft269/skills.git

# 2. Copy to Claude Code plugins directory
cp -r skills ~/.claude/plugins/minecraft269-skills
```

Restart Claude Code and the plugin will be auto-loaded.

---

## Skill List

| Skill | Description |
|-------|-------------|
| [`universal-project-kickoff`](docs/universal-project-kickoff.md) | Universal project kickoff & capability discovery: intent detection + target confirmation + Fork mode (contribute to open source) + 7-step capability discovery + 6-step mandatory kickoff |
| [`github-pr-manager`](docs/github-pr-manager.md) | GitHub PR full-featured manager: list, view, clone, analyze PRs |
| [`quick-plugin-installer`](docs/quick-plugin-installer.md) | Quick plugin installer: unified entry point for MCP Server and SKILL plugins |
| [`github-pr-reviewer`](docs/github-pr-reviewer.md) | GitHub PR code reviewer: line-by-line inline comments, full pending review workflow |
| [`git-commit-helper`](docs/git-commit-helper.md) | Git commit standardization helper: auto-generates Conventional Commits messages based on staged diff |
| [`env-health-check`](docs/env-health-check.md) | Cross-platform environment health check: detects git/gh/jq/claude availability, outputs health report |

---

## License

MIT License — see [LICENSE](LICENSE)
