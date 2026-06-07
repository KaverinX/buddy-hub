# buddy-hub

**[English](./README.md)** | **[中文](./README_zh.md)** | **[使用指南](./USAGE_zh.md)**

> A Claude Code Plugin Marketplace by Velpro

A curated collection of Claude Code plugins focused on **spec-driven development**, **engineering discipline (test-first)**, **developer workflow automation**, and **multi-agent collaboration** — all built on a shared event-sourced knowledge graph.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

---

## Quick Start

### Install Marketplace

```bash
claude plugin marketplace add KaverinX/buddy-hub
```

### Update / Remove Marketplace

```bash
claude plugin marketplace update KaverinX/buddy-hub
claude plugin marketplace remove KaverinX/buddy-hub
```

---

## Plugin Management

```bash
claude plugin install flowsmith@buddy-hub   # install a plugin
claude plugin update  flowsmith@buddy-hub   # update a plugin
claude plugin uninstall flowsmith@buddy-hub # uninstall a plugin
claude plugin list                          # list installed plugins
```

> New to buddy-hub? Read the end-to-end walkthrough in **[USAGE_zh.md](./USAGE_zh.md)** — from a requirement, through clarification and design, to done — plus lightweight recipes for debugging, small changes, and generating a whole-project spec.

---

## Available Plugins

### 🔨 [flowsmith](./plugins/flowsmith) — State-Machine-Driven Development SOP

**Role: Core Orchestrator** | `v1.3.0` | 10 commands, 4 agents, 7 skills

Enforces a strict development cycle and now bakes in test-first discipline:
**PLANNING → ARCHITECTURE → TEST_FIRST → IMPLEMENTATION → OPTIMIZATION → REVIEW → DONE**.
Prevents "skip thinking, jump to coding" by requiring explicit input/output contracts at each stage — and prevents "skip testing" by gating progress on a green test suite.

**Key Features:**
- FSM-enforced phase transitions — no skipping allowed
- **TEST_FIRST phase + green-light gate** — write failing tests first (red), and you cannot leave IMPLEMENTATION until the suite passes (enforced by a PostToolUse hook)
- **Iron Law + red-flags discipline** across all skills — anti-rationalization rules that stop the agent from talking itself out of testing, root-causing, or clarifying
- **Requirement-clarification gate** (`/sop-brainstorm`) — Socratic clarification before planning, when the requirement is ambiguous
- **TDD** (red-green-refactor) and **systematic-debugging** (root-cause-before-fix) skills
- **Self-evolving** — `writing-skills` meta-skill + `/skill-scaffold` author new buddy-hub-style skills
- 4 independent-context subagents: Optimizer + Architecture / Security / Logic reviewers
- Cross-task knowledge accumulation via `.sop/lessons.md`
- Deep integration with spec-keeper: links a spec change as a planning constraint and auto-applies the delta on `/sop-close`

```bash
claude plugin install flowsmith@buddy-hub
```

---

### 📐 [spec-keeper](./plugins/spec-keeper) — Spec-Driven Development (SDD)

**Role: Spec Truth Keeper** | `v1.2.0` | 7 commands, 1 skill

Makes the **spec** a first-class citizen: a living, capability-organized specification that stays in sync with code, plus `proposal → apply → archive` change actions with `ADDED/MODIFIED/REMOVED` behavior-level deltas. Align on *what* before touching code, and keep that alignment diff-able and reviewable over time.

**Key Features:**
- **Living spec** under `spec/capabilities/<id>/spec.md` — the system's behavioral truth, organized by capability (not by ephemeral task)
- **Behavior-level deltas** (`ADDED/MODIFIED/REMOVED`) — brownfield-friendly diffs against existing truth
- **Forward & reverse flows:**
  - `/spec-propose` — forward: write the delta before implementing
  - `/spec-bootstrap` — reverse (full): capture an existing project's behavior into a whole-project spec baseline
  - `/spec-sync` — reverse (incremental): reconcile the spec from the current branch's actual changes
  - `/spec-apply` — merge a reviewed delta into the living spec (the only action that rewrites "truth")
  - `/spec-archive` · `/spec-check` (drift) · `/spec-status`
- Deep integration with flowsmith and context-keeper — every action emits SkillBus events, so spec changes flow into the knowledge graph (a "spec + event-sourcing" combination)

```bash
claude plugin install spec-keeper@buddy-hub
```

---

### 🔍 [code-archaeologist](./plugins/code-archaeologist) — Legacy Code Archaeology & Refactoring Aid

**Role: Legacy Code Analyst** | `v1.0.0` | 6 commands, 3 agents, 1 skill

Before refactoring, splitting, or deleting legacy code, dispatches three independent archaeologists to perform deep due diligence across three dimensions — preventing 90% of refactoring accidents.

**Key Features:**
- Three-dimensional parallel analysis: History + Dependency + Intent
- Detects hidden dependencies invisible to IDEs (reflection, config-driven calls, serialization contracts)
- Generates "uncrossable red lines" to prevent refactoring regressions
- Auto-injects archaeological conclusions into flowsmith's planning constraints
- Decision matrix produces actionable refactoring strategy recommendations

```bash
claude plugin install code-archaeologist@buddy-hub
```

---

### 👥 [co-review](./plugins/co-review) — Team Collaboration Review

**Role: Team Health Inspector** | `v1.0.0` | 4 commands, 3 agents, 1 skill

Horizontal code review for multi-author scenarios. Instead of reviewing individual code quality (flowsmith handles that), analyzes team collaboration health, interface conflicts, and completion signals.

**Key Features:**
- Three-layer architecture: Contribution profiling + Completion assessment + Collaboration risk detection
- Independent-context subagents prevent analysis contamination
- Pure-terminal TUI dashboard (`bash scripts/tui/dashboard.sh`)
- Privacy-first: per-person feedback strictly isolated — no cross-person comparison, no attitude judgment
- 5-level merge strategy: `merge-now` → `staged` → `coordinate` → `block` → `escalate`

```bash
claude plugin install co-review@buddy-hub
```

---

### 🎨 [formatter](./plugins/formatter) — Code Style Guardian

**Role: Code Style Guardian** | `v1.0.0` | 1 command, 2 hooks, 1 skill

Edit-time auto-formatting plus session-end style gate. Injects team coding conventions into Claude's editing actions, eliminating style debates.

**Key Features:**
- Built-in Alipay/Alibaba Java coding convention profile (~270 Eclipse JDT rules)
- PostToolUse hook: auto-format on every file edit
- Stop hook: global style check on all changed files before session ends
- Supports both Maven and Gradle projects with one-shot setup
- Extensible profile architecture — drop new XML to add language support

```bash
claude plugin install formatter@buddy-hub
```

---

### 📚 [context-keeper](./plugins/context-keeper) — Event-Sourced Knowledge Graph (Foundation)

**Role: Shared Foundation** | `v1.0.0` | 5 commands, 1 skill

The infrastructure layer the whole ecosystem builds on. An append-only event stream plus materialized views give every plugin a queryable, auditable, traceable memory — the SkillBus protocol that lets plugins observe each other without tight coupling.

**Key Features:**
- **Append-only `events.jsonl`** as the single source of truth + **materialized views** (`entities/`) that can be fully rebuilt
- **SkillBus v0 event protocol** — now carries `spec.*` (proposed/bootstrapped/synced/applied/drift) and `test.*` (red/green/gate/debug) events from the latest upgrade
- **Non-invasive mirror hooks** — capture state changes at write-time without touching plugin logic
- **Provenance / evidence** on every event; forward-compatible via an `ext.<plugin>.<field>` subtree (append-only, never rename)

```bash
claude plugin install context-keeper@buddy-hub
```

---

## Ecosystem Architecture

The plugins form an interconnected ecosystem, not isolated tools. Everything new is built on the context-keeper foundation:

```
   📐 spec-keeper (SDD)                                🔨 flowsmith (Core Orchestrator)
   living spec + delta                  ── linked ──▶  BRAINSTORM(gate) → PLAN → ARCH
   propose / bootstrap / sync            constraint     → TEST_FIRST(red) → IMPL → OPT → REVIEW → DONE
        ▲   │ /sop-close auto /spec-apply              │              │ green-light gate
        │   ▼                                          │              │
   merge delta into living truth                       │ Hook: refactor │ Hook: multi-author
                                                        ▼ intent         ▼ after review
                          ┌────────────────┐  ┌────────────────┐   ┌────────────────┐
                          │ 🔍 code-       │  │ 👥 co-review   │   │ 🎨 formatter   │
                          │ archaeologist  │  │ team health    │   │ style guardian │
                          │ inject plan.md │  │ reads .sop/*   │   │ orthogonal     │
                          └────────────────┘  └────────────────┘   └────────────────┘
                                          │          │
                                          ▼          ▼
                          ┌───────────────────────────────────────────────┐
                          │  📚 context-keeper — Event-Sourced Foundation   │
                          │  events.jsonl (append-only) + materialized      │
                          │  views · SkillBus protocol · spec.* / test.*    │
                          │  knowledge graph shared & emitted to by all     │
                          └───────────────────────────────────────────────┘
```

### Plugin Relationships

| From | To | Mechanism | Description |
|------|----|-----------|-------------|
| spec-keeper | flowsmith | Planning constraint | Living spec injected into `plan.md`; `/sop-close` auto-runs `/spec-apply` |
| flowsmith | spec-keeper | `linked_change_id` | Task links a spec change; finalized task description inherited from proposal/brainstorm |
| flowsmith | code-archaeologist | Hook trigger | Detects refactor/split/migrate keywords → suggests `/arch-init` |
| flowsmith | co-review | Hook trigger | After `/sop-review` + multi-author detected → suggests `/scope-review` |
| code-archaeologist | flowsmith | `/arch-handoff` | Injects conclusions into `plan.md` constraints & prerequisites |
| co-review | flowsmith | Context read | Reads `.sop/` artifacts for more precise analysis |
| formatter | *(none)* | Orthogonal | Operates independently — no state interaction |
| **All plugins** | context-keeper | SkillBus emit | Emit events to the shared knowledge graph (`spec.*`, `test.*`, `task.*`, …) |
| **All plugins** | `lessons.md` | Shared R/W | Cross-task knowledge accumulation and injection |

---

## Project Structure

```
buddy-hub/
├── .claude-plugin/marketplace.json   # Marketplace metadata (6 plugins)
├── index.html                        # Interactive marketplace website
├── README.md / README_zh.md          # English / Chinese documentation
├── USAGE_zh.md                       # End-to-end usage guide
├── LICENSE
└── plugins/
    ├── flowsmith/                    # SOP workflow engine + test-first discipline
    │   ├── commands/                 # 10 slash commands (incl. sop-brainstorm, sop-test, skill-scaffold)
    │   ├── agents/                   # 4 independent-context subagents
    │   ├── skills/                   # 7 skills (planning, arch, tdd, debugging, brainstorming, writing-skills, impl) + _shared templates
    │   └── hooks/                    # State validation + test green-light gate
    ├── spec-keeper/                  # Spec-driven development (SDD)
    │   ├── commands/                 # 7 slash commands (propose/bootstrap/sync/apply/archive/check/status)
    │   ├── skills/                   # spec-authoring skill
    │   └── schemas/                  # spec & delta format contract
    ├── code-archaeologist/           # Legacy code archaeology
    ├── co-review/                    # Team collaboration review
    ├── formatter/                    # Code style guardian
    └── context-keeper/               # Event-sourced knowledge graph (foundation)
        ├── commands/  skills/  hooks/  schemas/  scripts/
```

---

## Roadmap

| Status | Plugin | Description | Connects To |
|--------|--------|-------------|-------------|
| 🟡 Backlog | **atlas** | Code wiki & system-linkage spec. Single-project navigable wiki + cross-project call-chain graph by joining published/consumed interface contracts. Feeds drift detection by comparing actual structure ("is") against spec ("should"). | spec-keeper, context-keeper |
| 🟢 Development | **release-captain** | Standardized release orchestration with multi-language Changelog sync, semantic versioning, and release gates. Bridges flowsmith's DONE phase to "shipped". | flowsmith, co-review |
| 🔵 Research | **Project Insight UI** | Web-based interactive dashboard evolved from co-review's TUI. Real-time code evolution curves, team health heatmaps, and refactoring risk radar. | co-review, code-archaeologist, flowsmith |

---

## Vision

We believe AI-assisted coding should not mean "write more bugs faster." It should mean **"build truly reliable software with engineering discipline."**

1. **Spec as Source of Truth** — Align on *what* the system does before changing it. A living, capability-organized spec stays in sync with code and keeps every change diff-able and reviewable.
2. **Process as Guardrails** — State machines enforce "think before code, test before ship." Every phase has explicit contracts; the test gate is hard. No skipping.
3. **Discipline over Rationalization** — Each rigid skill carries an Iron Law and a red-flags list of the exact excuses an agent uses to skip the rule — stopping it from talking itself out of doing the right thing.
4. **Knowledge Compounds** — An event-sourced knowledge graph plus `lessons.md` mean every completion, review finding, and archaeological conclusion flows back — so the next task stands on the shoulders of history.
5. **Multi-Agent Isolation** — Each analysis dimension runs in independent context. Security review isn't distracted by optimization; team analysis isn't contaminated by bias.
6. **Privacy First** — Team collaboration analysis strictly isolates per-person data. No horizontal comparison, no attitude judgment.
7. **Archaeology Before Action** — Understand before refactoring: why was it written this way? Who depends on it? Which complexity is necessary?
8. **Full Development Lifecycle** — From idea to production: Spec → Clarify → Plan → Design → Test → Code → Format → Archaeology → Review → Team Collaboration → Release.

---

## Author

**Velpro**
Email: [xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)
GitHub: [@KaverinX](https://github.com/KaverinX)

---

## License

MIT © Velpro
