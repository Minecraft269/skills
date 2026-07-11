# Contribution Guide


> 🌐 [中文版本](CONTRIBUTING.cn.md)
Thank you for your interest in Minecraft269 Skills! This document helps you understand how to contribute.

## Quick Start

1. **Fork** this repository
2. Create a feature branch: `git checkout -b feat/your-skill-name`
3. Submit a PR to the `main` branch after development
4. Wait for maintainer review

## Creating New Skills

**Recommended approach: Use the `skill-creator` skill to create.**

> ⚠️ Confirm the `skill-creator` plugin is installed before use. If not installed, install it in Claude Code first.

After confirming installation, run `/skill-creator` in Claude Code. It will guide you through the standard skill creation process. After creation, place the generated skill directory into `skills/<skill-name>/`.

### Skill Directory Structure

```
skills/
├── _shared/               # Package-level shared resources
│   ├── package-context.md # Package context detection protocol
│   ├── i18n-glossary.md   # EN↔CN terminology glossary
│   └── ...
├── <skill-name>/          # Single skill directory
│   ├── SKILL.md           # Skill entry file (required)
│   ├── locale/            # Chinese translations (reference only)
│   │   └── SKILL.cn.md
│   ├── references/        # Reference materials (optional)
│   │   └── *.md
│   ├── scripts/           # Executable scripts (optional)
│   │   └── *.sh
│   └── README.md          # Skill description (optional)
└── ...
```

### SKILL.md Format

- Use YAML frontmatter (wrapped in `---`), containing `name` and `description` fields
- Optional fields: `version`, `capabilities`, `integrates_with`
- Body uses Markdown, primarily in English
- Code blocks annotated with language type
- Indentation uses 2 spaces

### Naming Conventions

- Skill directory: `kebab-case` (e.g. `github-pr-manager`)
- frontmatter `name`: matches directory name
- Script files: `snake_case.sh`

### Skill Linkage Specification

This plugin package supports inter-skill coordination. All cross-skill references must follow these specifications.

#### Package Context Detection

Each skill must detect whether it is in a full plugin package environment:

1. Glob search for `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. Found → **High-Contact Mode** (`PACKAGE_MODE = true`), can reference sibling skills
3. Not found → **Standalone Mode** (`PACKAGE_MODE = false`), silently skip all cross-skill references

See `skills/_shared/package-context.md` for details.

#### Frontmatter Linkage Fields

Declare linkage intent in the SKILL.md YAML frontmatter:

```yaml
capabilities: ["<capability tag>", ...]     # Capabilities this skill provides
integrates_with: ["<required tag>", ...]     # Capability types needed for coordination
```

- `capabilities`: declares what this skill can do, for discovery by other skills
- `integrates_with`: declares what type of coordination this skill needs in its workflow
- Both fields are optional — skip linkage if not declared
- Tags should prioritize using existing tags (see registry below)

#### Conditional Linkage Writing

Add a "Package Linking" section in SKILL.md describing the PACKAGE_MODE detection logic. Linkage hooks are placed at the end of key workflow steps. If PACKAGE_MODE = false, skip linkage sections entirely.

#### Capability Tag Registry

New skills should prioritize using existing tags. If a new tag is needed, register it here.

**New Tag Creation Decision Tree:**

```
Need to declare a new capability?
  ├─ Search existing tags → semantic overlap → Reuse existing tag
  ├─ Existing tag is close → Prefer existing tag, clarify in description
  └─ No overlap → Create new tag, register at end of this table
```

| Tag | Semantics | Used By |
|------|----------|---------|
| `pr-management` | PR viewing/cloning/review/CI management | github-pr-manager |
| `ci-analysis` | CI status checking and failure analysis | github-pr-manager |
| `code-cloning` | Clone remote code locally and initialize environment | github-pr-manager |
| `skill-discovery` | Scan projects, discover and recommend matching capabilities | universal-project-kickoff |
| `capability-scanning` | Scan installed skills/plugins/MCP | universal-project-kickoff |
| `project-analysis` | Analyze project tech stack and structure | universal-project-kickoff |
| `plugin-installation` | Install MCP/SKILL plugins | quick-plugin-installer |
| `mcp-setup` | MCP Server configuration and verification | quick-plugin-installer |
| `project-setup` | Six-step decision process for project kickoff | universal-project-kickoff |
| `risk-assessment` | Project risk identification and contingency planning | universal-project-kickoff |
| `mvp-planning` | MVP scope definition and roadmap | universal-project-kickoff |
| `pr-review` | PR code review and inline comment workflow | github-pr-reviewer |
| `code-review` | Code quality review (general) | github-pr-reviewer |
| `inline-comments` | Line-by-line inline PR comment publishing | github-pr-reviewer |
| `git-commit` | Git commit standardization and commit message generation | git-commit-helper |
| `env-check` | Cross-platform environment health check and dependency diagnostics | env-health-check |
| `testing` | Test strategy, test frameworks, E2E testing (reserved) | — |
| `mobile-development` | Mobile development (reserved) | — |
| `security-audit` | Security review and vulnerability detection (reserved) | — |
| `debugging` | Debugging, root cause analysis, and error tracing (reserved) | — |
| `fork-workflow` | Complete contribution workflow: fork → local dev → submit PR | universal-project-kickoff |

### Commit Messages

Use conventional commit format:

```
feat: add xxx skill
fix: fix xxx issue
docs: update xxx documentation
refactor: refactor xxx
```

## Skill Review Standards

Before submitting a PR, confirm:

- [ ] SKILL.md includes complete frontmatter (name, description)
- [ ] `capabilities` and `integrates_with` declared (if applicable)
- [ ] Cross-skill references use PACKAGE_MODE gating, silently degrading standalone
- [ ] Skill can be triggered via `/` command
- [ ] External tools/dependencies declared in frontmatter
- [ ] No license-infringing content
- [ ] Core paths tested locally

## Reporting Issues

Submit via [GitHub Issues](https://github.com/Minecraft269/skills/issues):

- **Bug Reports**: Problem, reproduction steps, expected behavior
- **Feature Suggestions**: Use case and desired outcome
- **Skill Requests**: Skill needed and use case

## License

All contributions are under the [MIT License](LICENSE).
