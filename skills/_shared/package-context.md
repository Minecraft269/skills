# Package Context Detection Protocol

This document defines the common package detection and Package Linking discovery protocol shared by all skills within the minecraft269-skills plugin bundle.
Every skill references this protocol at startup and adapts to newly added skills without modification.

## 1. PACKAGE_MODE Detection

### Detection Steps

```
1. Search ~/.claude/plugins/ for subdirectories containing .claude-plugin/plugin.json
2. Use Glob to lookup ~/.claude/plugins/*/.claude-plugin/plugin.json
3. If found, Read that plugin.json and inspect the name field
4. If name is "minecraft269-skills" → PACKAGE_MODE = true (High-Contact Mode)
5. Otherwise → PACKAGE_MODE = false (Standalone Mode)
```

### Behavioral Differences by Mode

| Behavior | High-Contact Mode (PACKAGE_MODE = true) | Standalone Mode (PACKAGE_MODE = false) |
|----------|----------------------------------------|----------------------------------------|
| Cross-skill references | Actively discovers and suggests sibling skill linking | Never mentions any sibling skill |
| Cross-skill command hints | Available | Silently hidden |
| Package-level shared resources | May load resources from `_shared/` | Uses only built-in skill resources |
| Dynamic capability discovery | Scans sibling SKILL.md `capabilities` fields | Skips scanning |

### Safe Default

**Standalone Mode is the safe default.** Any detection failure (file not found, permission error, parse failure) must degrade to PACKAGE_MODE = false without error or interruption.

## 2. Runtime Package Linking Discovery

### Algorithm

When PACKAGE_MODE = true and a skill reaches a key decision point:

```
1. Determine the current skill's plugin bundle root directory
2. Glob scan `skills/*/SKILL.md` (**excluding the skill's own SKILL.md** by comparing the `name` frontmatter field)
3. For each sibling SKILL.md, parse the `capabilities` field from its frontmatter
4. Compute the intersection of the current skill's `integrates_with` with each sibling's `capabilities`
5. For every matched sibling skill, extract its `name` and `description`
6. Generate conditional recommendations at the current workflow node

**Self-filtering rule**: A skill must never recommend itself through Package Linking discovery. In step 2's Glob results, any SKILL.md whose `name` field exactly matches the current skill's `name` must be excluded.
```

### Tag Matching Example

```
Current skill integrates_with: ["skill-discovery", "plugin-installation"]

Sibling A: capabilities: ["skill-discovery", "project-analysis"]  → matches "skill-discovery" ✅
Sibling B: capabilities: ["pr-management", "ci-analysis"]          → no match ❌
Sibling C: capabilities: ["plugin-installation", "mcp-setup"]       → matches "plugin-installation" ✅
```

Result: recommend sibling skills A and C.

## 3. Frontmatter Extension Specification

Each skill may declare the following fields in its SKILL.md frontmatter to participate in Package Linking:

```yaml
capabilities: ["<tag>", ...]     # Abilities this skill provides
integrates_with: ["<tag>", ...]  # Types of capabilities this skill needs to pair with
```

Both fields are optional. Skills that do not declare `integrates_with` will not initiate Package Linking. Skills that do not declare `capabilities` will not be discovered by other skills.

Tag naming conventions:
- Use `kebab-case` (e.g., `pr-management`, `skill-discovery`)
- Keep semantics clear without over-splitting terms
- Prefer reusing existing tags (see the tag registry in CONTRIBUTING.md)

## 4. Package Linking Trigger Timing Guide

| integrates_with tag | Suggested trigger timing |
|--------------------|--------------------------|
| `skill-discovery` | After the current skill completes its main operation (installation done, initialization done, clone done) |
| `project-setup` | When the user first interacts with a project (cloning an unfamiliar repository, entering a new directory) |
| `plugin-installation` | When the user is found to be missing a tool, plugin, or MCP Server |
| `pr-management` | When a GitHub remote is detected with active development activity |
| `code-review` | After completing code modifications |
| `testing` | After completing feature implementation |

## 5. Extensibility

When a new skill joins the bundle:
1. Declare `capabilities` and `integrates_with` in the SKILL.md frontmatter
2. Register new tags in the CONTRIBUTING.md tag registry (if using new tags)
3. Insert Package Linking discovery steps at appropriate workflow nodes

**No modifications to this file or other existing skills are required.** The runtime discovery mechanism automatically recognizes new skills.

## 6. Loop Trigger Protection

To prevent Package Linking from forming infinite loops, all skills must follow these rules:

### Protection Rules

1. **Context marker**: After each Package Linking trigger, record a `_LINKED_FROM: ["<triggering_skill_name>"]` marker in the conversation context
2. **Loop detection**: Before executing a Package Linking, check the marker -- if the current skill name is already present, skip that linkage
3. **Depth limit**: Package Linking chain depth must not exceed 2 levels (direct + one level of indirection); anything beyond is truncated
4. **Frequency limit**: The same skill may trigger Package Linking at most 3 times in a single session; once the limit is reached, silently skip

### Implementation Hints

```
Before triggering Package Linking:
  1. Check the _LINKED_CHAIN depth counter (initial 0)
  2. If depth >= 2 → skip, do not trigger Package Linking
  3. Check _TRIGGERED_SKILLS frequency record
  4. If this skill has already triggered >= 3 times → skip
  5. Execute Package Linking, depth +1, frequency +1

After completion:
  6. depth -1 (exit current Package Linking level)
```

### Example

```
github-pr-manager clones a PR → triggers Package Linking → universal-project-kickoff (depth 1)
  → Initialization + capability recommendation complete → triggers Package Linking → quick-plugin-installer (depth 2)
    → Installation complete → triggers Package Linking → depth limit reached, skip
```

## 7. Dependency Health Check

To ensure PACKAGE_MODE Package Linking discovery works correctly, a lightweight health check should be performed on first load of package-context.md:

### Check Steps

1. Glob scan `skills/*/SKILL.md` to list all skills
2. Verify each SKILL.md's frontmatter is parseable (at minimum contains a `name` field)
3. If any SKILL.md has malformed frontmatter, log a warning but do not abort
4. Compare `capabilities` tags against the tag registry in CONTRIBUTING.md
5. If unregistered tags are found, prompt the developer to update the registry

### Degradation Strategy

If the health check finds a malformed SKILL.md for any skill declaring `capabilities: ["skill-discovery"]` (a capability relied upon by multiple skills), other skills should:
- Silently skip `skill-discovery` Package Linking (no error)
- Continue executing their own core functionality
- Issue a one-time hint on first encountering a node that needs linking: "Some skill linking is temporarily unavailable"

## 8. Package Linking Chain Extension

Package Linking may propagate in chains, but respects the following depth limits:

| Linking level | Description | Allowed? |
|---------------|-------------|----------|
| First level   | Skill A completes → recommends skill B | ✅ Allowed |
| Second level  | Skill B completes → recommends skill C | ✅ Allowed |
| Third level+  | Skill C completes → recommends skill D | ❌ Forbidden (truncated) |

### Typical Linking Chain Example

```
1. github-pr-manager clones an unfamiliar project PR
   → First-level linking: recommend universal-project-kickoff to initialize project

2. universal-project-kickoff completes CLAUDE.md generation + capability recommendation
   → Second-level linking: recommend quick-plugin-installer to install missing tools

3. quick-plugin-installer completes installation
   → Third-level linking: would recommend capability discovery again → ❌ truncated
   → Alternative: present all follow-up suggestions as a single list within the second-level linking result
```

Third-level linking and beyond should be replaced with a "single-shot suggestion list": within the second-level linking result, present all possible follow-up operations as a list rather than triggering chained recommendations.
