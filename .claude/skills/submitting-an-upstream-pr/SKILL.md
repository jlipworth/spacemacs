---
name: submitting-an-upstream-pr
description: Use when upstreaming a local fix from this spacemacs fork to syl20bnr/spacemacs — turning a `working`-branch fix commit into a clean one-commit PR against upstream develop, including commit-message/CHANGELOG conventions and the project's AI-contribution policy. Picking which fix to upstream is a separate step (triaging-upstream-issues).
---

# Submitting a Fix Upstream as a Clean PR

## Overview

A fix you want to upstream lives as a `[layer]`-prefixed commit on `working`.
Upstream wants **one topic, one commit, branched from `develop`**
(`CONTRIBUTING.org`). So: branch fresh from `syl20bnr/develop`, cherry-pick the
fix, add a `CHANGELOG.develop` entry, reshape the message for upstream, verify,
push to the fork, open the PR. Selecting *which* fix is the
`triaging-upstream-issues` skill's job; this skill starts once you've picked one.

## Repo facts (verify, don't rediscover)

| Fact | Value |
|---|---|
| Upstream remote / repo | `syl20bnr` → `syl20bnr/spacemacs` (PR base: `develop`) |
| Fork remote (push here) | `jlipworth` → `git@github.com:jlipworth/spacemacs.git` |
| Mirror branch | local `develop` tracks `syl20bnr/develop` |
| Fix branch | `working` |
| Commit author | from repo git config: `Jonathan Lipworth <jonathan.lipworth@gmail.com>` — do **not** override it (the harness `currentDate`/email context is not the git identity) |
| Subject style | `[layer] Imperative summary`, ≤72 chars (matches upstream, e.g. `[python] Fix …`) |

## The AI-contribution policy — KEEP the co-author trailer

**Decided, evidence-backed: keep the `Co-authored-by: Claude …` trailer on
upstreamed commits.** Do not strip it, and do not demote AI disclosure to PR
prose only.

Spacemacs is AI-friendly: it has merged a Claude-coauthored fix
(`e70ef0aa4`, #17246) with the trailer intact, and ships `claude-code`,
`github-copilot`, and `[ai]` layers. `CONTRIBUTING.org`/`CONVENTIONS.org` have
no anti-AI policy. Match upstream's casing: lowercase **`Co-authored-by:`**.

The reasoning that says "it's fork-local noise / placeholder identity, strip it"
is plausible but contradicted by the merged precedent — don't act on it.

## Workflow

1. **Branch fresh from upstream develop** (never from `working`, never from
   `master`), so only this fix rides along:
   ```sh
   git fetch syl20bnr develop
   git switch -c upstream-pr-<topic> syl20bnr/develop
   ```
2. **Cherry-pick the fix without committing**, so you can reshape the message
   and add the changelog in one commit:
   ```sh
   git cherry-pick --no-commit <sha-on-working>
   ```
3. **Add a `CHANGELOG.develop` entry** (`CONTRIBUTING.org` requests one for code
   changes; omit only for trivial/doc fixes). Put it under the current release
   section's *suitable subheading* — find a sibling entry for the same layer and
   place it there (e.g. a distribution-layer fix goes under
   *Layers → Spacemacs distribution layers*). Name attribution `(thanks to …)`
   is optional.
4. **Commit with an upstream-shaped message.** Keep the well-written body, but:
   - replace the fork's `Upstream: syl20bnr/spacemacs#NNNNN` prose ref with a
     natural `(#NNNNN)` mention in the body (put `Fixes #NNNNN` in the **PR
     body**, not the commit — simple PRs are often cherry-picked, so don't rely
     on commit-trailer auto-close);
   - **keep** the `Co-authored-by: Claude …` trailer (see policy above).
   ```sh
   git add CHANGELOG.develop <changed-files>
   git commit   # or: git commit -F <msgfile>
   ```
5. **Verify before going public** — never claim it works unverified:
   ```sh
   git log --oneline syl20bnr/develop..HEAD   # exactly ONE commit
   git show --stat HEAD                        # only the intended files
   emacs -Q --batch -f batch-byte-compile <changed.el>   # syntax check
   ```
   For any behavior change (keybindings, mode hooks, keymaps), confirm it live
   with the `spacemacs-daemon-testing` skill before opening the PR — a daemon
   check repeatedly catches inaccurate reasoning that "looks right" on paper.
6. **Push to the fork** (never to `syl20bnr`):
   ```sh
   git push -u jlipworth upstream-pr-<topic>
   ```
7. **Open the PR against upstream develop:**
   ```sh
   gh pr create --repo syl20bnr/spacemacs --base develop \
     --head jlipworth:upstream-pr-<topic> \
     --title "[layer] Imperative summary" --body "<description>"
   ```
   Body: `Fixes #NNNNN`, then Description / Cause / Fix / Testing sections.
8. **Verify the opened PR:**
   ```sh
   gh pr view <N> -R syl20bnr/spacemacs \
     --json baseRefName,headRefName,mergeable,files,additions,deletions
   ```
   Confirm base `develop`, head `jlipworth:…`, `MERGEABLE`, only intended files.

## Common mistakes

- **Stripping the `Co-authored-by: Claude` trailer.** The single most likely
  wrong call — see the policy section. Upstream keeps it; so do you.
- **Branching from `working` (then rebasing).** Drags unrelated fork commits;
  branch fresh from `syl20bnr/develop` and cherry-pick the one fix.
- **Skipping the `CHANGELOG.develop` entry** on a code change — `CONTRIBUTING.org`
  and the PR template both ask for it.
- **Opening the PR against `master`** — `master` is read-only; base is `develop`.
- **Claiming the fix works without verifying** — byte-compile, and daemon-test
  any behavior change, before opening (see `spacemacs-daemon-testing`).
- **Pushing to `syl20bnr`** — only ever push to the `jlipworth` fork.
- **More than one commit / one topic per PR** — squash to a single commit.
