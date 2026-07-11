# universal-project-kickoff

Universal project kickoff and capability discovery rules — suitable for any project type's startup phase, executing intent detection + 7-step capability discovery + mandatory 6-step process.

Has absorbed all functionality of the former `proactive-skill-discovery` (that skill has been deleted). New Fork mode: participate in open-source contributions (fork → clone → develop → PR).

## Core Flow

### Step 0: Intent Detection
First pre-detect user intent via keyword matching (start project/develop feature/review code/fix bug/explore tools). If a unique intent matches, route directly; only show AskUserQuestion when intent is ambiguous. Routing:

| Intent | Behavior |
|--------|----------|
| 🚀 Start New Project | Step 0b language/framework confirmation → mandatory 6-step process → capability discovery |
| 💻 Develop Feature | Step 0c tech stack confirmation → dev tool recommendations |
| 🔍 Review Code | Step 0a 5-layer follow-up → Step 0c review tool recommendations |
| 🐛 Fix Bug | Step 0a target confirmation → Step 0c debugging tool recommendations |
| 🍴 Fork Project | Step 0a-fork 5 sub-steps (get repo → fork → clone → project analysis → contribution guidance) |
| 🔧 Explore Tools | Step 0c full 7-step capability scan |

### Step 0c: 7-Step Capability Discovery

| Sub-step | Content |
|----------|---------|
| 0c-1 | Project fingerprint scan (25+ config files + language version detection + mobile frameworks) |
| 0c-2 | Parallel capability inventory (read .discovery-rules.json config, then 3-way parallel scan: Skills + Plugins + Deep Exploration) |
| 0c-3 | Match and rank (scoring engine + Priority Boost bonus + intent-based filtering) |
| 0c-4 | Interactive recommendation (5 options + 3-column display + linkage hooks) |
| 0c-5 | Command discovery (MCP tools + Slash commands, triggered only on user selection) |
| 0c-6 | Full export (3 questions: directory/language/format, Markdown/JSON/plain text) |
| 0c-7 | Context persistence (skip recording + fingerprint-change re-discovery) |

### Mandatory 6-Step Process (Starting New Projects)

| Step | Content | Output |
|------|---------|--------|
| 1 | Clarify "why" and "what" | One-sentence project definition + success criteria |
| 2 | Define boundaries | MVP scope, triple constraint |
| 3 | Quick risk assessment | Top 3 risks + Plan B |
| 4 | Stakeholder alignment | Core circle / influence circle / periphery circle |
| 5 | Draw roadmap | 3-5 milestones + acceptance criteria |
| 6 | Generate CLAUDE.md | Call /init to persist outcomes |

## Use Cases

- New project startup
- Feature planning
- AI Agent design
- Project plan review
- Code review tool recommendations
- Debugging tool recommendations
- Skill/plugin/command exploration
- Fork open-source projects and contribute PRs

## Core Principle

**Fire first, aim later — but before you fire, at least know which direction the target is in.** Complete critical decisions within 15 minutes to avoid rework.

## Related Skills

This skill is part of the [minecraft269-skills](https://github.com/Minecraft269/skills) plugin package. When the full package is installed, this skill can auto-link with other package skills:

- After identifying tech stack, suggests installing relevant MCP Servers
- After CLAUDE.md generation, suggests scanning tech stack for matching skill recommendations
- Triggered by PR Manager after cloning unfamiliar projects, helping new contributors quickly understand the project

When installed standalone, the above linkage features are silently disabled, with no impact on core flow.
