---
name: triaging-upstream-issues
description: Use when checking spacemacs upstream (syl20bnr/spacemacs) GitHub issues against prototype fixes on the local working branch — e.g. "are any upstream issues already fixed here", "which of my fixes should I upstream", or periodic issue-triage sweeps.
---

# Triaging Upstream Issues Against Local Fixes

## Overview

This fork carries prototype fixes on `working` ahead of `develop` (a mirror of
upstream `syl20bnr/develop`). The goal: match open upstream issues to local fix
commits — finding issues already fixed here (PR candidates) and issues we could
fix next.

**Key convention:** fix commits on `working` cite the issue they address with an
`Upstream: syl20bnr/spacemacs#NNNNN` line in the commit body (prose, NOT a git
trailer — `%(trailers)` won't find it). Grep these refs before any fuzzy
matching.

## Repo facts (verify, don't rediscover)

| Fact | Value |
|---|---|
| Upstream remote | `syl20bnr` → https://github.com/syl20bnr/spacemacs |
| Fork remote | `jlipworth` → git@github.com:jlipworth/spacemacs.git |
| Mirror branch | local `develop` tracks `syl20bnr/develop` |
| Fix branch | `working` (tracks `jlipworth/working`) |
| Open issue volume | ~50 total — one `gh issue list --limit 100` page covers everything |

## Workflow

1. **Sync upstream refs:** `git fetch syl20bnr develop`
2. **Enumerate local fixes:** `git log --oneline develop..working` —
   `[layer]`-prefixed commits are the fixes; skip everything else
   (`docs:`, `chore:`, `gitignore:`, …).
3. **Extract existing issue refs:**
   ```sh
   git log develop..working --format='%h %s%n%b' | rg '^[0-9a-f]{7,}|Upstream: \S*#\d+'
   ```
4. **Pull all open issues:**
   ```sh
   gh issue list -R syl20bnr/spacemacs --state open --limit 100 \
     --json number,title,createdAt
   ```
   Confirm the list is complete: `--limit 300 --json number --jq 'length'`.
5. **Match three ways:**
   - **Cited:** issue numbers from step 3 that are still open → already fixed
     locally, prime PR candidates. Cited-but-closed refs go in a separate
     "already resolved upstream" bucket — flag them as commits that may now be
     droppable on the next rebase (see the `syncing-with-upstream` skill).
   - **Title match:** remaining open issues whose titles name a layer/package
     that an *uncited* local commit touches (e.g. git/magit, pdf,
     spacemacs-visual).
   - **Keyword search** for uncited local fixes:
     `gh search issues --repo syl20bnr/spacemacs --state open "in:title <keywords>"`
     — without `in:title` this is full-text search and returns mostly noise.
6. **Verify each match by reading the issue body**
   (`gh issue view NNNNN -R syl20bnr/spacemacs --json title,body`) against the
   local commit message/diff — title similarity alone is not a match.
7. **Report:** table of issue ↔ commit pairs (already fixed), then a short list
   of open issues plausibly fixable next, scoped per fork discipline in
   CLAUDE.md (smallest upstreamable change only).

## Common mistakes

- **Skipping the `Upstream:` ref grep** and fuzzy-matching from scratch — the
  refs are already recorded; use them first.
- **Trusting title matches** without reading the issue body and the commit diff.
- **Paginating needlessly** — ~50 open issues; one page suffices (but verify the
  count, it may grow).
- **Proposing fixes outside fork discipline** — a matched issue is only worth
  fixing if the change is small and upstreamable (see CLAUDE.md).
