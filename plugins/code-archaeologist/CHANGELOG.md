# Changelog — code-archaeologist

All notable changes to the `code-archaeologist` plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this plugin adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-04-26

### Added
- Initial release.
- **Three independent archaeologist subagents**:
  - `history-archaeologist` — git timeline excavation, hot-spots & sleeping zones detection
  - `dependency-archaeologist` — blast radius analysis with deep focus on implicit dependencies (reflection, serialization, config refs, string construction)
  - `intent-archaeologist` — design intent reverse engineering with mandatory three-hypothesis analysis
- **`refactor-strategy` skill** — synthesizes three reports into final recommendation using the decision matrix.
- **6 commands**: `/arch-init`, `/arch-status`, `/arch-resume`, `/arch-report`, `/arch-handoff`, `/arch-close`.
- **flowsmith integration**:
  - `PostToolUse` hook auto-detects refactor keywords in flowsmith plan.md and suggests archaeology
  - `/arch-handoff` auto-injects archaeology conclusions into `.sop/plan.md` "Constraints" section
  - `/arch-close` writes archaeology lessons into shared `.sop/lessons.md` knowledge base
- **Decision matrix**: 4-dimension risk scoring (blast radius, knowledge loss, intent clarity, change frequency) plus 5 override rules for special cases.
- **5 recommendation strategies**: `safe-refactor`, `staged-refactor`, `parallel-rewrite`, `freeze-and-document`, `escalate`.
- `BUDDY_ARCH_AUTO_SUGGEST` environment switch for hook auto-suggestion.
- Full schema contracts for `state.json` and all four report formats (`history.md`, `blast-radius.md`, `intent.md`, `report.md`).

### Design notes
- Three agents intentionally use independent contexts to avoid cross-pollination of analytical biases.
- `intent-archaeologist` is the only one allowed to read `history.md` as input — providing temporal context to intent inference.
- Knowledge sharing with `flowsmith` happens through persistent `.sop/lessons.md`, not transient API calls — this is the cleanest cross-plugin coordination model.
