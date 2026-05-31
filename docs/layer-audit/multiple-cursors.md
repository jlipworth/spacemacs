# Layer audit: `multiple-cursors`  (`+misc/multiple-cursors`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer correctly wires two backends and handles the paste-transient-state incompatibility. However, it silently overrides mc/always-run-for-all to t (undocumented), documents a layer-variable pattern for mc/cmds-to-run-once that silently fails due to mc/load-lists overwriting it, and lacks :defer t on the evil-mc use-package form. Verification killed one finding (consult-M-x does not exist) and adjusted two others. Overall rating unchanged: the layer works for the default evil-mc case but has several papercut-level gaps.

## Findings

### MEDIUM · bug · effort S — mc/cmds-to-run-once documented as a layer variable but the pattern silently fails

_status: adjusted · deliverable: issue_

The README shows users can extend mc/cmds-to-run-once by passing it as a :variables key. Spacemacs calls (set-default 'mc/cmds-to-run-once user-value) before the package loads — but when multiple-cursors-core.el is first required it calls mc/load-lists, which does (load mc/list-file), and the saved .mc-lists.el file contains a bare (setq mc/cmds-to-run-once ...) that unconditionally overwrites the user's value. The result: any user-supplied commands are silently dropped the moment the package loads. The auditor's proposed fix (adding a defvar) does not address this root cause. The correct fix is to (1) add a defvar multiple-cursors-extra-cmds-to-run-once to config.el and (2) add those entries inside the existing with-eval-after-load block in packages.el using add-to-list, so they are appended after mc/load-lists has run. The README example using mc/cmds-to-run-once directly as a :variables key should be removed or corrected.

**Evidence:**
- layers/+misc/multiple-cursors/README.org:120-125 — README instructs users to pass mc/cmds-to-run-once as a :variables key
- layers/+misc/multiple-cursors/config.el:26 — only multiple-cursors-backend is declared with defvar; mc/cmds-to-run-once is not declared here
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/multiple-cursors-20260419.931/multiple-cursors-core.el:874-877 — mc/load-lists calls (load mc/list-file) which executes (setq mc/cmds-to-run-once ...) from the saved file, overwriting any value set via :variables before the package loaded
- layers/+misc/multiple-cursors/packages.el:71-74 — the with-eval-after-load block uses add-to-list but never reads or merges a user-supplied layer variable

### LOW · bug · effort S — evil-mc init missing :defer t — loads eagerly at startup

_status: adjusted · deliverable: issue_

Spacemacs calls every layer init function during startup (verified in core-configuration-layer.el:2111-2119). Without :defer t (and without :bind/:mode/:commands/:hook in the use-package form), use-package requires the package immediately when the init function runs. Adding :defer t is safe: turn-on-evil-mc-mode is autoloaded, so the hooks themselves remain functional and will trigger the actual load on first use. The startup cost is the full evil-mc load on every Emacs startup rather than deferred to first prog/text-mode buffer visit. Severity is low (not medium) because evil-mc is lightweight and users enabling this layer expect to pay its startup cost; but the inconsistency with the mc backend (which does use :defer t) is worth fixing.

**Evidence:**
- layers/+misc/multiple-cursors/packages.el:31 — (use-package evil-mc has no :defer t, no :bind/:mode/:hook keywords that would trigger auto-deferral
- layers/+misc/multiple-cursors/packages.el:35-36 — prog-mode-hook and text-mode-hook are added in :init, which runs unconditionally at startup
- layers/+misc/multiple-cursors/packages.el:52-53 — the multiple-cursors init correctly uses :defer t
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/evil-mc-20241025.2045/evil-mc-autoloads.el:57-59 — turn-on-evil-mc-mode is autoloaded, so it does not require the package to be loaded to be added to hooks

### LOW · gap · effort M — mc backend exposes no SPC bindings for incremental-select, cycle, or hide-unmatched-lines

_status: adjusted · deliverable: issue_

The mc backend's primary interactive workflow (mc/mark-more-like-this-extended at SPC s m m) covers incremental selection via arrow keys. But standalone one-shot bindings for mark-next/prev-like-this, edit-ends/beginnings-of-lines, and mc-hide-unmatched-lines-mode are absent from the SPC keymap, making these features undiscoverable via which-key. mc/cycle-forward and mc/cycle-backward do have C-v/M-v in mc/keymap (active when mc mode is on), so they work in-session but are not surfaced under SPC. Suggested additions: SPC s m n (mc/mark-next-like-this), SPC s m p (mc/mark-previous-like-this), SPC s m e (mc/edit-ends-of-lines), SPC s m i (mc/edit-beginnings-of-lines), SPC s m h (mc-hide-unmatched-lines-mode). Severity is low (not medium) because the critical commands are reachable; this is a discoverability gap.

**Evidence:**
- layers/+misc/multiple-cursors/packages.el:59-69 — only 10 commands bound under SPC s m
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/multiple-cursors-20260419.931/mc-mark-more.el:138,213 — mc/mark-next-like-this and mc/mark-previous-like-this are absent from SPC bindings; mc/mark-more-like-this-extended (bound at SPC s m m) covers the interactive case via arrow keys but not one-shot use
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/multiple-cursors-20260419.931/mc-edit-lines.el:95,102 — mc/edit-ends-of-lines and mc/edit-beginnings-of-lines have no SPC binding
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/multiple-cursors-20260419.931/mc-cycle-cursors.el:101,107,113-114 — mc/cycle-forward (C-v) and mc/cycle-backward (M-v) exist in mc/keymap but are not exposed under SPC
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/multiple-cursors-20260419.931/mc-hide-unmatched-lines-mode.el:51,107 — mc-hide-unmatched-lines-mode has C-' in mc/keymap but no SPC binding

### LOW · cleanup · effort S — README typo: 'consequtive' should be 'consecutive'

_status: confirmed · deliverable: issue_

Single-character typo in user-facing documentation. Change consequtive to consecutive on line 116.

**Evidence:**
- layers/+misc/multiple-cursors/README.org:116 — 'command to consequtive cursors'

### LOW · gap · effort M — No layer tests exist for any code path

_status: confirmed · deliverable: issue_

No tests/layers/+misc/ directory exists. The paste wrapper functions in funcs.el exercise four separate conditions: dotspacemacs-enable-paste-transient-state value, evil-mc-get-cursor-count result, org-src-mode active, and table-cell text property present. All four are testable with ERT + cl-letf mocking. Create tests/layers/+misc/multiple-cursors/multiple-cursors-funcs-test.el following tests/layers/+lang/python/python-funcs-test.el as template.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*multiple*' -o -name '*cursors*' — returns empty
- find /Users/jlipworth/.emacs.d/tests -type d — shows tests/layers/+lang/python exists as gold standard; no tests/layers/+misc directory exists at all
- layers/+misc/multiple-cursors/funcs.el:26-49 — spacemacs//evil-mc-paste-transient-state-p and spacemacs/evil-mc-paste-after have four distinct code branches (transient-state enabled/disabled, org-src-mode+table-cell, plain evil-paste)

### LOW · gap · effort S — User uses bare multiple-cursors symbol — evil-mc-enable-bar-cursor silently disabled on macOS

_status: confirmed · deliverable: issue_

User is on macOS (Darwin). The platform check at packages.el:40-41 silently sets evil-mc-enable-bar-cursor to nil with no layer variable to override it. Users who run Emacs in a terminal emulator that supports bar cursors (e.g., iTerm2) have no supported way to re-enable it short of dotspacemacs/user-config. Similarly, evil-mc-one-cursor-show-mode-line-text is hardcoded nil. Adding (defvar multiple-cursors-evil-mc-bar-cursor (not (or (spacemacs/system-is-mac) (spacemacs/system-is-mswindows))) ...) to config.el and using it in the conditional would expose an opt-in.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:39 — multiple-cursors declared as bare symbol with no :variables block
- layers/+misc/multiple-cursors/packages.el:40-41 — hardcoded platform check (spacemacs/system-is-mac or system-is-mswindows) sets evil-mc-enable-bar-cursor to nil
- layers/+misc/multiple-cursors/packages.el:39 — evil-mc-one-cursor-show-mode-line-text is also hardcoded to nil
- layers/+misc/multiple-cursors/config.el:26-28 — only multiple-cursors-backend is exposed as a layer variable; no variable for bar-cursor or mode-line-text

## Additional gaps caught in verification

- **(medium/bug)** mc/always-run-for-all hardcoded to t — undocumented behavior change from package default — The layer unconditionally sets mc/always-run-for-all to t, overriding the package default of nil. With the package default (nil), users are interactively prompted when an unknown command is run during an mc session: 'run for all cursors or just once?' This prompt is a safety net that prevents accidental multi-cursor execution of destructive commands. Setting it to t silently runs every unknown command for all cursors. The layer never documents this choice in the README, and there is no layer variable allowing users to opt back into the interactive prompt. Fix: (1) add (defvar multiple-cursors-always-run-for-all t ...) to config.el, (2) use it in the :init block, (3) document the variable and its behavioral implications in README.org.

## Rejected by verifier (false positives)

- ~~mc/cmds-to-run-once missing compleseus/consult-M-x entry~~ — consult-M-x does not exist. Searched consult.el, consult-autoloads.el, and all installed elpa .el files — zero hits. The compleseus layer binds dotspacemacs-emacs-command-key to execute-extended-command (compleseus/packages.el:160), not to any consult function. execute-extended-command is covered by mc--default-cmds-to-run-once in the package itself. The original finding is based on a hallucinated function name.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

