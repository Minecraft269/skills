---
name: universal-project-kickoff
description: >
  Universal project startup and capability discovery rules. Absorbs all capabilities from the former proactive-skill-discovery (which has been deleted).
  Added Fork Mode: participate in open-source contributions (fork → clone → develop → PR).
  This skill **must** trigger when the user says any of the following:
  "I want to start a new project", "Help me plan a new feature", "I want to launch an AI Agent",
  "How do I approach X", "Don't know where to start", "Help me scaffold something", "Project initialization",
  "Check my project plan", "Help me organize my thoughts", "How to start a new project",
  "Planning a side project", "Help me do project risk assessment",
  "What skills/plugins are available", "Recommend some tools", "/discover",
  "Help me review code", "Help me fix a bug", "I want to develop a new feature",
  "I want to participate in this open-source project", "Help me fork this repo", "I want to submit a PR to this project".
  This skill first detects user intent (start project / develop feature / review code / fix bug / explore tools / fork project),
  then routes to the corresponding sub-flow. When starting a new project, execute the mandatory six-step process (Why-What-Boundary-Risk-Stakeholders-Milestones-CLAUDE.md)
  + code style confirmation + capability recommendation, and finally call /init to generate the project's CLAUDE.md to permanently solidify the thinking.
  When forking a project, execute the five-step sub-process (Get Repository → Fork → Clone → Project Analysis → Contribution Workflow Guide).
  Other intents recommend matching skills and plugins based on the tech stack.
  Even if the user does not explicitly say "startup check", this skill should trigger whenever planning any project from scratch or tool recommendations are needed.
version: "4.0.0"
risk: safe
source: community
capabilities: ["project-setup", "risk-assessment", "mvp-planning", "skill-discovery", "capability-scanning", "project-analysis", "fork-workflow"]
integrates_with: ["plugin-installation", "pr-management"]
metadata:
  category: meta
  tags: [project-startup, planning, checklist, mvp-definition, risk-assessment, init, code-style, discovery, recommendation, skills, plugins, commands, fork, contribute, open-source]
  compatibility: Requires the /init command (built into Claude Code), no other external dependencies
---

# Universal Project Startup & Capability Discovery

## Core Principles

**Fire first, aim later — but know roughly where the target is before pulling the trigger.**  
This skill helps you make key decisions before startup within 15 minutes, avoiding rework caused by blind enthusiasm. At the same time, **preserve the project's code style throughout (including comments, naming, formatting, etc.)** — meaning whenever generating code examples, project structure, or scaffolding, proactively ask about or infer the user's existing style conventions and strictly follow them.

This skill has absorbed all capabilities from the former `proactive-skill-discovery` (which has been deleted). Before starting, it first detects your intent — starting a new project, developing a feature, reviewing code, fixing a bug, exploring tools, or participating in open source (Fork) — and then recommends the best-matching skills and plugins.

## Non-Trigger Conditions

Do **not** trigger this skill in the following situations:
- The user has explicitly specified a specific skill to use (e.g., `/github-pr-reviewer`)
- The conversation is simply Q&A, not involving project development tasks
- The user has explicitly stated in the current session that they do not need recommendations or startup checks

## References

This skill comes with six reference documents, loaded during execution according to the following rules:

- **`references/project-checklist.md`**: Full version of the general project startup checklist. Load when the user requests a more detailed explanation of a step, wants to see the full startup checklist, or needs to confirm no checklist items are missed.
- **`references/ai-agent-checklist.md`**: AI Agent project-specific checklist. Load when the user confirms the project type is an AI Agent, asks about Agent-specific risks or considerations, or needs to design the Agent's "brain" architecture.
- **`references/scanner-patterns.md`**: Project fingerprint detection matrix, scoring algorithm formulas, plugin mapping table, and command discovery reference. Consult during tech stack confirmation and capability matching.
- **`references/language-guide.md`**: Programming language pros/cons reference table. Load when the user is unsure which language to use.
- **`references/hook-config.md`**: Optional Claude Code hook configuration guide. Load when the user wants this skill to trigger automatically on new session start or new project detection — refer to this document for configuring SessionStart/PostToolUse hooks.
- **`references/validation-scenarios.md`**: Validation scenario collection. Load during LLM self-check after skill execution to verify recommendations match expectations. Covers 8 typical project types and 7 edge cases.

## Package Linking

This skill supports automatic linkage with other skills in the minecraft269-skills plugin package. Perform the following detection:

1. Glob search for `~/.claude/plugins/minecraft269-skills/.claude-plugin/plugin.json`
2. If found → `PACKAGE_MODE = true`, sibling skills can be discovered and linked
3. If not found → `PACKAGE_MODE = false`, skip all cross-skill logic (silent degradation)

When `PACKAGE_MODE = true`:
- After identifying the project tech stack, can link with `integrates_with: plugin-installation` (quick plugin installer)
- After CLAUDE.md generation, can prompt the user to run capability scanning (this skill has it built-in, no cross-skill linkage needed)
- Scan sibling SKILL.md `capabilities` fields, match against this skill's `integrates_with` tags
- Only show linkage hints when matching succeeds

See `_shared/package-context.md` for details. **Any detection failure defaults to PACKAGE_MODE = false; do not report errors or interrupt.**

---

## Usage Flow

### Step 0: Intent Detection

**Infer first, ask later.** Extract keywords from the user's raw message to pre-judge intent, only pop up `AskUserQuestion` when it cannot be determined.

#### 0.1 Intent Pre-Judgment (Keyword Matching)

Match the following patterns in the user's message (case-insensitive):

| Keyword Combinations | Inferred Intent | Direct Routing |
|---------------------|----------------|----------------|
| "start" / "begin" / "new" / "create" / "initialize" / "scaffold" / "from scratch" **+** "project" | 🚀 Start New Project | → Step 0b Language Confirmation → Mandatory Six-Step Process |
| "develop" / "add" / "implement" / "build" **+** "feature" / "functionality" | 💻 Develop New Feature | → Step 0c Tech Stack Confirmation + Capability Recommendation |
| "review" / "check" / "examine" **+** "code" / "PR" / "pull request" | 🔍 Review Code | → Step 0a Target Confirmation |
| "fix" / "repair" / "debug" **+** "bug" / "issue" / "error" | 🐛 Fix Bug | → Step 0a Target Confirmation |
| "what" / "recommend" / "which" / "available" / "discover" **+** "skills" / "plugins" / "tools" / "capabilities" | 🔧 Explore Tools | → Step 0c Full Capability Scan |
| "fork" / "participate" / "contribute" / "submit PR" / "upstream" **+** "project" / "repo" / "open source" / "code" / "repository" | 🍴 Fork Project | → Step 0a Fork Branch |

**Matching Rules:**
- If a **unique intent** matches → route directly, skip `AskUserQuestion`, confirm with one sentence before routing (e.g., "I see you want to [intent], let's get started…")
- If **multiple intents match** or **no match** → use `AskUserQuestion`

#### 0.2 Interactive Prompt (Only When Intent Is Unclear)

> "What would you like to do?"

| Option | Description | Subsequent Routing |
|--------|-------------|--------------------|
| 🚀 **Start New Project** | Start a project from scratch | → Ask for language/framework → Step 0b Language Confirmation → Enter mandatory six-step process |
| 💻 **Develop New Feature** | Add a feature to an existing project | → Enter Step 0c Tech Stack Confirmation + Capability Recommendation |
| 🔍 **Review Code** | Review a PR or code changes | → Step 0a Target Confirmation → Step 0c Tech Stack Confirmation + Review Tool Recommendation |
| 🐛 **Fix Bug** | Troubleshoot and fix issues | → Step 0a Target Confirmation → Step 0c Tech Stack Confirmation + Debugging Tool Recommendation |
| 🔧 **Explore Tools** | See what skills/plugins/commands are available | → Enter Step 0c Full Capability Scan |
| 🍴 **Fork Project** | Fork an open-source repo, develop locally, and contribute a PR | → Step 0a Fork Branch |
| 📋 **Other** | User free-text input | → Smart match routing based on input content |

#### Step 0a: Target Confirmation (Only for "Review Code" / "Fix Bug")

##### Code Review Branch (4 Layers of Questions)

The "Review Code" intent needs to first confirm the review target and method, then decide whether to execute tech stack scanning.

**Layer 1 — Ask about the review scenario:**

Use `AskUserQuestion`:
> "What are you reviewing?"

| Option | Description |
|--------|-------------|
| 📁 **Local Project** | Review code changes in the current workspace (unstaged / branch diff / recent commit) |
| ☁️ **Remote PR** | Review a Pull Request on GitHub |

**Layer 2 (Remote PR only) — Ask about the target PR:**

> "Please provide the PR URL (e.g., `https://github.com/owner/repo/pull/123`) or `owner/repo#number`"

Parse PR URL → Extract `owner`, `repo`, `pr_number`.

**Layer 3 (Remote PR only) — Ask about the review method:**

Use `AskUserQuestion`:
> "How would you like to review this PR?"

| Option | Description | Next Steps |
|--------|-------------|------------|
| ⚡ **Quick Online Review** | Get PR diff/files/commits directly via GitHub MCP, review online, no clone needed | → Use `gh pr view/diff` or GitHub MCP tools to get PR content → Output review conclusion → **Do not execute Step 0c** |
| 💻 **Clone to Local for Detailed Review** | Clone the repository locally, perform full tech stack scan + deep review | → Compare with local git remote: `git remote get-url origin 2>/dev/null \|\| echo "NOT_A_GIT_REPO"` → If no match, guide clone (`gh repo clone owner/repo` or `git clone`) → Execute Step 0c |

**Layer 4 (Local project only) — Confirm review scope:**

> "Which changes in the current workspace would you like to review?"

| Option | Description |
|--------|-------------|
| 📝 **Unstaged Changes** | Modifications in the workspace that have not yet been staged |
| 🌿 **Branch Comparison** | Diff of current branch vs target branch (e.g., `main`) |
| 📦 **Recent Commits** | Review changes from the last N commits |

After scope confirmed → proceed to Layer 5.

**Layer 5 (All review paths) — Review Model Confirmation:**

Before starting the review, confirm the AI model to use. Different models differ in review depth, speed, and cost.

1. **Get the current default model**: Read the current model name from session context (e.g., model info from system prompts)
2. **Display and confirm**:
   > "The current default review model is **[model name]**. Would you like to use this model for the review?"

   | Option | Description |
   |--------|-------------|
   | ✅ **Use Current Model** | Start review directly with the default model |
   | 🔄 **Switch Model** | Let the user specify a different model |

3. **When switching models**:
   > "Please enter the model name you'd like to use (e.g., `sonnet`, `opus`, `haiku`, `fable`, or a specific model ID)"
   - Record the user's choice in the review context; use that model for subsequent Agent calls

4. **Enter review** → Execute Step 0c tech stack scan → Prioritize matching `pr-review`, `code-review` capabilities when recommending skills.

##### Fix Bug Branch

The "Fix Bug" intent needs to first confirm the target project.

**1. Ask for the target:**

Use `AskUserQuestion`:
> "Which project are you fixing a bug in? Is it the current workspace project, or another project?"

**2. Check local status:**

- Compare the user's project info against the current workspace git remote
- If the target project is not local → guide cloning
- After cloning, switch to the target project directory

**3. Enter Step 0c:**

- Execute tech stack scan in the correct project directory
- Prioritize matching debugging tools + general code analysis skills when recommending

##### 🍴 Fork Project Branch (5-Step Sub-Process)

The "Fork Project" intent requires executing five steps in order: Get Repository, Fork, Clone, Project Analysis, Contribution Workflow Guide.

**Step 0a-fork-1: Get Target Repository**

1. Extract the GitHub repository identifier from the user's message. Supported formats:
   - Full URL: `https://github.com/owner/repo`
   - Shorthand: `owner/repo`
2. Regex extraction: `(?:https?://)?github\.com/([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)` or `\b([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)\b`
3. If extraction fails, use `AskUserQuestion`:
   > "Please provide the open-source repository you'd like to contribute to (e.g., `https://github.com/facebook/react` or `facebook/react`)"
4. If the user provides a non-GitHub URL, prompt:
   > "Currently, only GitHub open-source repositories are supported for Fork contributions. Please confirm the repository is on GitHub."

**Step 0a-fork-2: Fork the Repository**

1. First check if a fork already exists:
   - Use `gh repo list <username> --json name --jq '.[].name'` or `mcp__plugin_github_github__list_commits` to check
2. If not exists → execute fork:
   - Prefer `gh repo fork <owner/repo> --clone=false` (more reliable)
   - Fallback: GitHub MCP `mcp__plugin_github_github__fork_repository`
3. If exists → `AskUserQuestion`:
   > "I found you already forked `<owner/repo>`. Would you like to use the existing fork?"

   | Option | Description |
   |--------|-------------|
   | ✅ **Use Existing Fork** | Use the existing fork repository directly |
   | 🔄 **Re-fork** | Delete the existing fork and create a new one (`gh repo fork --force`) |
   | ⬆️ **Sync Existing Fork** | Sync the latest changes from the upstream repository to your fork (`gh repo sync`) |
   | ❌ **Cancel** | Abort the Fork operation |

4. After successful fork, record variables:
   - `_FORK_UPSTREAM = "owner/repo"` (upstream repository)
   - `_FORK_REPO = "your-username/repo"` (your fork)

**Step 0a-fork-3: Clone to Local**

1. Ask the user for the clone target directory (default: `<repo-name>` under the current workspace)
2. Check if the directory already exists locally:
   - Not exists → execute `gh repo clone <your-username/repo>` or `git clone https://github.com/<your-username/repo>.git`
   - Exists → `AskUserQuestion`:
     > "A directory with the same name already exists locally. How would you like to proceed?"
     - ✅ Reuse existing directory / 🔄 Re-clone / ❌ Cancel
3. After cloning, set up upstream:
   ```bash
   cd <repo-name>
   git remote add upstream https://github.com/<owner/repo>.git  # If not already added
   git fetch upstream
   ```
4. Record `_FORK_LOCAL_PATH = "<clone-path>"`

**Step 0a-fork-4: Project Analysis**

1. After entering the cloned directory, prompt the user to run a tech stack scan:
   > "[repo] has been cloned locally. It's recommended to scan the project tech stack first to help you quickly understand the project structure. Would you like to start the analysis?"

   | Option | Description |
   |--------|-------------|
   | ✅ **Start Analysis** | Execute Step 0c Tech Stack Confirmation + Capability Discovery |
   | ⏭️ **Skip** | Skip the tech stack scan and go directly to contribution workflow guidance |

2. If the user chooses "Start Analysis", execute the full Step 0c flow (0c-1 through 0c-7)
3. Additional checks:
   - Read the upstream `CONTRIBUTING.md` (if it exists)
   - Check `.github/` directory for PR templates, Issue templates
   - Read the `LICENSE` file
4. Display project overview summary (tech stack + contribution guide highlights + license type)

**Linkage Hooks (only when PACKAGE_MODE = true):**
After project analysis completes, match `integrates_with: pr-management`:
- If sibling skill `github-pr-manager` is detected as available → prompt: "💡 After making changes, you can use the **GitHub PR Manager** to create and manage your Pull Request."

**Step 0a-fork-5: Contribution Workflow Guide**

1. Display the contribution process overview:
   ```
   ## 🍴 Fork Contribution Flow
   
   1. ✅ Fork Repository → [fork-url]
   2. ✅ Clone to Local → [local-path]
   3. ✅ Project Analysis → [tech-stack]
   4. 📝 Create Feature Branch → Pending
   5. 🔨 Develop Changes → Pending
   6. 📤 Push and Create PR → Pending
   ```

2. Guide creating a feature branch:
   > "I recommend creating a feature branch for your changes. Branch name format: `feat/<description>` or `fix/<description>`"
   - Let the user enter a branch name, or auto-suggest based on description

3. **Linkage Hooks (only when PACKAGE_MODE = true):**
   - Match `integrates_with: pr-management` → prompt: "💡 After making changes, you can use the **GitHub PR Manager** to create and manage your Pull Request."
   - Match `git-commit` within `integrates_with: plugin-installation` → prompt: "💡 When committing code, you can use the **Git Commit Helper** to auto-generate Conventional Commits messages."

4. Summarize next steps:
   > "Your project is ready. Next steps: make changes → `git add` + `git commit` → `git push origin <branch>` → create PR. Let me know if you need any help."

#### Step 0b: Language/Framework Confirmation (Only for "Start New Project")

> "What programming language/framework would you like to use?"

| Option | Description |
|--------|-------------|
| 🟢 **Python** | AI/ML, data analysis, web backend, script automation |
| 🟡 **JavaScript/TypeScript** | Web full-stack, frontend, cross-platform |
| 🔵 **Java/Kotlin** | Enterprise backend, Android |
| 🟣 **Rust** | Systems programming, high-performance scenarios |
| ⚪ **Go** | Cloud-native, microservices, CLI tools |
| 🟠 **C# (.NET)** | Windows desktop, games, enterprise applications |
| 🔴 **Swift** | Apple ecosystem (iOS/macOS) |
| 🤔 **Not sure, recommend for me** | → Ask for project type → Load `references/language-guide.md` → List pros/cons + recommendation |

**"Not sure" branch recommendation logic:**

1. Ask for project type: Web App / Mobile App / Desktop App / CLI Tool / AI/ML / Game / Embedded
2. Ask for priorities: Development speed / Runtime performance / Ecosystem richness / Learning curve
3. Load `references/language-guide.md`, output recommendation table:

```
## Language Recommendation

Based on your needs ([project type] + [priorities]), the following languages are recommended:

| Language | Suitability | Advantages | Disadvantages |
|----------|-------------|------------|---------------|
| [Language A] | ⭐⭐⭐⭐⭐ | [Advantages] | [Disadvantages] |
| [Language B] | ⭐⭐⭐⭐ | [Advantages] | [Disadvantages] |
| [Language C] | ⭐⭐⭐ | [Advantages] | [Disadvantages] |

**Top Recommendation: [Language]** — [One-line rationale]
```

After the user confirms the language, proceed to the mandatory six-step process.

#### Step 0c: Tech Stack Confirmation + Capability Discovery (7-Step Sub-Process)

See `references/scanner-patterns.md` for the detailed algorithm.

---

**0c-1. Project Fingerprint Scan**

**Before scanning — Cache check:**

1. Check if a `_SCAN_CACHE` record exists in the session context (containing `timestamp` and `fingerprint`)
2. If a cached record exists:
   - Read `cache_ttl_hours` from `.discovery-rules.json` (default 24 hours)
   - If last scan is within TTL → reuse cached fingerprint and scan results, skip 0c-1 and 0c-2, go directly to 0c-3
   - If TTL exceeded → continue with full scan
3. If no cached record (first scan) → continue with full scan

Scan existing projects. Use `Glob` to check for the following files (extended detection matrix in `references/scanner-patterns.md` §Fingerprint Detection Map):

| File | Inference |
|------|-----------|
| `pom.xml` | Java + Maven |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin + Gradle |
| `package.json` | Node.js / JavaScript / TypeScript |
| `tsconfig.json` | TypeScript |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `requirements.txt` / `pyproject.toml` / `setup.py` | Python |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `*.sln` / `*.csproj` | .NET / C# |
| `CMakeLists.txt` | C/C++ |
| `pubspec.yaml` | Flutter/Dart |
| `Package.swift` / `*.xcodeproj` | Swift / Apple Ecosystem |
| `docker-compose.yml` / `Dockerfile` | DevOps / Container |
| `next.config.*` | Next.js |
| `vite.config.*` | Vite |
| `tailwind.config.*` | Tailwind CSS |
| `astro.config.*` | Astro |
| `nx.json` / `turbo.json` | Monorepo (Nx/Turborepo) |
| `pnpm-lock.yaml` | pnpm |
| `bun.lockb` | Bun |
| `deno.json` | Deno |
| `schema.prisma` | Prisma |
| `schema.graphql` | GraphQL |

- If `package.json` exists, `Read` its `dependencies` and `devDependencies` to extract framework keywords
- If `pom.xml` exists, `Grep` for `<artifactId>` and `<parent>` to detect Spring Boot, Quarkus, etc.
- Check `app/` or `src/` subdirectories as supplementary signals

**For brand new projects:** Directly use the language/framework from Step 0b.

**Output:** Project fingerprint (comma-separated tags, e.g., `java, spring-boot, maven, postgresql`).

**Linkage Hooks (only when PACKAGE_MODE = true):** Check `.git/config` for a GitHub remote. If found, match `integrates_with: pr-management`, prompt "💡 GitHub project detected. It is recommended to use the **GitHub PR Manager** to manage Pull Requests for this repository."

---

**0c-2. Capability Inventory Scan (Parallel Execution)**

Load `references/scanner-patterns.md` for parallel three-way scanning.

**Before scanning — Read deep exploration configuration:**

1. Attempt to read `~/.claude/skills/.discovery-rules.json`
2. If the file exists and defines `deep_explore_plugins` (array of strings) → use that list as deep exploration targets
3. If the file exists and defines `priority_boost_plugins` (array of strings) → use that list as priority boost plugins
4. If the file does not exist or fields are missing → use built-in defaults:
   - `deep_explore_plugins`: `["everything-claude-code", "superpowers", "andrej-karpathy-skills", "oh-my-claudecode"]`
   - `priority_boost_plugins`: `["everything-claude-code", "superpowers", "andrej-karpathy-skills"]`

**2a. Skill Scan:** Glob `~/.claude/skills/*/SKILL.md`, parse frontmatter to extract name, description, tags, category, source.

**2b. Plugin Scan:**
- MCP Configuration: Read `~/.claude/settings.json` → `mcpServers`, extract server name, type, command, description
- Local plugins: Glob `~/.claude/plugins/*/plugin.json` or `package.json`

**2c. Deep Exploration (Required, see scanner-patterns.md §Deep Exploration Reference):**
Execute deep exploration on the list of deep exploration target plugins determined above:
- List root-level `.md`/`.json`/`.yaml`/`.yml`/`.mdc` files (skip node_modules, .git)
- Read the first 5-10 lines of each `.md` file to identify purpose
- Scan nested skills (`.agents/skills/*/SKILL.md`)
- Extract `.mdc` rule filenames and descriptions
- Output format: tagged with `source: deep-exploration` and `plugin: <name>`, each entry with name, type (soul/rules/agents/claude-md/commands-ref/nested-skill), description, path

---

**0c-3. Matching and Ranking**

Load `references/scanner-patterns.md` §Skill-to-Project Matching Algorithm + §Priority Boost System.

**Skill Scoring:** Tag match +3, Framework match +3, Category alignment +1, General +0
**Plugin Scoring:** Tool match +3, Domain match +1, General +0

**Priority Boost System:**
When ECC, superpowers, andrej-karpathy-skills, oh-my-claudecode, or deep resources are detected → base score = max(normal_score, 10), mark with ⭐ pinned to top.

**Filter by intent:**

| Intent | Prioritize | Deprioritize |
|--------|------------|--------------|
| Develop New Feature | Language-specific development skills, code generation tools | Review/debugging categories |
| Review Code | Code review, PR review, lint skills | — |
| Fix Bug | Debugging, error tracking, testing skills | — |
| Fork Project | Project analysis, contribution guide, PR management, code review-related skills | — |
| Explore Tools | No filtering, show all matched results | — |

**Output three separate lists (always in this order):**
1. ⭐ Priority Recommendations (boosted plugins/deep resources — always first)
2. 📋 Recommended Skills (top 5-10, project-matched)
3. 🔌 Recommended Plugins (top 3-5, project-matched)

Unmatched items are kept for Step 0c-6 full export.

---

**0c-4. Interactive Recommendation (⚠️ Mandatory Step)**

Display recommendation results using the following template:

```markdown
## 🔍 Project Identification Results

**Project:** [project name or path]
**Tech Stack:** [language] + [framework] + [build tool]
**Detection Basis:** [list of discovered config files]

## ⭐ Priority Recommendations (Core Capability Enhancement)

> The following plugins/resources provide foundational capability enhancement and are strongly recommended regardless of project type.

| # | Name | Type | Description | Unloaded Resources Included |
|---|------|------|-------------|----------------------------|
| 1 | `everything-claude-code` | Plugin | AI behavior configuration / security guide | SOUL.md, RULES.md, AGENTS.md, COMMANDS-QUICK-REF.md, WORKING-CONTEXT.md, the-security-guide.md, agent.yaml, nested skills |
| 2 | `superpowers` | Plugin | Core workflow skills | AGENTS.md, hooks.json, GEMINI.md |
| 3 | `andrej-karpathy-skills` | Plugin | Karpathy coding guidelines | CURSOR.md, karpathy-guidelines.mdc |
| 4 | `oh-my-claudecode` | Plugin | Multi-Agent orchestration | Dozens of nested skills (`.agents/skills/*/SKILL.md`) |

## 📋 Recommended Skills (Sorted by Match)

| # | Name | Description | Match Reason | Source |
|---|------|-------------|--------------|--------|

## 🔌 Recommended Plugins (Sorted by Match)

| # | Name | Description | Match Reason | Type |
|---|------|-------------|--------------|------|
```

> 💡 If the plugin list is empty, display: "No strongly related plugins detected for the current project."

**Use `AskUserQuestion` to prompt:**
> "Based on your current project, these are the recommended skills, plugins, and unloaded resources. How would you like to proceed?"

Provide the following options:
- **Enable All Recommendations** — Actively use all recommended items in subsequent conversation
- **Select Individually** — Let the user specify which ones to enable (enter by number)
- **Skip, Don't Enable This Time** — Record the choice, no repeated recommendations for this session
- **Learn More** — Expand detailed explanation for a specific skill/plugin/deep resource (user specifies name)
- **Load Unloaded Resources** — For SOUL/RULES/AGENTS files discovered during deep exploration, ask if manual loading is needed

**Linkage Hooks (only when PACKAGE_MODE = true):**

Mark uninstalled plugins in the recommendation list with 🆕. After user selection, match `integrates_with: plugin-installation`:
- If the user selected an uninstalled capability → prompt: "💡 It looks like [name] is not yet installed. Would you like to use the **Quick Plugin Installer** to install it?"

---

**0c-5. Command Discovery (Only Runs After User Completes 0c-4 Selection)**

⚠️ If the user chooses "Skip" → jump to 0c-6

Load `references/scanner-patterns.md` §Command Discovery Reference.

**5a. MCP Tool Discovery (only scan plugins the user selected):**
1. Use `ListMcpResourcesTool` to enumerate MCP resources, or scan system prompts for `mcp__` prefixed tools
2. Only filter tools belonging to the user's **selected** plugins
3. For each tool, infer: purpose (what it does) + applicable scenario (when to use it)

**5b. Slash Command Discovery:**
Extract `/` commands from system prompts, matching the selected skill categories/capabilities

**5c. Display Template:**

```markdown
## 🔧 Available Commands for Selected Tools

Based on your selection of [skill-names] and [plugin-names], here are the available commands:

### 🛠 MCP Tool Commands

#### [Selected Plugin Name]
| Tool Name | Purpose | Applicable Scenario |
|-----------|---------|---------------------|
| `mcp__*__tool_name` | [one-line description] | [when to use] |

### ⌨️ Related Slash Commands

| Command | Purpose | Applicable Scenario |
|---------|---------|---------------------|
| `/command-name` | [function description] | [when to use] |
```

> 💡 If the selected plugins have no MCP tools or there is no MCP connection, display: "Selected plugins currently have no available MCP tool commands."
> 💡 Slash commands are always available; at least list general commands related to the selected skills.

---

**0c-6. Full Export (⚠️ Ask Before Exporting)**

Must obtain user consent before exporting.

Ask the user:
> "Would you like to export a complete list of all installed skills, plugins, and commands to a file? This way you can browse all available capabilities offline."

If the user agrees, ask three follow-up questions (using `AskUserQuestion`):
1. **Target export directory** — enter a path (e.g., `D:\docs\skills-list\`)
2. **Output language** — free input of any language (default: follow the current conversation language)
3. **Output format** — `Markdown` (recommended) / `JSON` / `Plain Text`

**Export Content Structure:** Load `references/scanner-patterns.md` §Export Field Definitions.

Export file naming: `{project-name}-skills-plugins-export.{format}`

```markdown
# [Title — in user-specified language]

> Export time: [timestamp]
> Project: [project path]
> Total: [N] skills, [M] plugins, [K] commands
> Language: [user-specified language]

## 📋 Skills — By Category

### [Category]
| Name | Description | Tags | Source | File Path |
| ... | ... | ... | ... | ... |

## 🔌 Plugins — By Type

### [Type]
| Name | Type | Command | Description | Source |
| ... | ... | ... | ... | ... |

## 🔧 Commands

### 🛠 MCP Tool Commands — Grouped by Plugin

#### [Plugin Name]
| Tool Name | Purpose | Applicable Scenario |
|-----------|---------|---------------------|

### ⌨️ Slash Commands — By Category

#### [Category]
| Command | Purpose | Applicable Scenario |
|---------|---------|---------------------|
```

---

**0c-7. Context Persistence**

- User chooses "Skip" → record in session context, do not repeat recommendations in this session (unless project fingerprint changes significantly)
- User selects specific skills/plugins → record acceptance list for subsequent linkage references
- Re-trigger discovery when the project fingerprint changes significantly. **Significant change is defined as any of the following:**
  - A new language/framework configuration file is added (e.g., new `package.json`, `go.mod`, `Cargo.toml`, `pom.xml`, etc.)
  - A new subdirectory is added that contains its own project configuration files
  - The user switches to a branch with a different tech stack via `git checkout`
  - The working directory switches to a different subproject within the same monorepo
- **Content-only modifications (without changing the tech stack) do not trigger re-discovery**
- After other in-package skills complete their main operation → prompt linked discovery
- **Cache Record**: After scanning completes, record `_SCAN_CACHE = { timestamp: <current time>, fingerprint: <project fingerprint tags>, ttl_hours: <cache_ttl_hours from rules, default 24> }` in the session context for reuse on subsequent calls

---

Non-"Start New Project" intents end at this step and do not enter the mandatory six-step process. However, the capability scan results can serve as context for subsequent work.

---

### Mandatory Six-Step Process (Only for "Start New Project")

The following six steps are the complete original kickoff flow — **must be executed in order**.

### Step 1: Clarify the "Why" and the "What"
Ask the user (at minimum, cover these 3 questions):
1. Whose pain point does this project solve, and what is lost by not doing it?
2. What are the measurable criteria for success? (e.g., DAU > 1000, cost < 0.1 CNY per use, first paying customer, etc.)
3. Fill in the blank: "We are solving **[problem]** for **[who]**, through **[what means]**, to achieve **[what effect]**."

- If the user cannot answer question 3, guide them to complete the "one-sentence definition" first before continuing.
- If it's an AI Agent project, additionally ask: "Can it be done without an Agent? Could a rule engine solve it?"
- For more detailed problem definition guidance, load Chapter 1 of `references/project-checklist.md` or Chapter 1 of `references/ai-agent-checklist.md`.

### Step 2: Define Boundaries — Make Clear "What Not to Do"
Ask the user to list all desired features for the first version, then:
- Forcefully cut 80%, keeping only the **minimum set that validates the core hypothesis (MVP).**
- Make clear the triple constraints (time, cost/resources, quality/scope), and note that "at most two can be preserved simultaneously."
- For Agent projects, additionally list **no-fly zones** (e.g., cannot delete production data, cannot transfer money externally, cannot send unapproved content).
- When boundary discussions hit difficulty, load Chapter 2 of `references/project-checklist.md`.

**Linkage Hooks (only when PACKAGE_MODE = true):**

After confirming the project tech stack, scan sibling skills' `capabilities`, match `integrates_with: plugin-installation`:
- Match succeeds → prompt user: "💡 I see your project uses [tech stack]. Would you like to install related MCP Servers (such as GitHub MCP, Playwright, Context7) to enhance the development experience?"

### Step 3: Quick Risk Assessment
Have the user respond to:
- Are there obvious obstacles in technology, personnel, market, or compliance?
- Write down the **three things most likely to cause project failure**, and come up with a Plan B for each (even if it's just "switch approaches, 30% slower").
- For AI Agent: use the current strongest model to manually simulate 3-5 steps of a "paper prototype" and observe whether it goes off track. If it does, require task simplification or add guardrails.
- See Chapter 3 of `references/project-checklist.md` for detailed feasibility analysis templates; see Chapter 4 of `references/ai-agent-checklist.md` for Agent-specific risk assessment.

### Step 4: Stakeholder Alignment
- Guide the user to identify the core circle (doers), influence circle (resource providers), and outer circle (users/regulators).
- Mandatory recommendation: "Take the 'project definition' and 'success criteria' from Step 1 and verbally confirm them with key people before proceeding."
- See Chapter 4 of `references/project-checklist.md` for complete stakeholder analysis guidance.

### Step 5: Draw a Rough Roadmap (Milestones Only)
- Output 3-5 milestones (in weeks), each milestone must have a clear **deliverable** and **acceptance criteria**.
- Finally, ask the user to confirm the following startup checklist:
  - ☑ Project definition and goals confirmed with key people
  - ☑ MVP scope defined (and what's not included)
  - ☑ Resources (time, money, people) secured or promised
  - ☑ Contingency plans in place for the top three risks
  - ☑ Code repository, communication channels, and documentation collaboration tools ready
- See Chapter 5 of `references/project-checklist.md` for roadmap design reference.

### Step 6 (Critical): Generate CLAUDE.md — Solidify Thinking into the Project

After completing the five-step check and confirming the code style, **must** execute the following process:

#### 6a. Confirm User Willingness
Ask the user:
> "We've completed the five-step startup check and confirmed the project's code style. Now I'll call /init to generate the project's CLAUDE.md, solidifying everything we discussed — project definition, MVP scope, milestones, risk plans, style conventions — into the project root. Shall we proceed?"

- If the user agrees, proceed to 6b.
- If the user is not ready yet, skip to 6d.

#### 6b. Detect Existing CLAUDE.md
Check whether a `CLAUDE.md` file already exists in the project root:
- **If not exists**: directly execute the `/init` command. `/init` is Claude Code's built-in project initialization command, which guides the generation of a standard CLAUDE.md file. The five-step check information collected by the skill is all in the conversation context, and /init can use it directly.
- **If exists**: read the existing CLAUDE.md, perform a paragraph-by-paragraph comparison and merge:
  1. Extract custom commands, build steps, test framework configuration from existing CLAUDE.md → **keep unchanged**
  2. Compare against the five-step check results, identify missing sections (project definition, MVP scope, risk plans, style conventions)
  3. Only supplement the missing parts, do not overwrite existing content
  4. Show the user a merge diff summary, write after confirmation

#### 6c. Verify Generation Result
After `/init` completes:
- Check whether CLAUDE.md was generated or updated in the project root.
- If generation succeeds, show the user a summary:
  > "✅ CLAUDE.md has been generated. Your project now has a standard entry file containing project definition, MVP scope, milestones, risk plans, and code style conventions. Claude will automatically load this context every time it enters this project."
- If `/init` did not complete for any reason (e.g., the user exited mid-way), manually output a startup summary using the "Output Template" below, and let the user know they can run `/init` again at any time.

**Linkage Hooks (only when PACKAGE_MODE = true, after 6c succeeds):**

After CLAUDE.md is generated, this skill already has built-in complete skill discovery capability (Step 0c), so it can directly prompt the user:
> "✅ CLAUDE.md has been generated. Would you like to scan the current project's tech stack and recommend matching skills and plugins?"

(No need for cross-skill linkage via `integrates_with: skill-discovery` — this capability is built into this skill.)
- Also check other sibling skills' `integrates_with`, and prompt if matches are found

#### 6d. Fallback Plan
If the user chooses not to run `/init`, output the complete startup summary (see template below) and inform:
> "Understood. Here is the complete startup check summary. You can run `/init` at any time to solidify these contents as a formal CLAUDE.md."

---

## Code Style Preservation Rules (Mandatory)

When this skill involves generating any code, configuration files, comment templates, or project scaffolding, **must** determine and preserve style according to the following priority:

1. **Proactive Detection**: Check whether the user has provided existing code files, `.editorconfig`, `eslint`/`prettier` config, or verbally stated style preferences (e.g., "we use tab indentation").
2. **If no existing style, adopt industry standard defaults** (e.g., PEP8 for Python, 2-space indentation for JavaScript, comments using `#` or `//` followed by a space), and confirm with the user before generation.
3. **Comment Conventions**: Ask the user for comment density preference (required for key functions / only complex logic / every line). Default: "write comments for public APIs and complex logic; omit for self-explanatory statements."
4. **Naming Conventions**: Clarify naming style for variables, functions, classes, and files (camelCase, snake_case, PascalCase, etc.), and apply consistently to all generated content.
5. **Even example code must follow the above style**; if the user has not specified, add a comment above the code block stating "Please adjust to your project's style."

---

## Additional Checks for AI Agent Projects

If the user confirms the project type is an AI Agent, append the following questions after completing the above six steps (see `references/ai-agent-checklist.md` for details):
- How is the memory system (short-term/long-term) designed? (See Chapter 3)
- Which planning strategy (ReAct / Plan-and-Execute / Multi-Agent) is chosen? (See Chapter 3)
- Are the tool set's input/output formats strictly defined? (See Chapter 3)
- How is "good vs bad" evaluated? (Task success rate, tool call accuracy, cost) (See Chapter 7)
- Security and ethics: have injection prevention, least privilege, transparency, and compliance been considered? (See Chapter 8)

And recommend that the user first implement a **minimum viable Agent** (model call + one tool) before introducing a framework.

---

## Output Template (Mandatory)

After completing the six-step check, **must** output a startup summary using the following format (keep under 500 words):

```markdown
## Project Startup Summary: [project name]

### Project Definition
- **One-liner**: [fill in]
- **Success Criteria**: [measurable metrics]
- **Stakeholders**: Core circle=[...], Influence circle=[...], Outer circle=[...]

### MVP Scope
- **Includes**: [Feature A, Feature B]
- **Excludes**: [Feature C, Feature D, Feature E]
- **Constraints**: Time=[Deadline], Resources=[budget/headcount], Quality=[compromise area]

### Roadmap
| Milestone | Deliverable | Acceptance Criteria |
|-----------|-------------|---------------------|
| W1 | [deliverable] | [criteria] |
| W2 | [deliverable] | [criteria] |
| W3 | [deliverable] | [criteria] |

### Risk Plan
| Risk | Likelihood | Plan B |
|------|------------|--------|
| [Risk 1] | High/Medium/Low | [alternative] |
| [Risk 2] | High/Medium/Low | [alternative] |
| [Risk 3] | High/Medium/Low | [alternative] |

### Code Style Conventions
- Indentation: [spaces/tabs, count]
- Comments: [density and format]
- Naming: [variable/function/class rules]

### Startup Status
☑ All confirmed → /init called, CLAUDE.md generated ✅
```

---

## Edge Case Handling

### User Already Has CLAUDE.md
If a CLAUDE.md already exists in the project root (detected before or during Step 6), first ask the user whether to overwrite or merge. Recommended strategy: read the existing CLAUDE.md content, compare with the five-step check results, supplement missing parts rather than completely overwriting — the CLAUDE.md may already contain project-specific build commands, test framework configurations, etc., that should not be overwritten.

### Non-Project-Owner Scenario
If the user explicitly indicates they are providing advice for someone else's project (e.g., "help me take a look at my friend's project plan"), then:
- Skip Step 6 (/init call), do not modify someone else's CLAUDE.md
- Skip code style questions (unless the user asks)
- Focus on completing the five-step analysis and recommendations
- Output a startup summary for the user to forward

### User Only Requests Partial Check
The user may only care about a specific aspect (e.g., "just do a risk assessment for me"). Handle flexibly:
- The user can choose to go through only some steps
- After completing the requested steps, briefly ask if they'd like to complete the remaining steps
- Do not force all six steps, but always mention "if you need a full startup check, feel free to say so"

### Minimal Project Scope

Enable minimal mode when **any 2** of the following conditions are met:

1. **Single-file level task description**: the user describes it as "write a script", "a tool", "a function", "batch processing", or similar single-file level tasks
2. **Few source code files**: the project directory has < 3 source code files (excluding `README.md`, `.gitignore`, `*.json`/`*.toml`/`*.yaml` and other config files)
3. **User explicitly requests simplification**: the user explicitly says "don't need the full process", "just a quick pass", "fast-track it"

**When only 1 condition is met**, ask the user to confirm whether to enable minimal mode.

Minimal mode content:
- **Do**: Problem definition (one-liner) + code style confirmation
- **Skip**: MVP boundary scoping (Step 2), stakeholder analysis (Step 4), milestone roadmap (Step 5)
- **Still do**: Quick risk assessment (Step 3, simplified to "the one thing most likely to go wrong")
- **Still do**: Step 6 CLAUDE.md generation (if project directory exists)
- Upon completion, prompt: "This is a minimal project. If you need the full startup check process, feel free to say so."

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| `~/.claude/skills/` does not exist or cannot be read | Skip skill scan, only recommend plugins and commands, no error reported |
| SKILL.md frontmatter format error | Skip that skill, record its name in a skip list, continue scanning other skills |
| `settings.json` has no `mcpServers` field | Skip MCP plugin scan, only scan local plugin directory |
| `.discovery-rules.json` JSON parse failure | Silently skip, use built-in default rules |
| Glob operation times out (>5 seconds) | Skip deep exploration, mark as "some plugins not deeply scanned" |
| Deep exploration file > 50KB | Only read first 5 lines to determine type, do not read full content |
| PACKAGE_MODE detection fails (any reason) | Degrade to PACKAGE_MODE = false, run silently |
| `/init` execution fails | Manually output startup summary, prompt user they can retry anytime |
| `gh repo fork` fails (not logged in / insufficient permissions) | Prompt user to run `gh auth login` first, or manually fork on GitHub website and provide clone URL |
| Target repository does not exist (Fork mode) | Prompt to confirm URL, re-enter owner/repo |
| Fork already exists and user chooses sync | Execute `git fetch upstream && git merge upstream/main` to sync upstream changes |
| GitHub MCP and `gh` CLI both unavailable (Fork mode) | Prompt user to manually Fork in browser, guide them to provide clone URL to continue |
| User-specified repository not on GitHub (Fork mode) | Prompt that only GitHub repositories are supported, ask whether to continue or cancel |
| Clone target directory conflict (Fork mode) | Ask the user: reuse existing directory / re-clone / choose another directory |

---

## Interaction Style
- Use concise checklist-style questions, asking at most 3 questions at a time to avoid information overload.
- Summarize and paraphrase the user's answers to ensure alignment.
- Finally output a **< 500 word startup summary** containing: project definition, MVP scope, key milestones, top three risks, style conventions, CLAUDE.md generation status.
