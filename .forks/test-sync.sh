#!/usr/bin/env bash
# Exercise .forks/sync.sh against throwaway local repositories.
# Usage: .forks/test-sync.sh   (needs git and jq; touches nothing remote)
set -euo pipefail

sync=$(cd "$(dirname "$0")" && pwd)/sync.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export GIT_BASE="file://$tmp" ISSUE_LOG="$tmp/issues.log"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
fail=0

check() {
  if eval "$2"; then echo "ok   - $1"; else echo "FAIL - $1"; fail=1; fi
}

# make_fork NAME: upstream up/NAME (master) and fork me/NAME whose
# spacemacs-pin branch carries one patch.  Prints the patch SHA.
make_fork() {
  local name=$1 w="$tmp/work-$1"
  git init -q -b master "$w"
  printf 'a\nb\nc\n' >"$w/f.el"
  git -C "$w" add f.el && git -C "$w" commit -qm base
  git init -q --bare "$tmp/up/$name.git"
  git -C "$w" push -q "$tmp/up/$name.git" master
  git -C "$w" checkout -qb spacemacs-pin
  printf 'a\nPATCH\nc\n' >"$w/f.el"
  git -C "$w" commit -qam patch
  git init -q --bare "$tmp/me/$name.git"
  git -C "$w" push -q "$tmp/me/$name.git" master spacemacs-pin
  git -C "$w" rev-parse HEAD
}

# upstream_commit NAME CONTENT FILE: add an upstream commit writing CONTENT.
upstream_commit() {
  local w="$tmp/up-work-$1"
  rm -rf "$w"; git clone -q "$tmp/up/$1.git" "$w"
  printf "$2" >"$w/$3"
  git -C "$w" add "$3" && git -C "$w" commit -qm "upstream change"
  git -C "$w" push -q origin master
}

pin_branch() { git --git-dir="$tmp/me/$1.git" rev-parse spacemacs-pin; }

clean=$(make_fork clean);   upstream_commit clean 'new\n' g.el
conflict=$(make_fork conflict); upstream_commit conflict 'a\nUPSTREAM\nc\n' f.el
landed=$(make_fork landed); upstream_commit landed 'a\nPATCH\nc\n' f.el
current=$(make_fork current)

mkdir -p "$tmp/root/layers"
cat >"$tmp/root/layers/packages.el" <<EOF
(clean :location (recipe :fetcher github :repo "me/clean"
                         :commit "$clean"))
(conflict :location (recipe :fetcher github :repo "me/conflict" :commit "$conflict"))
(landed :location (recipe :fetcher github :repo "me/landed"
                          :commit "$landed"))
(current :location (recipe :fetcher github :repo "me/current"
                           :commit "$current"))
EOF
manifest() {
  jq -n --argjson names "$1" '{pinBranch: "spacemacs-pin", forks: [
    $names[] | {fork: ("me/" + .), upstream: ("up/" + .), upstreamBranch: "master",
                files: ["layers/packages.el"]}]}' >"$tmp/root/forks.json"
}

# Dry run pushes nothing.
manifest '["clean"]'
(cd "$tmp/root" && DRY_RUN=1 bash "$sync" forks.json) >"$tmp/out" 2>&1
check "dry run leaves branch alone" '[ "$(pin_branch clean)" = "$clean" ]'
check "dry run creates no tag" '! git --git-dir="$tmp/me/clean.git" rev-parse -q --verify "refs/tags/pin/${clean:0:12}" >/dev/null'

# Real run over all four.
manifest '["clean","conflict","landed","current"]'
rc=0; (cd "$tmp/root" && bash "$sync" forks.json) >"$tmp/out" 2>&1 || rc=$?
cat "$tmp/out"
check "exit status is 1 (conflict)" '[ "$rc" = 1 ]'
check "clean: branch rebased" '[ "$(pin_branch clean)" != "$clean" ]'
check "clean: rebased onto upstream" 'git --git-dir="$tmp/me/clean.git" merge-base --is-ancestor "$(git --git-dir="$tmp/up/clean.git" rev-parse master)" spacemacs-pin'
check "clean: patch kept" '[ "$(git --git-dir="$tmp/me/clean.git" show spacemacs-pin:f.el)" = "$(printf "a\nPATCH\nc")" ]'
check "clean: old pin tagged" '[ "$(git --git-dir="$tmp/me/clean.git" rev-parse "pin/${clean:0:12}^{commit}")" = "$clean" ]'
check "conflict: branch untouched" '[ "$(pin_branch conflict)" = "$conflict" ]'
check "conflict: issue opened" 'grep -q "me/conflict needs a manual rebase" "$ISSUE_LOG"'
check "conflict: issue lists file" 'grep -q "^- f.el" "$ISSUE_LOG"'
check "landed: branch untouched" '[ "$(pin_branch landed)" = "$landed" ]'
check "landed: unpin issue opened" 'grep -q "me/landed patches landed upstream" "$ISSUE_LOG"'
check "current: reported up to date" 'grep -q "up to date (1 patch" "$tmp/out"'
check "current: branch untouched" '[ "$(pin_branch current)" = "$current" ]'

# A file that lost its pin fails loudly.
manifest '["clean"]'
sed -i.bak 's/:repo "me\/clean"/:repo "me\/renamed"/' "$tmp/root/layers/packages.el"
rc=0; (cd "$tmp/root" && bash "$sync" forks.json) >"$tmp/out" 2>&1 || rc=$?
check "missing pin fails" '[ "$rc" = 1 ] && grep -q "has no" "$tmp/out"'

exit "$fail"
