# Validation Scenarios

This document provides a set of validation scenarios for LLM self-checking when executing the `universal-project-kickoff` skill. After performing scanning and matching according to the scenario descriptions, verify that the recommendation results meet expectations.

## Test Scenarios

### Scenario 1: Standard Spring Boot Project

**Project characteristics:**
- `pom.xml` exists, contains `spring-boot-starter-parent`
- `src/main/java/` directory exists
- `application.yml` exists

**Expected fingerprint tags:** `java`, `spring-boot`, `maven`

**Expected recommendations (at minimum):**
- `github-pr-manager` (default always_recommend)
- `universal-project-kickoff` (default always_recommend)

**Verification points:**
- [ ] All skills matching `java`, `spring-boot`, `maven` tags have score > 0
- [ ] Skills in always_recommend appear at the top of the recommendation list
- [ ] Recommendation count does not exceed `max_recommendations` (default 10)

---

### Scenario 2: React + TypeScript Frontend Project

**Project characteristics:**
- `package.json` exists, contains `react` and `typescript` deps
- `tsconfig.json` exists
- `vite.config.ts` exists

**Expected fingerprint tags:** `typescript`, `react`, `nodejs`, `vite`

**Expected recommendations (at minimum):**
- `quick-plugin-installer` (plugin installation related)
- `github-pr-manager` (always_recommend)

**Verification points:**
- [ ] Skills matching `react`, `typescript` tags receive +3 per tag
- [ ] Skills aligned with the `frontend` domain receive category_bonus

---

### Scenario 3: Empty Project / No Configuration Files

**Project characteristics:**
- No recognizable configuration files exist
- May be an empty directory or contain only a README

**Expected fingerprint tags:** None (empty set)

**Verification points:**
- [ ] Should not error or abort
- [ ] Skills in the always_recommend list are still recommended (as general recommendations)
- [ ] Plugins in always_recommend_plugins are still recommended

---

### Scenario 4: Python FastAPI Project

**Project characteristics:**
- `pyproject.toml` exists, contains `fastapi` dep
- `requirements.txt` exists, contains `fastapi`

**Expected fingerprint tags:** `python`, `fastapi`

**Verification points:**
- [ ] No duplicate scoring because both `pyproject.toml` and `requirements.txt` exist (deduplication)
- [ ] Skills matching the `python` tag receive +3

---

### Scenario 5: Monorepo (Multi-language Project)

**Project characteristics:**
- `package.json` exists (frontend subdirectory)
- `go.mod` exists (backend subdirectory)
- `docker-compose.yml` exists (root directory)

**Expected fingerprint tags:** `javascript`/`typescript`, `nodejs`, `go`, `docker`, `orchestration`

**Verification points:**
- [ ] All detected tags are included (does not stop after finding the first language)
- [ ] Recommended skills cover all detected technology stacks

---

### Scenario 6: Flutter Mobile Project

**Project characteristics:**
- `pubspec.yaml` exists, contains `flutter` dep
- `android/` and `ios/` directories exist

**Expected fingerprint tags:** `flutter`, `dart`, `mobile`, `cross-platform`, `android`, `ios`

**Verification points:**
- [ ] Mobile framework detection is active (detection matrix added in Phase 4)
- [ ] `mobile` domain category_bonus is correctly applied

---

### Scenario 7: Pure Docker Project

**Project characteristics:**
- Only `Dockerfile` and `docker-compose.yml` exist
- No other language configuration files

**Expected fingerprint tags:** `docker`, `container`, `orchestration`

**Verification points:**
- [ ] Does not error due to absence of language tags
- [ ] DevOps/Infra category skills receive category_bonus

---

### Scenario 8: Legacy Java 8 Project (Version Detection)

**Project characteristics:**
- `pom.xml` exists, `<java.version>` is `1.8`
- `src/main/java/` directory exists

**Expected fingerprint tags:** `java`, `java-8`, `maven`

**Verification points:**
- [ ] Version tag `java-8` is correctly extracted
- [ ] Skills tagged with `java-21` receive only +1 (base `java` match), not +3

---

## Edge Case Checklist

| Edge Case | Expected Behavior |
|-----------|------------------|
| Empty directory | No error, only recommend always_recommend list |
| Non-git directory | Normal scanning, does not depend on git context |
| Glob timeout | Silent degradation, mark partial scan as incomplete |
| Empty skill directory | Only recommend plugins and commands |
| settings.json does not exist | Only recommend skills, skip plugin scanning |
| SKILL.md frontmatter format error | Skip that skill, continue scanning others |
| Very large project (1000+ files) | Limit Glob depth, prioritize root directory config files |

## Usage

After executing the skill, verify against the scenarios and edge cases in this document. If the recommendation results do not match expectations, check:
1. Whether fingerprint detection correctly identified all configuration files
2. Whether the tag matching algorithm applied the correct weights
3. Whether any always_recommend/never_recommend rules are interfering

---

## Complete Walkthrough Examples

### Example 1: Java Spring Boot Project

**Input:** User opens a project containing `pom.xml` with `spring-boot-starter-parent`.

**Project fingerprint:** `java, spring-boot, maven`

**Recommended skills (top 5):**
| # | Name | Description | Match Reason | Source |
|---|------|-------------|-------------|--------|
| 1 | `springboot-patterns` | Spring Boot development patterns | Direct Spring Boot framework match | community |
| 2 | `java-pro` | Java professional development | Java language match | community |
| 3 | `springboot-tdd` | TDD development workflow | Spring Boot + testing match | community |
| 4 | `springboot-security` | Spring Boot security | Spring Boot framework match | community |
| 5 | `git-workflow` | Git workflow | General development skill | community |

**Recommended plugins:**
| # | Name | Description | Match Reason | Type |
|---|------|-------------|-------------|------|
| 1 | `plugin:github:github` | GitHub PR/Issue management | General development plugin | MCP |
| 2 | `plugin:context7:context7` | Documentation lookup | Referencing Spring Boot docs | MCP |

**Command discovery after user selects github and context7:**
MCP tools: `mcp__github__create_pull_request` (create PR, when needing to submit a merge request after committing), `mcp__context7__query-docs` (query documentation, when needing to look up Spring Boot API). Slash commands: `/commit` (standardized commits), `/code-review` (review code), `/create-pr` (create Pull Request).

### Example 2: React + Vite Frontend Project

**Input:** User opens a project containing `package.json` (react, vite deps) and `vite.config.ts`.

**Project fingerprint:** `javascript/typescript, react, vite, nodejs`

**Recommended skills (top 5):**
| # | Name | Description | Match Reason | Source |
|---|------|-------------|-------------|--------|
| 1 | `react-best-practices` | React best practices | Direct React framework match | community |
| 2 | `frontend-patterns` | Frontend development patterns | Frontend domain match | community |
| 3 | `javascript-pro` | JS professional development | JavaScript language match | community |
| 4 | `vite-patterns` | Vite build patterns | Vite tool match | community |
| 5 | `ui-ux-designer` | UI/UX design | Frontend domain related | community |

**Recommended plugins:**
| # | Name | Description | Match Reason | Type |
|---|------|-------------|-------------|------|
| 1 | `plugin:playwright:playwright` | Browser automation testing | Frontend E2E testing | MCP |
| 2 | `plugin:github:github` | PR management | General development plugin | MCP |

**Commands after user selection:** `mcp__github__search_code` (search code), `mcp__github__create_pull_request` (create PR). Slash commands: `/frontend-design` (frontend design), `/code-review` (review code), `/commit` (commit).

### Example 3: Unknown/Empty Project

**Input:** Empty directory or a directory with no known configuration files.

**Project fingerprint:** (None -- empty directory or no known config files detected)

**Detection result:** "\u{1F195} No known project type detected. Here are general recommendations:"

**Recommended skills (general):**
| # | Name | Description | Match Reason | Source |
|---|------|-------------|-------------|--------|
| 1 | `git-workflow` | Git workflow | General development skill | community |
| 2 | `code-review` | Code review | General development skill | community |
| 3 | `commit` | Standardized commits | General development skill | community |
| 4 | `file-organizer` | File organization | General utility skill | community |

**Recommended plugins (general):**
| # | Name | Description | Match Reason | Type |
|---|------|-------------|-------------|------|
| 1 | `plugin:github:github` | PR/Issue management | General development plugin | MCP |
| 2 | `plugin:longhand:longhand` | Session memory | General utility plugin | MCP |

**Commands after user selection:** `/commit` (when committing code), `/code-review` (when reviewing code), `/discover` (when rediscovering)

**Behavior:** Prompt the user: "If you'd like to see a full list of all installed capabilities, I can export the complete catalog for you."
