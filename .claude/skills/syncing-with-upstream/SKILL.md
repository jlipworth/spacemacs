---
name: syncing-with-upstream
description: Use when updating this spacemacs fork from upstream — fast-forwarding local develop from syl20bnr/develop and rebasing the working branch onto it, including resolving conflicts where a local prototype fix was superseded by an upstream commit. Also covers the jlipworth fork pins (spacemacs-pin branches, fork-sync/Renovate CI, conflict issues, retiring a pin).
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
7. **Smoke test in an isolated runtime:** from the repository root run
   ```sh
   sh .claude/skills/syncing-with-upstream/scripts/isolated-core-tests.sh
   ```
   Never run bare `make -C tests/core test` (or its installation/unit/func
   targets) against the live Emacs directory. `SPACEMACSDIR` selects the
   dotfile, not package/cache storage; `-Q --batch` does not isolate storage.
   The minimal test configuration can delete live packages as orphans.
   The helper sets `user-emacs-directory` before loading Spacemacs and redirects
   native compilation cache to a unique temporary runtime. It retains that
   directory for inspection; remove only that printed directory when finished.
   Optionally set `SPACEMACS_TEST_ELPA_SEED` to an existing ELPA root to copy
   dependencies (never symlink or hardlink live runtime state into tests).
   Inspect actual failures: remote tests need `origin`, and fetch-tags also
   expects `origin/master`; missing prerequisites are not code regressions.
   On macOS, GNU tar must be installed (`brew install gnu-tar`, per README):
   with only BSD tar, quelpa's tarballs fail to parse (`Error getting
   PACKAGE-DESC: (wrong-type-argument arrayp nil)`), and startup then dies
   with `void-variable evil-evilified-state-map`.
   For GUI verification follow the isolated-instance rules in `AGENTS.md`.
8. **Push:** `git push --force-with-lease origin working`
   (`develop` needs no push — it just mirrors upstream).
9. **Check fork pins:** look for open `fork-sync` issues and an open
   `renovate/fork-pins` PR on jlipworth/spacemacs and handle them (see
   *Fork pins* below). Renovate rebases its own PR after `working` moves.

## Fork pins

Some layers pin packages to jlipworth forks carrying unmerged fixes
(`:repo "jlipworth/X" :commit "<sha>"` in `layers/**/packages.el`). Forks get
behind their upstreams too, so they are synced by CI:

- `.forks/forks.json` lists each fork, its upstream repo/branch, and the
  layer files that pin it.
- Each fork has a **`spacemacs-pin`** branch: upstream plus our patches. CI
  touches only this branch and `pin/<sha12>` tags; PR branches and the fork's
  `master` are left alone.
- **`fork-sync` cron** (`.woodpecker/fork-sync.yml` → `.forks/sync.sh`) tags
  every currently pinned SHA `pin/<sha12>` (package-build clones and then
  resets to the SHA, so a pin must stay reachable after the branch is
  rewritten), rebases `spacemacs-pin` onto upstream and pushes with a lease.
  A conflict opens a `fork-sync` issue instead; so does a rebase that leaves
  no commits (every patch landed upstream). It also fails if a listed file
  no longer has the pin shape, which would silently blind Renovate.
- **`renovate` cron**, an hour later (`.woodpecker/renovate.yml`, config in
  `.forks/renovate.json` because the default branch is the upstream mirror),
  opens one grouped `renovate/fork-pins` PR against `working`. Merge it by
  hand after checking the fork's `git range-diff`.
- **A merged pin bump is not installed by restarting Emacs**: Spacemacs only
  installs *missing* packages, and checks recipe `:commit` changes only in an
  explicit update (`SPC f e U`). Run that, or with Emacs quit move the bumped
  package directories out of `elpa/<ver>/develop/` (keep them as
  `elpa-backup-<pkg>-<date>`) so the next start reinstalls them at the pin.
- Test the sync script locally with `bash .forks/test-sync.sh` (throwaway
  repos only) or `DRY_RUN=1 bash .forks/sync.sh` (real forks, pushes
  nothing).
- Pushing `spacemacs-pin` runs the fork's own GitHub Actions; that is
  expected noise.

**Resolving a "needs a manual rebase" issue:**
```sh
git clone -b spacemacs-pin https://github.com/jlipworth/X && cd X
git remote add upstream https://github.com/OWNER/X && git fetch upstream
old=$(git rev-parse HEAD)
git rebase upstream/master        # resolve, keeping the patch's intent
git range-diff upstream/master...$old upstream/master...HEAD
git push --force-with-lease=spacemacs-pin:$old origin HEAD:spacemacs-pin
```
Then close the issue; the next `renovate` run proposes the pin (or trigger
the cron by hand). Leave the `pin/*` tag alone — the old pin needs it until
the Renovate PR merges.

**Retiring a pin** ("patches landed upstream" issue): restore the package's
normal entry in each listed layer file (match `syl20bnr/develop`), remove its
entry from `.forks/forks.json`, commit both together on `working`, and close
the issue. Keep the fork and its tags; old checkouts may still reference them.

**Adding a fork:** create `spacemacs-pin` on the fork at the commit to pin
and tag it `pin/<sha12>`; pin the layer with the full 40-hex SHA in the
`:repo … :commit …` order Renovate matches; add a `forks.json` entry; run
`DRY_RUN=1 bash .forks/sync.sh`.

## Common mistakes

- **Checking out develop to merge** — `git fetch syl20bnr develop:develop`
  fast-forwards in place; no branch switching, no risk of stray commits.
- **Merging both versions of a duplicated fix** — when upstream supersedes a
  local commit, drop ours (`git rebase --skip`); carrying both diverges the
  fork for nothing.
- **Skipping range-diff** — a "clean" rebase can still silently mangle a
  commit; range-diff is the only cheap way to see what actually changed.
- **`git push -f`** — always `--force-with-lease`, and only to the
  `origin` fork (jlipworth/spacemacs), never to `syl20bnr`.
- **Ignoring stale worktrees** — `.claude/worktrees/*` hold old branches
  pinned to pre-rebase commits; they don't block the rebase, but prune them
  (`git worktree prune` after deleting dirs) if branch cleanup errors mention
  them.
