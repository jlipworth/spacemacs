# Layer audit: `git`  (`+source-control/git`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer covers the core Magit workflow well and is confirmed adequate for daily use, but carries a concrete multi-variable API breakage against Magit 4 that silently no-ops or throws at runtime, a zombie user-facing variable that cannot be used as documented, and a shipped package (code-review) with zero user-accessible keybindings. Secondary concerns — smeargle staleness, magit-delta missing binary guard, wrong file header — are all confirmed. The no-layers.el finding is real but overstated: 172 of 241 layers also lack one. Rating remains adequate; the whitespace-toggle breakage and zombie forge variable keep it from 'mature'.

## Findings

### HIGH · bug · effort S — spacemacs/magit-toggle-whitespace uses removed Magit 3/4 API

_status: confirmed · deliverable: issue_

spacemacs/magit-toggle-whitespace and both of its helper functions reference three variables removed in Magit 4: magit-refresh-args (funcs.el:36,44,52), magit-diff-section-arguments (funcs.el:37,44,53), and magit-diff-options (funcs.el:49). None of these are defined anywhere in the installed magit-20260520.2337 package. The auditor's evidence mentioned only two of the three; magit-diff-options in spacemacs//magit-dont-ignore-whitespace is the third removed variable. At runtime this function silently no-ops (the variables are void symbols, member returns nil) so whitespace is never toggled and no error is surfaced. Fix by rewriting against magit-buffer-diff-args, which is the buffer-local variable Magit 4 uses (magit-diff.el:964). Also add a C-S-w row to the README keybinding table.

**Evidence:**
- funcs.el:35-53 — references magit-refresh-args (lines 36, 44, 52), magit-diff-section-arguments (lines 37, 44, 53), and magit-diff-options (line 49)
- grep -rn 'defvar magit-refresh-args|defcustom magit-refresh-args' /Users/jlipworth/.emacs.d/elpa/30.2/develop/magit-20260520.2337/*.el returns empty
- grep -rn 'defvar magit-diff-section-arguments|magit-diff-options' /Users/jlipworth/.emacs.d/elpa/30.2/develop/magit-20260520.2337/*.el returns empty
- magit-buffer-diff-args (the modern replacement) is defined at magit-diff.el:964 as a buffer-local var
- packages.el:222-223 — C-S-w is bound to this function in magit-status-mode-map
- README.org has no entry for C-S-w anywhere in the keybinding tables

### MEDIUM · bug · effort S — git-enable-magit-forge-plugin is an undefined zombie variable in user config

_status: confirmed · deliverable: issue_

The user has set git-enable-magit-forge-plugin t in their dotfile at .spacemacs:59, but no such variable exists anywhere in the git layer (config.el, packages.el, funcs.el). The setting is silently ignored. Forge loads unconditionally on non-Windows regardless. Two valid fixes: (1) define the variable in config.el and thread it into the packages.el :toggle as (and (not (spacemacs/system-is-mswindows)) git-enable-magit-forge-plugin), consistent with how all other plugins are gated; or (2) remove the variable from the user dotfile with a note that forge is always active. Option 1 is preferable for parity with delta/gitflow/svn/todos. Also add the variable to README.org under the Forge section.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:59 — git-enable-magit-forge-plugin t is set by the user
- grep of 'forge-plugin|magit-forge-plugin' across all four git layer files returns zero results
- config.el defines only: git-magit-buffers-useless, git-enable-magit-delta-plugin, git-enable-magit-gitflow-plugin, git-enable-magit-svn-plugin, git-enable-magit-todos-plugin, git-magit-status-fullscreen
- packages.el:32 — forge :toggle is (not (spacemacs/system-is-mswindows)) with no reference to any user variable

### MEDIUM · gap · effort M — code-review package ships with zero keybindings or configuration

_status: confirmed · deliverable: issue_

The doomelpa/code-review fork (installed as code-review-20250515.133454, last commit 2025-05-15) is a live package with code-review-start and code-review-mode-map fully present. The layer includes it but provides no way for users to invoke it or interact with it. At minimum, add spacemacs/set-leader-keys 'gr' 'code-review-start in git/init-code-review, register the code-review-mode major-mode prefix, and document a Code Review section in README.org. The auditor's note about verifying the doomelpa API before writing bindings is correct — do so before implementing.

**Evidence:**
- packages.el:70-72 — git/init-code-review is exactly: (use-package code-review :defer t) with nothing else
- packages.el:248-251 — only layer contribution is a post-init-emojify hook
- No SPC bindings for code-review anywhere in packages.el or funcs.el
- README.org has zero mentions of code-review
- code-review-20250515.133454/code-review-autoloads.el:17 confirms code-review-start is a valid autoloaded entry point
- code-review-20250515.133454/code-review.el:164 confirms code-review-mode-map exists

### MEDIUM · gap · effort M — No layer tests — no tests/layers/+source-control/git/ directory

_status: confirmed · deliverable: issue_

Create tests/layers/+source-control/git/ modeled on the python layer test harness. Minimum viable coverage: (1) a functional test verifying the layer loads without error; (2) a unit test for spacemacs/magit-toggle-whitespace that would have caught the Magit 4 API breakage; (3) a test for spacemacs/forge-get-info-from-fetched-notification-error, which does non-trivial base64/SQL parsing. Add a Makefile target consistent with make -C tests/layers/+source-control/git test.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -path '*source-control*' returns empty
- tests/layers/+lang/python/ contains layers-ftest.el, init.el, Makefile as the gold standard
- The broken whitespace-toggle function (three void-variable references) would be caught by a smoke test

### LOW · cleanup · effort S — funcs.el module comment incorrectly reads 'Colors Layer functions File'

_status: confirmed · deliverable: issue_

One-line fix: change 'Colors Layer functions File' to 'Git Layer functions File'. Submit upstream as well since the defect is identical in syl20bnr/develop.

**Evidence:**
- funcs.el:1 — ;;; funcs.el --- Colors Layer functions File  -*- lexical-binding: nil; -*-
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+source-control/git/funcs.el confirms identical copy-paste error on line 1 upstream

### LOW · modernization · effort M — smeargle (gH bindings) is unmaintained — last release 2020

_status: confirmed · deliverable: issue_

smeargle has not received a MELPA update since March 2020 and lives in the emacsorphanage. The blamer package (October 2025) provides per-line inline blame as a modern alternative. Consider adding blamer as a gated alternative via a git-enable-blamer-plugin variable, keeping smeargle as default for backwards compatibility. At minimum, add a README note that smeargle is unmaintained.

**Evidence:**
- MELPA archive-contents entry for smeargle: (20200323 533) — March 2020, repo at emacsorphanage/smeargle
- MELPA archive-contents entry for blamer: (20251001 620) — October 2025, actively maintained at artawower/blamer.el
- packages.el:49 — smeargle is unconditionally included in git-packages

### LOW · modernization · effort S — magit-delta plugin is stale (2022) and has no guard for missing delta binary

_status: adjusted · deliverable: issue_

When git-enable-magit-delta-plugin is t but the delta binary is absent, magit-delta-mode is activated and magit-delta-call-delta-and-convert-ansi-escape-sequences is hooked into magit-diff-wash-diffs-hook. On the first diff render, call-process-region will throw a file-error since delta is not found. Neither the layer init nor the package itself has a guard. Add (when (executable-find "delta") ...) around the :hook in git/init-magit-delta and emit a message if absent. The delta binary is present on this machine so this is not an active breakage for the user, which is why severity remains low.

**Evidence:**
- MELPA archive-contents for magit-delta: (20220125 50) — January 2022
- packages.el:253-255 — git/init-magit-delta is (use-package magit-delta :hook (magit-mode . magit-delta-mode)) with no executable-find guard
- magit-delta.el:123-125 — calls call-process-region with magit-delta-delta-executable without first checking it exists
- delta IS installed at /opt/homebrew/bin/delta on this machine, so the missing guard does not affect this user currently

### LOW · gap · effort S — No layers.el — forge/LSP-style conditional layer dependencies are not declared

_status: adjusted · deliverable: issue_

The auditor's claim that layers.el is the correct place for conditional layer dependencies is accurate in principle, but the specific rationale is weak for this layer: forge manages its own ghub dependency, and helm-git-grep is already wired by the helm layer. There is no concrete missing dependency that layers.el would fix today. The finding is valid as a forward-looking hygiene note (reserving the hook if, e.g., a completion-framework integration is added later), but should not be treated as an actionable gap requiring immediate work. If code-review bindings are added (finding 3), a layers.el might become useful to gate on whether a forge-capable layer is present.

**Evidence:**
- ls /Users/jlipworth/.emacs.d/layers/+source-control/git/ shows: config.el, funcs.el, packages.el, README.org, img/ — no layers.el
- 69 of 241 total layers have a layers.el; 172 do not — absence is the statistical norm
- The git layer currently has no concrete cross-layer dependency declaration use case that isn't already handled by the packages themselves (forge pulls ghub; helm-git-grep is in the helm layer's packages.el, not git's)

## Additional gaps caught in verification

- **(high/bug)** spacemacs//magit-dont-ignore-whitespace also references the removed magit-diff-options variable — The auditor's finding #1 lists magit-refresh-args and magit-diff-section-arguments but omits the third removed variable: magit-diff-options, used in spacemacs//magit-dont-ignore-whitespace at funcs.el:49. This is a setq to a void variable, which in Emacs does not throw but creates a new free variable binding, meaning the intended effect (storing the modified diff args) is silently discarded. The fix for finding #1 covers this as well, but the evidence in that finding should be updated to list all three removed variables.
- **(low/cleanup)** README.org documents helm-git-grep as a git layer feature but it is not provided by this layer — README.org lines 51 implies helm-git-grep is part of the git layer, but the git layer has never included it. The bindings (SPC g/ and SPC g*) are contributed by the +completion/helm layer's packages.el. The fix is to either (a) remove the line from the git layer README and note that helm layer users get this automatically, or (b) add a cross-reference: 'git grep integration via helm-git-grep is provided by the helm layer'. This misleads users who enable the git layer without helm into thinking they will have helm-git-grep.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

