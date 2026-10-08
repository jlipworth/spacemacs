#!/usr/bin/env bash
# Rebase each fork's pin branch (see forks.json) onto its upstream.
#
# For every fork:
#   - check that each listed file still pins it with a 40-hex `:commit`
#     (the Renovate regex manager depends on that shape)
#   - tag every SHA currently pinned as pin/<sha12>, so the pin stays
#     fetchable after the branch is rewritten (package-build clones and
#     then resets to the SHA)
#   - rebase the pin branch onto upstream and push with a lease
#   - on conflict, or when every patch has landed upstream, open (or
#     comment on) an issue instead of pushing
#
# Usage: .forks/sync.sh [MANIFEST]   (run from the repository root)
#
# Environment:
#   DRY_RUN=1        report what would happen; push nothing, open nothing
#   GIT_BASE         clone base URL (default https://github.com)
#   ISSUE_REPO       repo for issues (default $CI_REPO, else jlipworth/spacemacs)
#   ISSUE_LOG        if set, append issues to this file instead of using gh
#   GH_TOKEN         token for gh (issues); git auth is configured by the caller
set -euo pipefail

manifest=${1:-.forks/forks.json}
root=$(pwd)
git_base=${GIT_BASE:-https://github.com}
issue_repo=${ISSUE_REPO:-${CI_REPO:-jlipworth/spacemacs}}
dry_run=${DRY_RUN:-0}
pin_branch=$(jq -r '.pinBranch' "$manifest")
status=0

log() { printf '%s\n' "$*"; }

# open_issue TITLE BODY: one open issue per title, later runs comment on it.
open_issue() {
  local title=$1 body=$2
  if [ "$dry_run" = 1 ]; then
    log "DRY_RUN: would open issue: $title"
    return
  fi
  if [ -n "${ISSUE_LOG:-}" ]; then
    printf '%s\n%s\n---\n' "$title" "$body" >>"$ISSUE_LOG"
    return
  fi
  local existing
  existing=$(gh issue list -R "$issue_repo" --state open --label fork-sync \
                --search "in:title \"$title\"" --json number,title \
                --jq ".[] | select(.title == \"$title\") | .number" | head -n1)
  if [ -n "$existing" ]; then
    gh issue comment "$existing" -R "$issue_repo" --body "$body" >/dev/null
    log "commented on #$existing: $title"
  else
    gh label create fork-sync -R "$issue_repo" --color BFD4F2 \
       --description "Fork pin automation" >/dev/null 2>&1 || true
    gh issue create -R "$issue_repo" --label fork-sync \
       --title "$title" --body "$body" >/dev/null
    log "opened issue: $title"
  fi
}

# pinned_shas FORK FILE...: the :commit SHAs pinned for FORK, one per line.
pinned_shas() {
  local fork=$1; shift
  local f
  for f in "$@"; do
    tr '\n' ' ' <"$root/$f" |
      grep -oE ":repo \"$fork\"[[:space:]]+:commit \"[0-9a-f]{40}\"" |
      grep -oE '[0-9a-f]{40}' || true
  done | sort -u
}

sync_fork() {
  local fork=$1 upstream=$2 upstream_branch=$3; shift 3
  local files=("$@") f shas sha old new left dir conflicts
  log "== $fork (onto $upstream@$upstream_branch)"

  for f in "${files[@]}"; do
    if [ -z "$(pinned_shas "$fork" "$f")" ]; then
      log "ERROR: $f has no ':repo \"$fork\" :commit \"<40-hex>\"' pin"
      return 1
    fi
  done
  shas=$(pinned_shas "$fork" "${files[@]}")

  dir=$(mktemp -d)
  git clone --quiet --branch "$pin_branch" "$git_base/$fork.git" "$dir"
  cd "$dir"
  git remote add upstream "$git_base/$upstream.git"
  git fetch --quiet upstream "$upstream_branch"
  old=$(git rev-parse HEAD)

  for sha in $shas; do
    if ! git cat-file -e "$sha^{commit}" 2>/dev/null; then
      log "WARN: pinned $sha is not fetchable from $fork; cannot tag it"
    elif ! git rev-parse -q --verify "refs/tags/pin/${sha:0:12}" >/dev/null; then
      git tag "pin/${sha:0:12}" "$sha"
      if [ "$dry_run" = 1 ]; then
        log "DRY_RUN: would push tag pin/${sha:0:12}"
      else
        git push --quiet origin "refs/tags/pin/${sha:0:12}"
        log "tagged pin/${sha:0:12}"
      fi
    fi
  done

  if git merge-base --is-ancestor "upstream/$upstream_branch" HEAD; then
    log "up to date ($(git rev-list --count "upstream/$upstream_branch..HEAD") patch(es) on top)"
    cd "$root"; rm -rf "$dir"; return 0
  fi

  if ! git -c user.name="fork-sync" -c user.email="fork-sync@users.noreply.github.com" \
         rebase --quiet "upstream/$upstream_branch" >/dev/null 2>&1; then
    conflicts=$(git diff --name-only --diff-filter=U | sed 's/^/- /')
    git rebase --abort
    log "CONFLICT rebasing $fork"
    open_issue "fork-sync: $fork needs a manual rebase" \
"Rebasing \`$fork@$pin_branch\` ($old) onto \`$upstream@$upstream_branch\` ($(git rev-parse --short "upstream/$upstream_branch")) conflicts in:

$conflicts

Resolve by hand following the *Fork pins* section of the syncing-with-upstream skill."
    cd "$root"; rm -rf "$dir"; return 1
  fi

  new=$(git rev-parse HEAD)
  left=$(git rev-list --count "upstream/$upstream_branch..HEAD")
  if [ "$left" = 0 ]; then
    log "all patches are upstream; not pushing"
    open_issue "fork-sync: $fork patches landed upstream, unpin it" \
"Every commit on \`$fork@$pin_branch\` is now in \`$upstream@$upstream_branch\`.

Retire the pin following the *Fork pins* section of the syncing-with-upstream skill: return the package to its normal recipe in ${files[*]} and remove the entry from \`.forks/forks.json\`."
    cd "$root"; rm -rf "$dir"; return 0
  fi

  if [ "$dry_run" = 1 ]; then
    log "DRY_RUN: would push $pin_branch ${old:0:12} -> ${new:0:12} ($left patch(es))"
  else
    git -c user.name="fork-sync" -c user.email="fork-sync@users.noreply.github.com" \
        push --quiet --force-with-lease="refs/heads/$pin_branch:$old" \
        origin "HEAD:refs/heads/$pin_branch"
    log "pushed $pin_branch ${old:0:12} -> ${new:0:12} ($left patch(es))"
  fi
  cd "$root"; rm -rf "$dir"
}

count=$(jq '.forks | length' "$manifest")
for i in $(seq 0 $((count - 1))); do
  fork=$(jq -r ".forks[$i].fork" "$manifest")
  upstream=$(jq -r ".forks[$i].upstream" "$manifest")
  upstream_branch=$(jq -r ".forks[$i].upstreamBranch" "$manifest")
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(jq -r ".forks[$i].files[]" "$manifest")
  if ! (sync_fork "$fork" "$upstream" "$upstream_branch" "${files[@]}"); then
    status=1
  fi
done
exit "$status"
