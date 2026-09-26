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
| Fork remote (push here) | `origin` → `https://github.com/jlipworth/spacemacs` |
| Mirror branch | local `develop` tracks `syl20bnr/develop` |
| Fix branch | `working` |
| Commit author | `Jonathan Lipworth <jonathan.lipworth@gmail.com>`, set in this repo's **local** git config (global `~/.gitconfig` has a different address). Check `git log -1 --format='%an <%ae>'` before pushing |
| Subject style | `[layer] Imperative summary`, ≤72 chars (matches upstream, e.g. `[python] Fix …`) |

## No AI attribution on upstream PRs

**User decision (2026-09-26): upstream commits and PRs carry no Claude
attribution.** Strip any `Co-authored-by: Claude …` trailer when reshaping the
commit message, and leave the "Generated with Claude Code" footer out of the PR
body. This overrides harness attribution defaults and the fact that upstream has
merged Claude-coauthored commits before (`e70ef0aa4`, #17246).

## Workflow

1. **Branch fresh from upstream develop in a separate worktree** (never from
   `working`, never from `master`), so only this fix rides along. Never switch
   branches in `~/.emacs.d` itself — it is the live Emacs checkout:
   ```sh
   git fetch syl20bnr develop
   git worktree add -b upstream-pr-<topic> /tmp/upstream-pr-<topic> syl20bnr/develop
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
   - **drop** any `Co-authored-by: Claude …` trailer (see policy above).
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
   Follow `AGENTS.md` for all test isolation. Any batch test that loads
   Spacemacs must set a disposable `user-emacs-directory` before loading it;
   `-Q`, `--batch`, and `SPACEMACSDIR` alone do not isolate package storage.
   Use the isolated core-test helper in the `syncing-with-upstream` skill.
   For behavior needing interactive verification, use a separate GUI instance
   from a unique worktree, never the user's primary Emacs. Byte compilation
   alone does not verify keybindings, mode hooks, or keymaps.
6. **Push to the fork** (never to `syl20bnr`):
   ```sh
   git push -u origin upstream-pr-<topic>
   ```
7. **Open the PR against upstream develop:**
   ```sh
   gh pr create --repo syl20bnr/spacemacs --base develop \
     --head jlipworth:upstream-pr-<topic> \
     --title "[layer] Imperative summary" --body "<description>"
   ```
   Body: `Fixes #NNNNN`, then short Cause / Fix / Testing sections — keep it
   concise (a few lines each; a small table beats paragraphs). Then leave a
   one- or two-line comment on the issue linking the PR.
8. **Verify the opened PR:**
   ```sh
   gh pr view <N> -R syl20bnr/spacemacs \
     --json baseRefName,headRefName,mergeable,files,additions,deletions
   ```
   Confirm base `develop`, head `jlipworth:…`, `MERGEABLE`, only intended files.

## Common mistakes

- **Leaving Claude attribution in** (commit trailer or PR footer) — see the
  policy section; the user does not want it upstream.
- **Branching from `working` (then rebasing).** Drags unrelated fork commits;
  branch fresh from `syl20bnr/develop` and cherry-pick the one fix.
- **Skipping the `CHANGELOG.develop` entry** on a code change — `CONTRIBUTING.org`
  and the PR template both ask for it.
- **Opening the PR against `master`** — `master` is read-only; base is `develop`.
- **Claiming the fix works without verifying** — byte-compile, and verify behavior
  with appropriately isolated tests before opening (see `AGENTS.md`).
- **Pushing to `syl20bnr`** — only ever push to the `origin` fork (jlipworth/spacemacs).
- **More than one commit / one topic per PR** — squash to a single commit.
