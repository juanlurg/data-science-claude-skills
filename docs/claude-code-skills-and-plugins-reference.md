# Claude Code Skills & Plugins Reference

> A comprehensive reference for building domain-specific skill packs and plugins for Claude Code.
> Created to inform the design of a data science plugin.

---

## Table of Contents

1. [Extension Mechanisms Overview](#1-extension-mechanisms-overview)
2. [Skills Deep Dive](#2-skills-deep-dive)
3. [Plugins Deep Dive](#3-plugins-deep-dive)
4. [Skills vs Plugins vs Commands](#4-skills-vs-plugins-vs-commands)
5. [Best Practices](#5-best-practices)
6. [Architecture Patterns for Skill Collections](#6-architecture-patterns-for-skill-collections)
7. [Key Resources](#7-key-resources)

---

## 1. Extension Mechanisms Overview

Claude Code offers eight distinct extension mechanisms. Each serves a different purpose.

| Mechanism | What It Does | Format | Scope |
|-----------|-------------|--------|-------|
| **Skills** | Teach Claude new workflows and domain knowledge | `SKILL.md` with YAML frontmatter | Project, personal, enterprise, plugin |
| **Hooks** | Run shell commands/prompts/agents at lifecycle events | JSON config in settings or frontmatter | User, project, local, plugin, per-skill |
| **Plugins** | Bundle skills + agents + hooks + MCP + LSP into a distributable package | Directory with `.claude-plugin/plugin.json` | User, project, local, managed |
| **MCP Servers** | Connect Claude to external tools, APIs, and databases | `.mcp.json` or CLI configuration | User, project, local, plugin |
| **Subagents** | Specialized AI assistants with isolated context and custom system prompts | Markdown with YAML frontmatter in `.claude/agents/` | Project, personal, plugin, CLI flag |
| **CLAUDE.md** | Persistent project/user context loaded at every session startup | Plain Markdown at project root or `~/.claude/` | Always loaded |
| **Rules** | Behavioral constraints via permission settings | JSON in settings files | User, project, local, managed |
| **LSP Servers** | Language intelligence (diagnostics, completions) | `.lsp.json` config | Plugin or standalone |

### When to Use Which

| Goal | Use |
|------|-----|
| Teach Claude a new workflow or domain | **Skill** |
| Enforce a deterministic action (formatting, linting) | **Hook** (command type) |
| Connect to an external API/database | **MCP Server** |
| Delegate a task to an isolated specialist | **Subagent** |
| Share a collection of capabilities as a package | **Plugin** |
| Set project-wide conventions and context | **CLAUDE.md** |
| Add language-aware diagnostics | **LSP Server** |
| Gate or modify tool behavior | **Hook** (PreToolUse/PermissionRequest) |

### How They Compose

- **Plugins** bundle skills, agents, hooks, MCP servers, and LSP servers into one distributable unit
- **Skills** can run inside subagents via `context: fork`
- **Subagents** can preload skills via the `skills` frontmatter field
- **Hooks** can be scoped to a skill's or agent's lifetime via frontmatter
- **MCP servers** can be defined per-plugin, per-subagent, or globally

---

## 2. Skills Deep Dive

Skills follow the open [Agent Skills](https://agentskills.io) standard, originally developed by Anthropic and now adopted by 25+ tools including Gemini CLI, Cursor, OpenAI Codex, VS Code, and GitHub Copilot.

### 2.1 Core Concept

A skill is a **directory containing a `SKILL.md` file** with YAML frontmatter (metadata) and Markdown body (instructions). Claude loads skills on demand when relevant, or users invoke them directly via `/skill-name`.

### 2.2 File Format

```yaml
---
name: explain-code
description: Explains code with visual diagrams and analogies. Use when explaining how code works.
---

When explaining code, always include:
1. **Start with an analogy**: Compare the code to everyday life
2. **Draw a diagram**: Use ASCII art to show flow
3. **Walk through the code**: Step-by-step
4. **Highlight a gotcha**: Common mistake or misconception
```

### 2.3 Directory Structure

**Minimal skill:**
```
my-skill/
└── SKILL.md           # Required entry point
```

**Full skill with supporting files:**
```
my-skill/
├── SKILL.md              # Main instructions (required, <500 lines)
├── reference.md          # Detailed API docs (loaded when needed)
├── examples.md           # Usage examples (loaded when needed)
├── template.md           # Template for Claude to fill in
├── scripts/
│   ├── extract.py        # Utility script (executed, not loaded)
│   └── validate.sh       # Validation script
├── references/
│   └── REFERENCE.md      # Detailed technical reference
└── assets/
    ├── templates/        # Document templates
    └── schemas/          # Data schemas, lookup tables
```

Reference supporting files from `SKILL.md` so Claude knows what each contains:

```markdown
## Additional resources
- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

### 2.4 Storage Locations and Priority

| Location | Path | Scope | Priority |
|----------|------|-------|----------|
| Enterprise | Managed settings (admin-deployed) | All users in organization | 1 (highest) |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects | 2 |
| Project | `.claude/skills/<skill-name>/SKILL.md` | Current project only | 3 (lowest) |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled | Namespaced |

When skills share the same name, higher-priority locations win: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespacing so they never conflict.

**Monorepo support:** When editing files in subdirectories, Claude auto-discovers skills from nested `.claude/skills/` directories (e.g., `packages/frontend/.claude/skills/`).

**`--add-dir` support:** Skills in directories added via `--add-dir` are loaded automatically with live change detection — editable during a session without restart.

### 2.5 Complete Frontmatter Reference

All fields are optional. Only `description` is strongly recommended.

#### Open Standard Fields (agentskills.io)

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes (per spec) | Max 64 chars. Lowercase letters, numbers, hyphens only. Must match directory name. No consecutive hyphens. |
| `description` | Yes (per spec) | Max 1024 chars. What the skill does AND when to use it. Include keywords for task matching. |
| `license` | No | License identifier or reference (e.g., `Apache-2.0`) |
| `compatibility` | No | Max 500 chars. Environment requirements (e.g., `Requires git, docker, jq`) |
| `metadata` | No | Arbitrary string-to-string key-value map (e.g., `author`, `version`) |
| `allowed-tools` | No | Space-delimited pre-approved tools. **Experimental.** |

#### Claude Code Extended Fields

| Field | Description |
|-------|-------------|
| `argument-hint` | Hint shown during autocomplete (e.g., `[issue-number]`, `[filename] [format]`) |
| `disable-model-invocation` | `true` = Claude cannot auto-load this skill; manual-only via `/name`. Default: `false` |
| `user-invocable` | `false` = hidden from `/` menu; background knowledge Claude can invoke. Default: `true` |
| `allowed-tools` | Comma-separated tools Claude can use without permission when skill is active (Claude Code extends the open standard field with comma-separated syntax and runtime permission bypassing) |
| `model` | Model to use when this skill is active |
| `context` | `fork` = run in an isolated subagent context |
| `agent` | Subagent type when `context: fork` is set: `Explore`, `Plan`, `general-purpose`, or custom agent name |
| `hooks` | Hooks scoped to this skill's lifecycle (same format as settings-based hooks) |

### 2.6 Invocation Control

| Frontmatter Setting | User Can Invoke | Claude Can Invoke | Context Loading |
|---------------------|----------------|-------------------|-----------------|
| (defaults) | Yes | Yes | Description always in context; full skill loads on invocation |
| `disable-model-invocation: true` | Yes | No | Description NOT in context; only loads when user invokes |
| `user-invocable: false` | No | Yes | Description always in context; loads when Claude invokes |

### 2.7 String Substitution Variables

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking. If absent in content, arguments appended as `ARGUMENTS: <value>` |
| `$ARGUMENTS[N]` | Access specific argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` (`$0` = first arg, `$1` = second) |
| `${CLAUDE_SESSION_ID}` | Current session ID |

Example:

```yaml
---
name: migrate-component
description: Migrate a component from one framework to another
---
Migrate the $0 component from $1 to $2.
Preserve all existing behavior and tests.
```

`/migrate-component SearchBar React Vue` → `$0` = SearchBar, `$1` = React, `$2` = Vue.

### 2.8 Dynamic Context Injection

The `` !`command` `` syntax runs shell commands as **preprocessing** before the skill content is sent to Claude. The command output replaces the placeholder.

```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---
## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`
```

Execution flow: (1) each `` !`command` `` runs immediately, (2) output replaces placeholder, (3) Claude receives fully-rendered prompt with actual data.

### 2.9 Running Skills in Subagents

Add `context: fork` to run in isolation:

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---
Research $ARGUMENTS thoroughly using Glob and Grep.
Summarize findings with specific file references.
```

| Approach | System Prompt | Task | Also Loads |
|----------|--------------|------|------------|
| Skill with `context: fork` | From agent type (Explore, Plan, etc.) | SKILL.md content | CLAUDE.md |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md |

**Important:** `context: fork` skills need explicit task instructions. Guidelines-only skills will leave the subagent without an actionable prompt.

### 2.10 Skill Description Budget

Skill descriptions are loaded into context with a **dynamic budget of 2% of the context window** (fallback: 16,000 characters). Run `/context` to check for warnings about excluded skills. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable.

### 2.11 Extended Thinking

Include the word **"ultrathink"** anywhere in skill content to enable extended thinking mode.

### 2.12 Restricting Skill Access

1. **Deny the Skill tool** in `/permissions`: add `Skill` to deny rules
2. **Allow/deny specific skills**: `Skill(commit)` (exact), `Skill(review-pr *)` (prefix)
3. **Hide individual skills**: `disable-model-invocation: true` in frontmatter

---

## 3. Plugins Deep Dive

Plugins are self-contained directories that bundle skills, agents, hooks, MCP servers, and LSP servers into a distributable package. Requires Claude Code 1.0.33+.

### 3.1 Plugin Directory Structure

```
my-plugin/
├── .claude-plugin/           # Metadata directory (optional)
│   └── plugin.json           # ONLY plugin.json goes here
├── commands/                 # Slash commands as .md files (AT ROOT)
├── agents/                   # Subagent definitions (AT ROOT)
├── skills/                   # Skills with SKILL.md (AT ROOT)
│   └── code-review/
│       └── SKILL.md
├── hooks/                    # Event handlers (AT ROOT)
│   └── hooks.json
├── scripts/                  # Utility scripts
├── .mcp.json                 # MCP server configs (AT ROOT)
├── .lsp.json                 # LSP server configs (AT ROOT)
├── LICENSE
└── CHANGELOG.md
```

**Critical:** Do NOT put `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`. Only `plugin.json` belongs there. Everything else is at the plugin root.

### 3.2 Plugin Manifest (`plugin.json`)

Only `name` is required if a manifest is included. The manifest itself is optional — Claude Code auto-discovers components in default locations.

```json
{
  "name": "my-plugin",
  "description": "Brief plugin description",
  "version": "1.0.0",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

**Custom paths supplement default directories** — they do NOT replace them. All paths must be relative and start with `./`.

### 3.3 Namespacing

Plugin skills are always namespaced: `/plugin-name:skill-name`. The `name` field determines the prefix. This prevents conflicts between plugins.

### 3.4 Installation Scopes

| Scope | Settings File | Use Case |
|-------|--------------|----------|
| `user` | `~/.claude/settings.json` | Personal plugins (default) |
| `project` | `.claude/settings.json` | Team plugins via version control |
| `local` | `.claude/settings.local.json` | Project-specific, gitignored |
| `managed` | `managed-settings.json` | Organization-managed (read-only) |

### 3.5 CLI Commands

```bash
claude plugin install <plugin> [--scope user|project|local]
claude plugin uninstall <plugin> [--scope ...]
claude plugin enable <plugin> [--scope ...]
claude plugin disable <plugin> [--scope ...]
claude plugin update <plugin> [--scope user|project|local|managed]
```

### 3.6 Testing During Development

```bash
claude --plugin-dir ./my-plugin
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

Restart Claude Code to pick up changes.

### 3.7 Plugin Environment Variable

`${CLAUDE_PLUGIN_ROOT}` provides the absolute path to the plugin directory. Use in hooks, MCP configs, and scripts:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"
      }]
    }]
  }
}
```

### 3.8 Plugin MCP Servers

In `.mcp.json` at plugin root:

```json
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": { "DB_URL": "${DB_URL}" }
  }
}
```

Or inline in `plugin.json` under `mcpServers`.

### 3.9 Plugin Hooks

In `hooks/hooks.json`:

```json
{
  "description": "Automatic code formatting",
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh",
        "timeout": 30
      }]
    }]
  }
}
```

### 3.10 Plugin Caching

Marketplace plugins are cached to `~/.claude/plugins/cache`. Installed plugins cannot reference files outside their directory — `../` paths won't work. You MUST bump the version for existing users to see changes.

### 3.11 Version Management

Follow semver: `MAJOR.MINOR.PATCH`. Start at `1.0.0` for first stable release. Pre-release versions like `2.0.0-beta.1` are supported.

### 3.12 Marketplace Distribution

Plugins can be distributed through the official directory (`anthropics/claude-plugins-official`), self-hosted marketplaces, or direct git URLs.

```bash
# Official directory
/plugin install my-plugin@claude-plugin-directory

# Self-hosted marketplace
/plugin marketplace add owner/repo
/plugin install my-plugin@marketplace-name

# Browse interactively
/plugin > Discover
```

Self-hosted `marketplace.json`:
```json
{
  "name": "my-marketplace",
  "description": "My plugin marketplace",
  "owner": { "name": "Author", "email": "author@example.com" },
  "plugins": [{
    "name": "my-plugin",
    "description": "Description",
    "version": "1.0.0",
    "source": "./"
  }]
}
```

---

## 4. Skills vs Plugins vs Commands

### 4.1 Standalone Skills vs Plugin Skills

| Aspect | Standalone (`.claude/skills/`) | Plugin (`<plugin>/skills/`) |
|--------|-------------------------------|----------------------------|
| Invocation | `/hello` | `/plugin-name:hello` |
| Best for | Personal workflows, project-specific, quick experiments | Sharing with teams, community distribution, versioned releases |
| Namespace | Direct, can conflict | Namespaced, isolated |
| Version control | Manual | Semantic versioning via `plugin.json` |
| Distribution | Copy files | Marketplace, git URL, `--plugin-dir` |
| Additional capabilities | Skills only | Skills + agents + hooks + MCP + LSP |

### 4.2 Skills vs Legacy Custom Slash Commands

Custom slash commands (`.claude/commands/*.md`) are the **legacy form** of skills. They have been merged:

- `.claude/commands/review.md` and `.claude/skills/review/SKILL.md` both create `/review`
- Existing command files continue to work
- Skills are preferred — they support directories for supporting files, frontmatter for invocation control, and automatic loading
- If a skill and command share the same name, the **skill takes precedence**

### 4.3 Skills vs Subagents

| Feature | Skills | Subagents |
|---------|--------|-----------|
| Context | Inline (shared) or forked (`context: fork`) | Always isolated |
| Purpose | Reusable instructions and workflows | Specialized task delegation |
| System prompt | Main conversation's system prompt | Custom system prompt |
| Tool restrictions | Optional `allowed-tools` | Full `tools`/`disallowedTools` control |
| Persistent memory | No | Yes (with `memory` field) |
| Can spawn children | No | Cannot spawn other subagents |

### 4.4 Skills vs CLAUDE.md

| Feature | Skills | CLAUDE.md |
|---------|--------|-----------|
| Loading | On-demand when triggered | Always at startup |
| Format | SKILL.md with YAML frontmatter | Plain Markdown |
| Discovery | Via name/description matching | Always present |
| Purpose | Domain-specific capabilities | Persistent project context |

### 4.5 Skills vs MCP Servers

**Complementary, not competing.** MCP provides tools (structured function calls). Skills provide procedural knowledge and workflow instructions. A skill can reference MCP tools: `BigQuery:bigquery_schema`.

---

## 5. Best Practices

### 5.1 Progressive Disclosure

This is the core architectural pattern that makes skills efficient.

| Level | When Loaded | Token Cost | Content |
|-------|------------|------------|---------|
| **Level 1: Metadata** | Always at startup | ~50-100 tokens/skill | `name` + `description` from frontmatter |
| **Level 2: Instructions** | When skill is activated | <5,000 tokens recommended | Full SKILL.md body |
| **Level 3+: Resources** | As needed during execution | Effectively unbounded | Referenced files, scripts, templates |

**Runtime flow:**
1. Startup → parse frontmatter only → inject metadata into system prompt
2. User request → Claude matches against skill descriptions
3. Activation → Claude reads full SKILL.md content
4. Selective resource loading → additional files read only when needed
5. Script execution → scripts are **executed** (output enters context), never loaded as source

### 5.2 Conciseness

The context window is a shared resource. Only add context Claude does not already possess.

- "Does Claude really need this explanation?"
- "Can I assume Claude already knows this?"
- "Does this paragraph justify its token cost?"

### 5.3 Keep SKILL.md Under 500 Lines

Move detailed reference material to separate files. Keep file references **one level deep** from SKILL.md — deeply nested chains cause Claude to partially read files and lose track.

**Pattern 1 — Guide with references:**
```markdown
## Advanced features
See [FORMS.md](FORMS.md) for complete guide
See [REFERENCE.md](REFERENCE.md) for all methods
```

**Pattern 2 — Domain-specific organization:**
```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md
    ├── sales.md
    └── marketing.md
```

### 5.4 Description Writing

The description is the **primary signal** Claude uses to choose from available skills. Write in third person (it gets injected verbatim into the system prompt).

**Good:**
```yaml
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.
```

**Bad:**
```yaml
description: Helps with PDFs.
```

**Critical rule from Superpowers:** Description must contain ONLY triggering conditions, NEVER summarize the workflow. Testing revealed that workflow summaries in descriptions cause Claude to follow the description as a shortcut instead of reading the full SKILL.md body.

### 5.5 Naming Conventions

- **Directories:** lowercase with hyphens (kebab-case)
- **Gerund form preferred:** `processing-pdfs`, `analyzing-spreadsheets`, `managing-databases`
- **Acceptable alternatives:** noun phrases (`pdf-processing`), action-oriented (`process-pdfs`)
- **Avoid:** vague names (`helper`, `utils`), overly generic (`documents`, `data`)
- **SKILL.md:** always uppercase filename

### 5.6 Degrees of Freedom

Match instruction specificity to task fragility:

| Freedom Level | Format | When |
|---------------|--------|------|
| **High** | Text instructions | Multiple valid approaches, context-dependent decisions |
| **Medium** | Pseudocode/parameterized scripts | Preferred pattern exists, some variation acceptable |
| **Low** | Exact scripts with few parameters | Fragile operations, consistency critical |

### 5.7 Evaluation-Driven Development

1. **Identify gaps:** Run Claude on representative tasks WITHOUT a skill. Document failures.
2. **Create evaluations:** Build 3+ scenarios testing those specific gaps.
3. **Establish baseline:** Measure performance without the skill.
4. **Write minimal instructions:** Just enough to address identified gaps.
5. **Iterate:** Execute evaluations, compare results, refine.

### 5.8 Iterative Development with Two Claude Instances

- **Claude A** (expert/designer): Helps design and refine the skill
- **Claude B** (user/tester): Tests the skill on real tasks

Observe Claude B's actual behavior and bring insights back to A. Claude models understand the Skill format natively.

### 5.9 Workflow Patterns

**Checklist pattern:**
```markdown
Copy this checklist and track your progress:
- [ ] Step 1: Analyze the input
- [ ] Step 2: Create mapping
- [ ] Step 3: Validate
- [ ] Step 4: Execute
- [ ] Step 5: Verify output
```

**Feedback loop pattern:** Run validator → fix errors → repeat. Improves output quality for precision tasks.

### 5.10 Code and Script Best Practices

- Handle errors explicitly — don't let scripts fail silently
- Self-documenting constants — comment *why* values were chosen
- Provide utility scripts — more reliable than generated code, saves tokens
- Distinguish execute vs. read — make clear whether Claude should run or reference a script
- Create verifiable intermediate outputs — plan-validate-execute pattern
- Use forward slashes always (no Windows-style paths)

### 5.11 Anti-Patterns to Avoid

- Offering too many options without a clear default (provide recommended approach with escape hatch)
- Deeply nested file references
- Over-explaining things Claude already knows
- Time-sensitive content that will go stale
- Installing packages globally
- Undocumented magic numbers in scripts
- Inconsistent terminology

### 5.12 Testing

- Test with **all models** you plan to support (Haiku, Sonnet, Opus have different instruction-following)
- Create at least 3 evaluations per skill
- Test with realistic usage scenarios
- Gather feedback from team members

---

## 6. Architecture Patterns for Skill Collections

### 6.1 The Superpowers Pattern (Reference Implementation)

[Superpowers](https://github.com/obra/superpowers) (53k+ stars) is the most mature Claude Code plugin, created by Jesse Vincent. It demonstrates key architectural patterns.

#### Directory Structure

```
superpowers/
├── .claude-plugin/
│   ├── plugin.json              # Minimal manifest
│   └── marketplace.json         # Self-hosted marketplace config
├── agents/
│   └── code-reviewer.md         # Subagent definition
├── commands/
│   ├── brainstorm.md            # Thin wrappers delegating to skills
│   ├── execute-plan.md
│   └── write-plan.md
├── hooks/
│   ├── hooks.json               # SessionStart bootstrap
│   └── session-start.sh
├── lib/
│   └── skills-core.js           # Skill resolution engine
├── skills/
│   ├── brainstorming/
│   │   └── SKILL.md
│   ├── systematic-debugging/
│   │   └── SKILL.md
│   ├── test-driven-development/
│   │   ├── SKILL.md
│   │   └── testing-anti-patterns.md
│   ├── writing-skills/
│   │   ├── SKILL.md
│   │   ├── anthropic-best-practices.md
│   │   ├── examples/
│   │   └── persuasion-principles.md
│   └── ... (14 skills total)
└── tests/
```

#### Key Observations

1. **Flat namespace:** All skills sit directly under `skills/`, one level deep. No nested category folders.
2. **Three complexity tiers:** Single-file (`brainstorming/SKILL.md`) to multi-file bundles (`writing-skills/` with 7 files).
3. **Commands delegate to skills:** Thin wrappers with `disable-model-invocation: true` that invoke the actual skill.
4. **SessionStart hook:** Bootstrap logic runs on every session start.
5. **Minimal manifest:** Only `name`, `description`, `version`, `author`, `license`, `keywords`.

#### Commands as Thin Wrappers

```yaml
---
description: "You MUST use this before any creative work..."
disable-model-invocation: true
---

Invoke the superpowers:brainstorming skill and follow it exactly as presented to you
```

### 6.2 Cross-Referencing Skills

**Preferred — Explicit requirement markers with namespace:**
```markdown
**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development
**REQUIRED BACKGROUND:** You MUST understand superpowers:systematic-debugging
```

**Within-skill file references** use relative paths:
```markdown
- `./implementer-prompt.md` - Dispatch implementer subagent
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer
```

**Prohibited — `@` file references:** Force-loads entire files into context immediately, consuming 200k+ tokens.

**Prohibited — Direct file paths:** Unclear about whether the reference is required.

### 6.3 Structuring a Domain-Specific Plugin

Based on the patterns above, a domain-specific plugin (like a data science one) should follow this structure:

```
data-science-skills/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── exploratory-data-analysis/
│   │   ├── SKILL.md                    # Overview + navigation (<500 lines)
│   │   ├── pandas-patterns.md          # Reference: common pandas operations
│   │   └── scripts/
│   │       └── profile-dataset.py      # Utility script
│   ├── feature-engineering/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── numerical.md
│   │       ├── categorical.md
│   │       └── temporal.md
│   ├── model-training/
│   │   └── SKILL.md
│   ├── model-evaluation/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── plot-metrics.py
│   └── data-pipeline/
│       └── SKILL.md
├── agents/
│   └── data-reviewer.md               # Specialist subagent
├── hooks/
│   └── hooks.json                      # Optional lifecycle hooks
├── scripts/                            # Shared utility scripts
├── LICENSE
└── README.md
```

#### Design Principles for Domain Plugins

1. **One skill per workflow/task type.** Don't bundle EDA and model training into one skill.
2. **Skills are reference guides, not tutorials.** Write for Claude, not for humans.
3. **Use progressive disclosure.** SKILL.md = table of contents; heavy content in supporting files.
4. **Include utility scripts.** Scripts for deterministic operations (data profiling, visualization) are more reliable than generated code.
5. **Cross-reference with namespace prefix.** `data-science-skills:feature-engineering` with explicit requirement markers.
6. **Test with evaluation scenarios.** Identify where Claude fails without the skill, then write the minimum instructions to fix it.

### 6.4 TDD for Skills (Superpowers Pattern)

Treat skill creation as TDD applied to documentation:

| TDD Concept | Skill Analog |
|-------------|-------------|
| Test case | Pressure scenario with subagent |
| Production code | SKILL.md document |
| RED | Agent violates rule without skill |
| GREEN | Agent complies with skill present |
| REFACTOR | Close rationalization loopholes |

Process:
1. **RED:** Run a scenario without the skill. Document where Claude fails or rationalizes.
2. **GREEN:** Write minimal skill addressing those failures. Re-run. Claude should comply.
3. **REFACTOR:** Find new rationalizations. Add explicit counters. Re-test until robust.

### 6.5 Rationalization Prevention (for Discipline Skills)

For skills that enforce practices (e.g., "always validate data before modeling"):

1. **The Iron Law:** Single non-negotiable rule in a code block
2. **Gate Function:** Step-by-step process before any claim
3. **Red Flags list:** Thoughts/phrases that signal rationalization
4. **Rationalization Table:** Every excuse mapped to counter-argument
5. **Spirit over Letter clause:** "Violating the letter IS violating the spirit"

### 6.6 Subagent Delegation Pattern

For complex multi-step workflows:

1. **Controller** reads plan, extracts tasks
2. **Per task:** Dispatch fresh implementer subagent with full task text
3. **Spec reviewer** (separate subagent) confirms code matches spec
4. **Code quality reviewer** (separate subagent) reviews quality
5. **Review loops:** Fix → re-review until passing

Each subagent type gets its own prompt template file in the skill directory.

### 6.7 Hook-Based Bootstrap

Register a `SessionStart` hook to run setup logic:

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup|resume|clear|compact",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh",
        "async": false
      }]
    }]
  }
}
```

### 6.8 Token Budget Guidelines

| Skill Type | Target |
|------------|--------|
| Frequently-loaded skills | < 200 words |
| Standard skills | < 500 words |
| SKILL.md body | < 500 lines |
| Frontmatter description | < 1024 chars |

Techniques for staying within budget:
- Move detailed docs to reference files
- Use cross-references instead of repeating content
- Compress examples (20 words vs 42 for same info)
- Eliminate redundancy with referenced skills

---

## 7. Key Resources

### Official Documentation

- [Skills documentation](https://code.claude.com/docs/en/skills) — File format, frontmatter, invocation, discovery
- [Plugins documentation](https://code.claude.com/docs/en/plugins) — Plugin manifest, structure, distribution
- [Hooks documentation](https://code.claude.com/docs/en/hooks) — Lifecycle events, handlers, configuration
- [Subagents documentation](https://code.claude.com/docs/en/sub-agents) — Agent definitions, tool control, memory
- [MCP documentation](https://code.claude.com/docs/en/mcp) — Server configuration, transports, tools
- [Agent Skills best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — Progressive disclosure, evaluation-driven development

### Official Repositories

- [anthropics/skills](https://github.com/anthropics/skills) — Official skills (PDF, Excel, Word, PowerPoint)
- [anthropics/claude-code](https://github.com/anthropics/claude-code) — Claude Code source
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — Official plugin directory (48+ plugins)
- [anthropics/claude-cookbooks](https://github.com/anthropics/claude-cookbooks) — Cookbook examples

### Open Standard

- [agentskills.io](https://agentskills.io) — Agent Skills open standard specification
- [agentskills/agentskills](https://github.com/agentskills/agentskills) — Reference implementation (`skills-ref` library)

### Community

- [obra/superpowers](https://github.com/obra/superpowers) — Superpowers plugin (53k+ stars) — TDD, debugging, collaboration patterns
- [Anthropic blog: Agent Skills](https://www.anthropic.com/engineering/claude-code-agent-skills) — "Equipping Agents for the Real World with Agent Skills"

### Official Plugin Directory Categories

| Category | Examples |
|----------|---------|
| Development | LSP servers (11 languages), frontend-design, greptile, serena |
| Productivity | commit-commands, code-review, github, gitlab, linear, asana, slack |
| Security | security-guidance, sonatype-guide |
| Testing | playwright |
| Database | supabase, firebase, pinecone |
| Monitoring | sentry, posthog |
| Deployment | vercel |
| Design | figma |
