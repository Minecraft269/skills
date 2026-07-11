# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Definition

Solving the pain points of cross-project skill reuse and proactive tool discovery for developers using Claude Code, through continuous creation and maintenance of high-quality Claude Code skills distributed via Marketplace. Create whatever comes to mind; community contributions are welcome. No restrictions, but skills involving external APIs, paid services, or sensitive operations must be declared in frontmatter.

## Project Structure

```
.claude-plugin/                  # Plugin manifest + Marketplace registration
├── plugin.json
└── marketplace.json
.github/                          # CI/CD configuration
└── workflows/
    └── skill-health.yml          # Frontmatter format validation + tag consistency check
docs/                            # Skill documentation (README links point here), one per skill
skills/                          # All skills (one subdirectory per skill)
├── _shared/                      # Package-level shared resources (detection protocol, common templates, i18n glossary)
├── universal-project-kickoff/   # Universal project kickoff & capability discovery (absorbed proactive-skill-discovery, includes Fork mode)
│   └── references/               # 7 reference files
├── github-pr-manager/           # GitHub PR full-featured manager
├── github-pr-reviewer/          # GitHub PR reviewer (line-by-line inline comments)
├── quick-plugin-installer/      # Quick plugin installer (MCP + SKILL)
├── git-commit-helper/           # Git commit standardization helper (Conventional Commits)
└── env-health-check/            # Cross-platform environment health check
CONTRIBUTING.md                  # Contribution guide (capability tag registry + tag decision tree)
```

## Quick Start

```bash
git clone https://github.com/Minecraft269/skills.git
cd skills
find skills/ -name "*.sh" -exec bash -n {} \;   # Shell syntax check
grep -oP 'capabilities:\s*\[\K[^\]]+' skills/*/SKILL.md | tr '"' '\n' | sort -u   # Tag consistency
```

## Creating New Skills

**You must use `/skill-creator` to create new skills.** Confirm the skill-creator plugin is installed first.

After creation, place the skill directory into `skills/<skill-name>/`. Each skill must contain at least a `SKILL.md` (YAML frontmatter + Markdown body). Simultaneously create skill documentation at `docs/<skill-name>.md`.

## Code Style

- Indentation: 2 spaces (consistent with skill-creator generated standard)
- Comments: header documents purpose and usage, key logic gets comments, self-explanatory code stays comment-free
- Skill directory naming: `kebab-case` (e.g. `github-pr-manager`)
- frontmatter `name`: matches directory name
- frontmatter `version`: skill version number, SemVer recommended (e.g. `"3.0.0"`), used for tracking breaking changes
- frontmatter `risk`: operational risk level (`safe` / `medium` / `high`); skills involving external APIs, paid services, or sensitive operations must declare this
- frontmatter `source`: origin identifier (`community` / `official` / `custom`), used for Marketplace categorization
- frontmatter linkage fields: `capabilities` (capabilities provided), `integrates_with` (capabilities needed for coordination) — optional, used for intra-package dynamic skill discovery
- Script files: `snake_case.sh`
- All user-facing content uses English; technical terms remain in English
- Cross-skill references must be gated by PACKAGE_MODE detection; silently degrade when installed standalone
- `.discovery-rules.json` override convention — hardcoded defaults for `deep_explore_plugins`, `priority_boost_plugins`, `cache_ttl_hours` and other fields can be overridden by `~/.claude/skills/.discovery-rules.json`. When modifying defaults, update three locations simultaneously: SKILL.md (Step 0c-2 config reading section), scanner-patterns.md (default value annotations), and discovery-rules.json JSON Schema

## Risks and Contingency Plans

| Risk | Plan B |
|------|--------|
| Compliance pitfalls (license conflicts, unauthorized code references) | License review before each new skill release; unified tool dependency declarations |
| Claude Code version upgrade causing skill incompatibility | Document minimum compatible version in skill; run core paths first after new release |
| Community contribution chaos (uneven PR quality, inconsistent style) | CONTRIBUTING.md + PR template gatekeeping; core skills self-reviewed |

## Roadmap

M1–M7 all completed ✅ — through Marketplace availability, extension hardening, skill linkage, capability merging, quality review, logic fixes, review enhancement. Current phase: ongoing feature expansion (e.g. v4.0.0 Fork mode).

## Local Verification

Run these commands before committing to ensure CI passes:

```bash
# Shell syntax check
find skills/ -name "*.sh" -exec bash -n {} \;

# Manual tag consistency verification (CI runs this automatically)
# Note: grep -oP requires GNU grep (Linux); macOS BSD grep does not support -P, use brew install grep or CI verification
grep -oP 'capabilities:\s*\[\K[^\]]+' skills/*/SKILL.md | tr '"' '\n' | sort -u
# Compare against the tag registry in CONTRIBUTING.md
```

## Release Workflow

```bash
# 1. Local verification: frontmatter completeness + tag consistency + ShellCheck
find skills/<name>/ -name "*.sh" -exec bash -n {} \;
grep -oP 'capabilities:\s*\[\K[^\]]+' skills/*/SKILL.md | tr '"' '\n' | sort -u

# 2. Commit and push (must update 4 files simultaneously, see "New Skill Registration Checklist")
git add skills/<name>/ docs/<name>.md CONTRIBUTING.md README.md
git commit -m "feat: add <name> skill"
git push

# If you need to sync README/docs after committing, use amend:
git add README.md docs/<name>.md
git commit --amend --no-edit
git push --force-with-lease origin <branch>

# 3. Marketplace auto-syncs after pushing to GitHub
```

## Prerequisites

Users installing this plugin need:
- Claude Code CLI
- Prerequisite tools declared by each skill (e.g. `gh`, `git`, `jq`)

## Development Notes

- `.git/info/exclude` — personal local directories (`.omc/`, `.remember/`, `.impeccable/`) go here; do not commit to `.gitignore`
- worktree commits — if git commands are unavailable in a worktree created by `EnterWorktree` (`not a git repository`), use `GIT_DIR=../.git GIT_WORK_TREE=<path> git ...` as a workaround
- Post-push local sync — after committing and pushing through a worktree, the main repo worktree will be detached; run `git fetch && git reset --hard origin/main` to sync (`git restore .` only restores files, does not move the branch pointer)
- Do not append `Co-Authored-By` trailer

## New Skill Registration Checklist

Creating a new skill requires updating 4 files simultaneously:

1. `skills/<name>/SKILL.md` — skill definition (~150 lines, includes frontmatter + package linking + core workflow + error handling)
2. `CONTRIBUTING.md` — register new capability tag at the end of the "Capability Tag Registry" table
3. `README.md` — add a row to the "Skill List" table (before the license)
4. `docs/<name>.md` — concise documentation (~40 lines, intro + prerequisites + trigger + workflow + interactive options)

Purely AI-driven skills do not need `scripts/` or `references/` directories.

## CI Notes

- `ludeeus/action-shellcheck@master` fails on warnings; all `*.sh` must pass `bash -n` + ShellCheck with zero warnings
- CI validates consistency between the CONTRIBUTING.md tag registry and the `capabilities` fields of all `skills/*/SKILL.md`
