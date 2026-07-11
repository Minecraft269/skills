# Scanner Patterns Reference

Detailed reference for the universal-project-kickoff skill's scanning and matching engine (proactive-skill-discovery capabilities merged here).

## Project Fingerprint Detection Map

Complete mapping of project files to technology tags, organized by ecosystem:

### Java Ecosystem

| Detection File(s) | Tags |
|-------------------|------|
| `pom.xml` with `spring-boot-starter-parent` | `java`, `spring-boot`, `maven` |
| `pom.xml` with `quarkus` | `java`, `quarkus`, `maven` |
| `pom.xml` (generic) | `java`, `maven` |
| `build.gradle` / `build.gradle.kts` with `spring-boot` plugin | `java`/`kotlin`, `spring-boot`, `gradle` |
| `build.gradle` / `build.gradle.kts` (generic) | `java`/`kotlin`, `gradle` |
| `src/main/java/` exists | `java` |
| `src/main/kotlin/` exists | `kotlin` |
| `application.properties` / `application.yml` | `spring-boot` |
| `persistence.xml` or `@Entity` in source | `jpa`, `hibernate` |

### Node.js / Frontend Ecosystem

| Detection File(s) | Tags |
|-------------------|------|
| `package.json` with `react` dep | `javascript`/`typescript`, `react`, `nodejs` |
| `package.json` with `vue` dep | `javascript`/`typescript`, `vue`, `nodejs` |
| `package.json` with `angular` dep | `javascript`/`typescript`, `angular`, `nodejs` |
| `package.json` with `next` dep | `javascript`/`typescript`, `nextjs`, `react` |
| `package.json` with `svelte` dep | `javascript`/`typescript`, `svelte` |
| `package.json` with `express` dep | `javascript`/`typescript`, `express`, `backend` |
| `package.json` with `tailwindcss` dep | `tailwind-css` |
| `tsconfig.json` | `typescript` |
| `vite.config.*` | `vite` |
| `next.config.*` | `nextjs` |
| `tailwind.config.*` | `tailwind-css` |
| `astro.config.*` | `astro` |
| `.eslintrc.*` / `eslint.config.*` | `eslint` |
| `.prettierrc*` | `prettier` |

### Python Ecosystem

| Detection File(s) | Tags |
|-------------------|------|
| `pyproject.toml` with `django` dep | `python`, `django` |
| `pyproject.toml` with `fastapi` dep | `python`, `fastapi` |
| `pyproject.toml` with `flask` dep | `python`, `flask` |
| `pyproject.toml` (generic) | `python` |
| `requirements.txt` with `django` | `python`, `django` |
| `requirements.txt` with `fastapi` | `python`, `fastapi` |
| `requirements.txt` (generic) | `python` |
| `setup.py` / `setup.cfg` | `python` |
| `Pipfile` | `python`, `pipenv` |

### Rust Ecosystem

| Detection File(s) | Tags |
|-------------------|------|
| `Cargo.toml` with `actix-web` dep | `rust`, `actix`, `backend` |
| `Cargo.toml` with `rocket` dep | `rust`, `rocket`, `backend` |
| `Cargo.toml` with `axum` dep | `rust`, `axum`, `backend` |
| `Cargo.toml` with `tauri` dep | `rust`, `tauri`, `desktop` |
| `Cargo.toml` (generic) | `rust` |

### Go Ecosystem

| Detection File(s) | Tags |
|-------------------|------|
| `go.mod` with `gin-gonic/gin` | `go`, `gin`, `backend` |
| `go.mod` with `echo` | `go`, `echo`, `backend` |
| `go.mod` with `fiber` | `go`, `fiber`, `backend` |
| `go.mod` (generic) | `go` |

### Other Languages

| Detection File(s) | Tags |
|-------------------|------|
| `Gemfile` | `ruby` |
| `composer.json` | `php` |
| `*.sln` / `*.csproj` / `*.fsproj` | `csharp`/`fsharp`, `dotnet` |
| `CMakeLists.txt` | `c`/`cpp`, `cmake` |
| `Makefile` | `make`, (supplemental) |

### Mobile Ecosystem

| Detection File(s) | Tags |
|-------------------|------|
| `pubspec.yaml` with `flutter` dep | `flutter`, `dart`, `mobile`, `cross-platform` |
| `react-native.config.js` | `react-native`, `mobile`, `javascript`/`typescript` |
| `metro.config.js` | `react-native`, `mobile` |
| `app.json` with `expo` key | `expo`, `react-native`, `mobile`, `typescript` |
| `package.json` with `react-native` dep | `react-native`, `mobile`, `javascript`/`typescript` |
| `ionic.config.json` | `ionic`, `mobile`, `cross-platform`, `angular`/`react`/`vue` |
| `Podfile` | `ios`, `cocoapods`, `mobile` |
| `android/` directory (top-level) | `android`, `mobile` |
| `ios/` directory (top-level) | `ios`, `mobile` |

### DevOps / Infrastructure

| Detection File(s) | Tags |
|-------------------|------|
| `Dockerfile` | `docker`, `container` |
| `docker-compose.yml` / `docker-compose.yaml` | `docker`, `orchestration` |
| `kubernetes/` / `k8s/` dir with `*.yaml` | `kubernetes` |
| `.github/workflows/*.yml` | `github-actions`, `ci-cd` |
| `terraform/*.tf` | `terraform`, `infra` |
| `.env.example` / `.env.template` | (supplemental) |

### Language Version Detection

When a language is detected, extract the version for more precise recommendations (a Java 8 project should not get Java 21 tooling recommendations). Version information is read from these files and appended as a versioned tag (e.g., `java-8`, `python-3.12`, `node-22`):

| Version Source | Language | Format Example |
|---------------|----------|---------------|
| `pom.xml` `<java.version>` or `<maven.compiler.source>` | Java | `java-8`, `java-17`, `java-21` |
| `build.gradle(.kts)` `sourceCompatibility` | Java/Kotlin | `java-17`, `kotlin-1.9` |
| `package.json` `engines.node` | Node.js | `node-18`, `node-22` |
| `pyproject.toml` `requires-python` | Python | `python-3.9`, `python-3.12` |
| `go.mod` `go` directive | Go | `go-1.21`, `go-1.23` |
| `Cargo.toml` `[package] edition` | Rust | `rust-2021`, `rust-2024` |
| `.java-version` | Java | `java-17` |
| `.node-version` | Node.js | `node-20` |
| `.python-version` | Python | `python-3.11` |
| `.ruby-version` | Ruby | `ruby-3.2` |
| `rust-toolchain.toml` or `rust-toolchain` | Rust | `rust-1.76` |

**Usage:** Version tags supplement the base language tags for scoring. A skill tagged `java-17` gets a +3 bonus on a Java 17 project but only +1 on a Java 8 project (partial match via base `java` tag). Skills with only `java` (no version) match all Java versions with +3.

## Skill-to-Project Matching Algorithm

### Scoring Formula

```
total_score = Σ(tag_match_score) + framework_match_score + category_bonus + always_bonus - never_penalty
```

Weights are configurable via `~/.claude/skills/.discovery-rules.json` → `scoring_weights`. Built-in defaults (used when no rules file exists):

| Weight | Default | Description |
|--------|---------|-------------|
| tag_match | 3 | Per matching technology tag |
| framework_match | 3 | Framework name match |
| category_bonus | 1 | Category aligns with project domain |
| always_bonus | 10 | Skill/plugin in always_recommend list |
| never_penalty | -999 | Skill/plugin in never_recommend list |

### Category Alignment Table

| Project Domain | Matching Skill Categories |
|----------------|--------------------------|
| Frontend (React/Vue/Angular) | `dev` (frontend-* prefixed), `ui` |
| Backend (Java/Go/Python/Rust API) | `dev` (backend-* prefixed), `ops`, `database` |
| Full-stack | `dev`, `ui`, `ops`, `database` |
| Data Science / ML | `dev` (python-* prefixed), `data` |
| DevOps / Infra | `ops`, `dev` (docker-*/k8s-* prefixed) |
| Mobile | `dev` (swift-*/kotlin-*/flutter-* prefixed) |
| Game Dev | `dev` (unity-*/godot-*/unreal-* prefixed) |
| Unknown/General | All, prefer `meta` and generic `dev` |

## Plugin-to-Project Matching Algorithm

### MCP Plugin Scoring

| Match Type | Score | Example |
|------------|-------|---------|
| Plugin name matches project toolchain | +3 | `postgres` plugin for PostgreSQL project |
| Plugin provides project-relevant capability | +1 | `playwright` for frontend, `context7` for any dev |
| Domain-adjacent | +1 | `github` for any dev project |
| Generic/utility | +0 | All plugins have at minimum this score |

### Known Plugin Mappings

| MCP Plugin | Best For Project Types |
|------------|----------------------|
| `plugin:github:github` | All dev projects |
| `plugin:playwright:playwright` | Frontend, E2E testing |
| `plugin:context7:context7` | Any framework/library heavy project |
| `plugin:longhand:longhand` | All projects (session history) |
| Database plugins (`postgres`, `mysql`, etc.) | Backend, data projects |

## Discovery Rules JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "always_recommend": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Skills that always appear at the top of recommendations"
    },
    "never_recommend": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Skills that are always excluded from recommendations"
    },
    "always_recommend_plugins": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Plugins that always appear at the top of recommendations"
    },
    "never_recommend_plugins": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Plugins that are always excluded from recommendations"
    },
    "category_weights": {
      "type": "object",
      "properties": {
        "dev": { "type": "number", "default": 3 },
        "ops": { "type": "number", "default": 1 },
        "meta": { "type": "number", "default": 0 }
      },
      "description": "Score multipliers per category"
    },
    "export_defaults": {
      "type": "object",
      "properties": {
        "language": { "type": "string", "default": "zh" },
        "format": { "type": "string", "enum": ["markdown", "json", "plaintext"], "default": "markdown" }
      },
      "description": "Default settings for the export feature"
    },
    "max_recommendations": {
      "type": "number",
      "default": 10,
      "description": "Maximum number of recommendations to display"
    },
    "cache_ttl_hours": {
      "type": "number",
      "default": 24,
      "description": "Hours before cached scan results expire and require a fresh scan"
    }
  }
}
```

## Filter Rules

### Built-in Defaults

When no `~/.claude/skills/.discovery-rules.json` exists, the engine uses these built-in defaults:

| List | Default Entries | Rationale |
|------|----------------|-----------|
| `always_recommend` | `universal-project-kickoff`, `github-pr-manager` | Hub skill for all projects + broadly useful PR management |
| `never_recommend` | (empty) | No hard exclusions by default |
| `always_recommend_plugins` | `github`, `context7` | Version control (universal) + documentation lookup (universal) |
| `never_recommend_plugins` | (empty) | No hard exclusions by default |

Users can override any default by creating their own rules file. The `discovery-rules.example.json` in this skill's references directory provides a ready-to-copy template.

### How Filters Work

1. Load `~/.claude/skills/.discovery-rules.json` if it exists; if not, use built-in defaults above
2. Merge user overrides with built-in defaults (user values take precedence)
3. Apply `never_recommend` / `never_recommend_plugins` as hard exclusions (removed before scoring)
4. After scoring, prepend `always_recommend` / `always_recommend_plugins` entries at the top
5. Truncate to `max_recommendations` count

## Export File Naming Convention

```
{project-name}-skills-plugins-export.{format}

Examples:
- auto-skills-skills-plugins-export.md
- my-frontend-app-skills-plugins-export.json
- unknown-project-skills-plugins-export.txt
```

## Performance Notes

- Scanning ~1000 skill directories: estimated 2-5 seconds using parallel Glob + Grep
- MCP configuration read: near-instant (single file read)
- Matching and scoring: O(S * T) where S = skills count, T = project tags (typically <50ms for 1000 skills × 10 tags)
- Full export generation: O(S) file writes, ~1-3 seconds for 1000 entries

To keep the interactive experience responsive, always:
1. Parallelize skill scanning and plugin scanning
2. Cache scan results within a session (don't re-scan on repeated `/discover` calls):
   - Store `_SCAN_CACHE = { timestamp, fingerprint, ttl_hours }` in session context after scan completes
   - On subsequent calls, check if cache exists and `(now - timestamp) < ttl_hours` (default 24h, configurable via `.discovery-rules.json` → `cache_ttl_hours`)
   - If cache is valid, skip 0c-1 and 0c-2 entirely, reuse cached results
   - If cache expired or absent, perform full scan
3. Limit initial display to top 5-10; lazy-load "show more" on request

---

## Command Discovery Reference

### MCP Tool Discovery

MCP tools are discovered by identifying the `mcp__*` prefix in system prompts.

#### Discovery Method

1. **Extract from system prompts:** Scan the tool list in `<system-reminder>`, identify all functions with `mcp__` prefix
2. **Use ListMcpResourcesTool:** Invoke the built-in MCP to view all connected server resources
3. **Read from settings.json:** Parse `mcpServers` for the server list
4. **Get schema from the tool list:** A tool's parameter schema reflects its capabilities

#### MCP Tool Naming Convention

```
mcp__plugin_{server-name}_{server-name}__{tool-name}
or
mcp__{server-name}__{tool-name}

Examples:
- mcp__plugin_github_github__create_pull_request  → GitHub plugin → create_pull_request tool
- mcp__plugin_context7_context7__query-docs       → Context7 plugin → query-docs tool
- mcp__longhand__recall                           → Longhand plugin → recall tool
```

#### MCP Tool → Use Case Inference Rules

| Tool Name Pattern | Inferred Purpose | Inferred Use Case |
|-------------------|-----------------|-------------------|
| `create_*` | Create resources | When creating new PRs/Issues/branches/files |
| `search_*` | Search / find | When searching for code/docs/users |
| `get_*` / `read_*` | Read / retrieve | When viewing details/content |
| `list_*` | List collections | When browsing lists/directories |
| `update_*` / `edit_*` | Modify resources | When updating config/content |
| `delete_*` / `remove_*` | Delete resources | When removing files/resources |
| `query-*` | Query documentation | When looking up API/framework docs |
| `recall` / `find_*` | Recall / memory lookup | When searching session history/memory |
| `replay_*` | Replay / trace back | When tracing historical state |
| `resolve-*` | Resolve / lookup ID | When looking up library IDs |

### Slash Command Discovery

Slash commands are listed in system prompts in the format `- name: description`.

#### Discovery Method

1. Scan the "available skills" / slash commands section in system prompts
2. Command format: `- command-name: Description text`
3. After extraction, categorize by function

#### Slash Command Categories

| Category | Typical Commands | General Use Case |
|----------|-----------------|------------------|
| **Git Operations** | `/commit`, `/create-pr`, `/create-branch`, `/git-pushing`, `/clean_gone` | Code version management |
| **Code Review** | `/code-review`, `/review`, `/simplify`, `/security-review` | Code quality assurance |
| **Development Workflow** | `/tdd`, `/feature-dev`, `/init`, `/setup` | Formal development process |
| **Debugging & Verification** | `/debug`, `/verify`, `/lint`, `/test` | Issue troubleshooting and fix verification |
| **Research Work** | `/deep-research`, `/analyze`, `/explain` | Requirements analysis and research |
| **Session Management** | `/discover`, `/clear`, `/loop`, `/exit`, `/schedule` | Session interaction control |
| **Configuration Management** | `/config`, `/keybindings`, `/update-config`, `/install` | Environment and personal settings |
| **Documentation & Writing** | `/write-plan`, `/write-skill`, `/generate-docs` | Document creation and maintenance |
| **Automation** | `/hookify`, `/cron`, `/workflow` | Automated workflows |

#### Command-to-Project Matching

| Project Phase | Most Useful Slash Commands |
|---------------|---------------------------|
| **Project Initiation** | `/init`, `/setup`, `/discover` |
| **Daily Development** | `/commit`, `/feature-dev`, `/code-review` |
| **Debug & Fix** | `/debug`, `/verify`, `/test` |
| **Code Review** | `/review`, `/simplify`, `/code-review`, `/security-review` |
| **Release Preparation** | `/create-pr`, `/lint`, `/verify` |
| **Learning & Exploration** | `/explain`, `/analyze`, `/deep-research` |
| **Session Management** | `/clear`, `/loop`, `/exit`, `/discover` |

### Command Matching Algorithm

```
For each MCP tool:
  score = 0
  if tool parent plugin is matched (from Step 3 plugin matching):
    score += 3  # plugin is relevant, its tools are relevant
  if tool name pattern matches project toolchain:
    score += 2  # e.g., query-docs for framework-heavy project
  if tool is general-purpose (github, longhand):
    score += 1  # useful but not project-specific

For each Slash command:
  score = 0
  if command category matches project phase:
    score += 2  # e.g., /commit during dev, /create-pr during release prep
  if command is always useful:
    score += 1  # e.g., /discover, /code-review, /clear

Commands with score >= 1 are DISPLAYED (not filtered out).
Display ALL slash commands organized by category.
Display MCP tools organized by parent plugin.
```

### Command Discovery Performance

- MCP tool discovery via system prompt scan: near-instant (text matching)
- Slash command discovery via system prompt scan: near-instant (text matching)
- Total command catalog construction: <100ms for typical session

---

## Deep Exploration Reference

Some plugins contain critical files that are NOT automatically loaded or indexed — they exist on disk but Claude Code won't discover them unless explicitly scanned during the capability inventory step.

**The plugin list below is the built-in default.** It can be overridden by setting `deep_explore_plugins` in `~/.claude/skills/.discovery-rules.json`. If the rules file exists and defines this field, its values replace the defaults below entirely.

### Priority Plugins & Unindexed Resources (Defaults)

| Plugin | Unindexed Key Files | Type |
|--------|-------------------|------|
| `everything-claude-code` (ECC) | SOUL.md, RULES.md, AGENTS.md, CLAUDE.md, COMMANDS-QUICK-REF.md, WORKING-CONTEXT.md, the-security-guide.md, agent.yaml | Behavioral rules, security guides, agent configs |
| `superpowers` | AGENTS.md, CLAUDE.md, GEMINI.md, hooks/hooks.json | Multi-platform agent behavior configs, hooks |
| `andrej-karpathy-skills` | CLAUDE.md, CURSOR.md, .cursor/rules/karpathy-guidelines.mdc, skills/karpathy-guidelines/SKILL.md | Coding guidelines, nested skills, Cursor rules |
| `oh-my-claudecode` | .agents/skills/\*/\*.md (dozens of nested skills) | Plugin-internal skills (may not appear in `~/.claude/skills/`) |

### How to Deep-Explore

1. For each priority plugin in `~/.claude/plugins/`, list root-level `.md`, `.json`, `.yaml`, `.yml`, `.mdc` files (skip `node_modules`, `.git`, `package-lock.json`)
2. Read the first 5-10 lines of each `.md` file to identify its purpose (SOUL/RULES/AGENTS/CLAUDE/etc.)
3. For nested skills (`.agents/skills/*/SKILL.md`), read frontmatter same as normal skill scan (Step 2a)
4. For `.mdc` (Cursor rules) files, extract rule name and description

### Deep Resources Output Format

Each discovered resource is tagged with `source: deep-exploration` and `plugin: <plugin-name>`. Each entry has: name, type (soul/rules/agents/claude-md/commands-ref/nested-skill), description, and path.

**Parallelize with Steps 2a and 2b.** Run all three scans concurrently for responsive performance.

---

## Priority Boost System

Certain plugins provide foundational capabilities that enhance ALL workflows. When detected during the capability inventory, they receive a **+10 priority boost** to guarantee top placement — regardless of project match score.

**The plugin list below is the built-in default.** It can be overridden by setting `priority_boost_plugins` in `~/.claude/skills/.discovery-rules.json`. If the rules file exists and defines this field, its values replace the defaults below entirely.

| Priority Plugin | Boost Reason |
|----------------|-------------|
| `everything-claude-code` (ECC) | Claude Code's "OS-level" plugin — provides SOUL/RULES/AGENTS behavioral rules, nested skills, security guides |
| `superpowers` | Core workflow skills (TDD/debugging/planning/code review) + multi-platform adaptation |
| `andrej-karpathy-skills` | Karpathy coding guidelines — elevates all code output quality |
| Any deep resource from Deep Exploration | Discovered unindexed resources (SOUL/RULES/nested skills) that enhance all workflows |

**How the boost works:**
1. After normal scoring (tag_match + framework_match + category_bonus + always_bonus - never_penalty), check if any of the above plugins/resources exist
2. If found: their base score = max(normal_score, 10), placing them at or near the top
3. Mark them with ⭐ in the recommendation display to indicate priority status

**Output structure — three separate lists (always in this order):**
1. ⭐ Priority Recommendations (boosted plugins/resources — always first)
2. 📋 Recommended Skills (top 5-10, project-matched)
3. 🔌 Recommended Plugins (top 3-5, project-matched)

Store remaining unmatched items separately for the full export step.

---

## Discovery Rules — Extended Fields

The following fields extend the base JSON schema (see Discovery Rules JSON Schema above) to control command visibility, priority boosting, and deep exploration:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `always_show_commands` | string[] | `[]` | Slash commands that always appear in command discovery output |
| `never_show_commands` | string[] | `[]` | Slash commands excluded from command discovery output |
| `priority_boost_plugins` | string[] | `["everything-claude-code", "superpowers", "andrej-karpathy-skills"]` | Plugins that receive +10 priority boost |
| `deep_explore_plugins` | string[] | `["everything-claude-code", "superpowers", "andrej-karpathy-skills", "oh-my-claudecode"]` | Plugins to deep-explore for unindexed resources |
| `deep_explore_patterns` | string[] | `["SOUL.md", "RULES.md", "AGENTS.md", "CLAUDE.md", "COMMANDS-QUICK-REF.md", "WORKING-CONTEXT.md", "the-security-guide.md", "agent.yaml", ".cursor/rules/*.mdc"]` | File patterns to match during deep exploration |

---

## Export Field Definitions

When generating a full export, use these field tables:

**Per Skill:** name, category (dev/meta/ops), source (community/official/custom), description, use-case tags, file path

**Per Plugin:** name, type (stdio/sse/http), command/executable, description, source (MCP config / local plugin directory)

**Per MCP Tool:** tool name, parent plugin, purpose, use case

**Per Slash Command:** command (/name), purpose, use case, category (Git/Review/Dev/Debug/Session/Config)

---

## Future Skill & Plugin Sources

The scanning logic in Step 2 is designed to be extensible. When new sources emerge (marketplace APIs, team-shared repositories, remote registries, OCI artifacts), extend the capability inventory by:
1. Adding the new source URL/endpoint to scan targets
2. Following the same metadata extraction pattern (name, description, tags, category, source)
3. Appending discovered items to the combined recommendation pool

---

## Critical Execution Rules

1. **Correct order** — Step 0c-1→2→3→4 (recommend, ask user) → Step 0c-5 (only after selection, show commands) → Step 0c-6 (export) → Step 0c-7 (persist)
2. **Deep exploration is REQUIRED** — always deep-scan ECC/superpowers/andrej-karpathy/OMC for SOUL.md, RULES.md, AGENTS.md, nested skills, and other unindexed resources
3. **Priority boost** — ECC, superpowers, andrej-karpathy-skills, and any deep resources always get ⭐ top placement
4. **Step 0c-5 commands come AFTER selection** — never show MCP tools or slash commands in Step 0c-4's initial recommendation
5. **Each command MUST include "purpose" and "use case"** — describe what it does and when to use it
6. **Step 0c-4 is MANDATORY** — always ask user after displaying recommendations
7. **Step 0c-6 requires consent** — always ask before exporting
8. **Respect "skip"** — don't re-recommend in the same session unless project context changes significantly
9. **Be concise** — show top 5-10 matches; offer "show more" option; never dump 100+ entries at once
