---
name: syncing-with-upstream
description: Use when updating this spacemacs fork from upstream — fast-forwarding local develop from syl20bnr/develop and rebasing the working branch onto it, including resolving conflicts where a local prototype fix was superseded by an upstream commit.
---

# Syncing develop From Upstream and Rebasing working

## Overview

`develop` is a pure mirror of `syl20bnr/develop` (never commit to it); `working`
carries local prototype fixes rebased on top. Sync = fast-forward the mirror,
then rebase `working`. Conflicts usually mean upstream merged its own version of
a fix we already carry — the resolution is normally to **drop the local commit**,
not to merge the two.

## Workflow

1. **Preconditions:** no staged or unstaged changes in `git status` (untracked
   files are fine and don't block anything). Record the pre-rebase SHAs for
   later verification — print them and note the literal values, since shell
   variables don't survive across separate tool invocations:
   ```sh
   git rev-parse develop working   # note both SHAs: old_develop, old_working
   ```
   Other local branches (`pr-*-review`, worktree branches) are out of scope.
2. **Fast-forward develop without leaving working:**
   ```sh
   git fetch syl20bnr develop:develop
   ```
   This refuses non-fast-forward updates — exactly what we want for a mirror.
   If it fails, local `develop` has stray commits; stop and investigate rather
   than forcing.
3. **Identify superseded commits up front.** Local fix commits cite issues with
   `Upstream: syl20bnr/spacemacs#NNNNN` prose lines (see the
   `triaging-upstream-issues` skill). Extract the refs and check each cited
   issue's state:
   ```sh
   git log develop..working --format='%h %s%n%b' | rg '^[0-9a-f]{7,}|Upstream: \S*#\d+'
   gh issue view NNNNN -R syl20bnr/spacemacs --json state,closedAt
   ```
   For each **closed** issue, find the closing commit
   (`gh api repos/syl20bnr/spacemacs/issues/NNNNN/timeline --jq '.[] | select(.event=="closed") | .commit_id'`)
   and diff it against the local commit. An identical patch will be
   auto-skipped by the rebase ("skipped previously applied commit"); a
   different-but-equivalent upstream fix will conflict — plan to drop ours in
   step 5.
4. **Rebase:** `git rebase develop working` (works from any branch — it checks
   out `working` itself).
5. **Per conflict**, decide superseded vs. genuine:
   - Check what upstream did to the conflicted file since the old base:
     `git log --oneline <old_develop>..develop -- <file>`
   - **Superseded** (upstream merged an equivalent fix, possibly from our own
     PR): verify the upstream version covers the local intent, then drop the
     whole commit with `git rebase --skip` if the *entire* commit is covered.
     If only some hunks are covered, keep upstream's side for those. NB the
     side-swap during rebase: `--ours` is upstream (the branch being rebased
     onto), `--theirs` is the local commit being replayed — so "keep
     upstream's version" is `git checkout --ours <file>`.
   - **Genuine conflict** (upstream moved code our fix touches): re-apply the
     local intent onto the new upstream shape, keeping the diff minimal per
     fork discipline.
6. **Verify the rebase preserved intent:**
   ```sh
   git range-diff <old_develop>..<old_working> develop..working
   ```
   Every local commit should appear `=` or with explainable changes; commits
   intentionally dropped in step 4 show as removed — confirm each was meant.
7. **Smoke test:** `make -C tests/core test`. Two func tests
   (`test-git-fetch-tags`, `test-git-has-remote`) fail in any clone lacking an
   `origin` remote — environmental, not a regression. For interactive
   behavior, the `spacemacs-daemon-testing` skill covers live verification.
8. **Push:** `git push --force-with-lease jlipworth working`
   (`develop` needs no push — it just mirrors upstream).

## Common mistakes

- **Checking out develop to merge** — `git fetch syl20bnr develop:develop`
  fast-forwards in place; no branch switching, no risk of stray commits.
- **Merging both versions of a duplicated fix** — when upstream supersedes a
  local commit, drop ours (`git rebase --skip`); carrying both diverges the
  fork for nothing.
- **Skipping range-diff** — a "clean" rebase can still silently mangle a
  commit; range-diff is the only cheap way to see what actually changed.
- **`git push -f`** — always `--force-with-lease`, and only to the
  `jlipworth` fork, never to `syl20bnr`.
- **Ignoring stale worktrees** — `.claude/worktrees/*` hold old branches
  pinned to pre-rebase commits; they don't block the rebase, but prune them
  (`git worktree prune` after deleting dirs) if branch cleanup errors mention
  them.
