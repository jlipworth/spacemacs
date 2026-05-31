# Spacemacs Layer Audit — Design

**Date:** 2026-05-31
**Goal:** Systematically assess every Spacemacs layer the user enables, identify where each is underbuilt / stale / broken / improvable, and produce a tracked, actionable hitlist plus per-layer deep-dives. Reusable so it can be re-run as the fork evolves.

## Scope

- **Audited:** the 39 enabled layers that live in this fork (from `~/.spacemacs`).
- **Out of scope (noted only):** `claude-code`, `whisper` — enabled but external packages with thin wrapper layers; no upstream source in-repo to audit.
- **Plus:** a "suggested new layers" scout — high-value layers the user does *not* enable yet, given their stack.

## Benchmarks (what "underbuilt" means)

Each layer is judged against three references:
1. **Upstream** — diff against `syl20bnr/develop` (present locally) to catch staleness, local divergence, and lost upstream improvements.
2. **Modern ecosystem** — best-in-class today for that language/tool (newer packages, tree-sitter, LSP/DAP coverage, formatters, REPL/debug, test runners), via web research.
3. **The user's actual config** — gaps relative to the `:variables` they set in `~/.spacemacs`, things commented out, or unfinished intent.

`python` (1386 LOC, with tests) is the in-repo gold standard for "mature." LOC is a hint, not a verdict — maturity is judged by **capability coverage**, not line count.

## Workflow (`.claude/workflows/layer-audit.js`)

Pipeline, one item per layer:

| Phase | Agents | Role |
|---|---|---|
| 1. Audit | 1 / layer | Read layer `.el`+README, user's `:variables`, diff vs upstream, web-research ecosystem, compare to python. Emit structured findings with **mandatory evidence** (file:line / diff / source). |
| 2. Verify | 1 / layer (pipelined) | Skeptic re-checks each finding against real code; marks `confirmed`/`rejected`/`adjusted`; adds missed gaps. |
| 3. Scout | ~3 | Propose valuable unused layers given the user's stack. (Full run only.) |

**Args:** array of layer names (subset, e.g. pilot) or `{layers, scout}`; default = all enabled, scout on.

**Guardrails:** agents only read and return structured data — no file writes, no issue creation, no config edits inside the workflow.

### Finding shape
`{title, kind (gap|bug|modernization|enhancement|cleanup), severity (high|medium|low), effort (S|M|L), evidence[], detail (handoff-ready), deliverable (issue|md|both), status (from verify)}`

## Deliverables (synthesized after the run, approved before anything outward-facing)

- `docs/layer-audit/INDEX.md` — master hitlist: every layer ranked by maturity, finding counts, top gap, links; plus "Suggested new layers".
- `docs/layer-audit/<layer>.md` — deep-dive (ocaml `ROADMAP.md` style) for each layer with real findings; mature/clean layers get only an INDEX row.
- **GH issues** — drafted from `deliverable: issue|both` findings, created only after user approves the list. Convention: `[<layer>] title` + existing labels + a `layer-audit` grouping label.

## Execution plan

1. **Pilot** 4 layers — `python` (calibration), `ocaml`/`terraform`/`react` (suspected thin) — on Opus.
2. **Checkpoint** — review output format/quality; decide Opus vs Sonnet for the bulk.
3. **Fan out** remaining 35 + scout.
4. **Synthesize** INDEX + deep-dives.
5. **Draft issues**, approve, create.

## Cost

~82 agents total (39 audit + 39 verify + ~3 scout + pilot). Pilot-then-fan-out bounds risk; bulk can drop to Sonnet at the checkpoint.
