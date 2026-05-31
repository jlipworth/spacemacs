# Layer audit: `shell`  (`+tools/shell`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The maturity rating holds. The layer integrates all major terminal emulators coherently and is not thin. The dead-advice bug (finding #1) is a real silent data-loss regression for eshell users that upstream also carries. Three medium-complexity integration gaps (eat, vterm-consult) are real but bounded. The two lowest-severity findings (point-at-bol, lexical-binding) are clean and well-evidenced. No finding was found to be a false positive; two were adjusted for precision.

## Findings

### HIGH · bug · effort S — Dead advice silently drops eshell history persistence after shell-pop rewrite

_status: confirmed · deliverable: issue_

shell-pop's May 2026 rewrite removed shell-pop--kill-and-delete-window and replaced window-close handling with shell-pop--eshell-exit-hook-delete-window registered on eshell-exit-hook inside shell-pop--set-exit-action. The Spacemacs layer still advises the removed function, so the advice silently does nothing. Eshell's own eshell--save-history hook (em-hist.el:304) only fires when the buffer is killed (via kill-buffer-hook -> eshell-kill-buffer-function -> eshell-exit-hook), but shell-pop buries the buffer on close, so history is NOT written on popup close — only on buffer kill (Emacs exit or manual kill). Fix: remove the advice-add call in packages.el:248, remove spacemacs/shell-pop-with-eshell-history-write in funcs.el:331-337, and add (add-hook 'eshell-exit-hook #'eshell-write-history) and (add-hook 'eshell-exit-hook #'eshell-write-last-dir-ring) directly in shell/init-shell-pop (eshell's own guard on eshell-history-file-name prevents double-write). Alternatively hook into shell-pop-out-hook with a mode check. Secondary note: the existing advice wrapper has an additional logic bug — when (one-window-p) is true, orig-fun is never applied, but this is moot since the target is gone.

**Evidence:**
- layers/+tools/shell/packages.el:248 — advice-add on 'shell-pop--kill-and-delete-window which does not exist in shell-pop-20260529.56
- elpa/30.2/develop/shell-pop-20260529.56/shell-pop.el — grep for 'shell-pop--kill-and-delete-window' returns nothing; function list confirms it was replaced by shell-pop--eshell-exit-hook-delete-window at line 402
- elpa/30.1/develop/shell-pop-20241207.1539/shell-pop.el:269 — function existed in the pre-rewrite version, confirming removal
- layers/+tools/shell/funcs.el:331-337 — spacemacs/shell-pop-with-eshell-history-write wraps the absent function; it never fires
- opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/eshell/esh-mode.el:404 — eshell adds eshell-kill-buffer-function to kill-buffer-hook; this runs eshell-exit-hook including eshell--save-history (em-hist.el:304) only when the buffer is killed, NOT when shell-pop buries it on popup close
- elpa/30.2/develop/shell-pop-20260529.56/shell-pop.el:608 — shell-pop-out calls bury-buffer, not kill-buffer, so eshell-exit-hook does not fire on popup close
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+tools/shell/packages.el:248 confirms upstream develop has the same dead advice — this is a candidate upstream PR

### MEDIUM · gap · effort S — vterm M-r history search has no consult handler; user's helm setup is also inert because spacemacs-vterm-history-file-location is unset

_status: adjusted · deliverable: issue_

Two independent sub-gaps. (1) The consult branch is a real layer-level gap: spacemacs//vterm-bind-m-r (funcs.el:324-329) handles helm and ivy but has no consult branch. Any consult user who sets spacemacs-vterm-history-file-location gets no M-r binding. Fix: add a consult cond branch that calls consult-history (which works with a provided history list). (2) The claim that the user's 'helm setup is inert' is technically accurate (M-r is never bound because spacemacs-vterm-history-file-location is nil, which gates the call to spacemacs//vterm-bind-m-r at packages.el:371-372), but this is a user configuration issue rather than a layer bug — the helm branch exists and would work if the variable were set. The auditor's framing combines a real layer gap (consult) with a user config omission (helm path unset); these should be treated as separate items. Severity is correctly medium for the consult gap; the helm-path issue is user-actionable documentation.

**Evidence:**
- layers/+tools/shell/funcs.el:324-329 — spacemacs//vterm-bind-m-r dispatches only on helm and ivy; no consult branch
- layers/+tools/shell/config.el:87-88 — spacemacs-vterm-history-file-location defaults to nil
- /Users/jlipworth/GNU_files/.spacemacs:96-100 — user sets shell-default-shell 'vterm but sets no spacemacs-vterm-history-file-location (grep confirms zero occurrences of 'vterm-history' in config)
- /Users/jlipworth/GNU_files/.spacemacs:36 — user has helm layer but NOT consult layer (zero consult references in config)

### MEDIUM · gap · effort S — eat is not added to evil-collection-allowed-list and has no SPC m major-mode menu

_status: confirmed · deliverable: issue_

eat's integration is incomplete in three concrete ways: (1) evil-collection support exists (evil-collection-eat.el) but is never loaded because 'eat is absent from spacemacs-evil-collection-allowed-list. Without it, escape-key behavior in eat is inconsistent with vterm. Fix: add (add-to-list 'spacemacs-evil-collection-allowed-list 'eat) in shell/pre-init-evil-collection. (2) No SPC m key bindings exist for eat's four input modes. Fix: add (spacemacs/set-leader-keys-for-major-mode 'eat-mode "C" 'eat-char-mode "L" 'eat-line-mode "E" 'eat-emacs-mode "S" 'eat-semi-char-mode) in shell/init-eat :config. (3) eat-mode is also absent from vi-tilde-fringe disable hooks (packages.el:338-343) and from the window-purpose terminal mapping (packages.el:401-407). The auditor's finding covers (1) and (2) accurately; sub-gaps (3) were missed and are noted in missed_findings.

**Evidence:**
- layers/+tools/shell/packages.el:134-135 — shell/pre-init-evil-collection adds only 'vterm; eat is absent
- elpa/30.2/develop/evil-collection-20251205.1511/modes/eat/evil-collection-eat.el:1 — evil-collection support for eat exists, provides evil-collection-eat-setup with insert-state C-* pass-through bindings and escape-toggle
- layers/+tools/shell/packages.el:345-355 — shell/init-eat sets no spacemacs/set-leader-keys-for-major-mode for eat-mode
- eat-0.9.4/eat.el:5869,5879,5891,5970 — eat-emacs-mode, eat-semi-char-mode, eat-char-mode, eat-line-mode all defined and interactive
- layers/+tools/shell/packages.el:338-343 — vi-tilde-fringe hook list does not include eat-mode-hook (comint, eshell, shell, term only)
- layers/+tools/shell/packages.el:401-407 — window-purpose configuration includes vterm-mode, eshell-mode, shell-mode, term-mode but NOT eat-mode

### LOW · cleanup · effort S — point-at-bol is obsolete since Emacs 29.1 and emits byte-compiler warnings

_status: confirmed · deliverable: issue_

Replace (point-at-bol) on funcs.el:171 with (line-beginning-position). Both respect fields; line-beginning-position is the non-deprecated form. pos-bol is NOT correct because inhibit-field-text-motion is explicitly set to t in the same let block, indicating the code specifically wants field-aware beginning-of-line behavior. One-line fix.

**Evidence:**
- layers/+tools/shell/funcs.el:171 — (point-at-bol) inside spacemacs//protect-eshell-prompt
- Emacs 30.2 marks point-at-bol byte-obsolete since 29.1 with replacement line-beginning-position or pos-bol
- funcs.el:169 — inhibit-field-text-motion is set to t on the enclosing let, so line-beginning-position (field-aware) is correct; pos-bol would be wrong here
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+tools/shell/funcs.el:171 — same in upstream

### LOW · modernization · effort M — All three .el files explicitly disable lexical binding

_status: confirmed · deliverable: issue_

The nil cookie was added deliberately by commit 55c9c2fe, not by omission, because the files were not audited for dynamic binding reliance. The make-shell-pop-command macro (funcs.el:98-125) is the highest-risk area — it uses backtick expansion and references shell-pop-term-shell and shell-pop-internal-mode as free variables that may rely on dynamic lookup. Enabling lexical-binding: t would require a careful audit of these closures. This is a valid modernization but the effort assessment of M is correct. Not fork-specific debt since upstream develop is identical.

**Evidence:**
- layers/+tools/shell/packages.el:1 — lexical-binding: nil;
- layers/+tools/shell/config.el:1 — lexical-binding: nil;
- layers/+tools/shell/funcs.el:1 — lexical-binding: nil;
- git show 55c9c2fe — commit message explains nil was chosen deliberately for files needing dynamic-binding audit; shell files are among those explicitly set to nil in that commit
- layers/+lang/python/funcs.el:1 — also lexical-binding: nil; confirming this is a widespread repo pattern, not shell-specific debt

### LOW · gap · effort L — No layer tests exist for +tools/shell

_status: confirmed · deliverable: issue_

No tests exist for the shell layer. Most testable units: make-shell-pop-command macro (does it generate correctly-named functions?), spacemacs/default-pop-shell dispatch table (cl-case mapping: multi-vterm -> multivterm, shell -> inferior-shell, etc.), and spacemacs//protect-eshell-prompt text property assertions. Gold standard: tests/layers/+lang/python/Makefile pattern. Create tests/layers/+tools/shell/{Makefile,init.el,shell-utest.el}.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*shell*' returns nothing
- tests/layers/ contains only +distribution/ and +lang/ — no +tools/ directory
- tests/layers/+lang/python/ has Makefile + layers-ftest.el + init.el as gold standard

## Additional gaps caught in verification

- **(low/gap)** eat-mode absent from window-purpose terminal mapping and vi-tilde-fringe hooks — eat-mode is registered for hl-line disable (packages.el:355) but was not added to two other per-mode configuration points that every other terminal mode gets: (1) window-purpose terminal classification — without this, buffers using eat as a shell-pop default will not be classified as 'terminal purpose, potentially breaking purpose-aware window layouts. Fix: add (eat-mode . terminal) to the purpose-conf in shell/post-init-window-purpose. (2) vi-tilde-fringe disable — without this, eat buffers will display the vi-tilde fringe markers in empty terminal lines when vi-tilde-fringe is active. Fix: add 'eat-mode-hook to the hooks list in shell/post-init-vi-tilde-fringe. Both are one-line additions. Also missing: centered-cursor-mode inhibit for eat (every other terminal shell has a with-eval-after-load centered-cursor-mode block; eat-mode does not).
- **(low/bug)** spacemacs/shell-pop-with-eshell-history-write drops orig-fun call when one-window-p — This is a secondary logic bug in the dead advice wrapper: when (one-window-p) returns t, the function returns nil without calling (apply orig-fun args). In the old shell-pop this meant the window-delete call was skipped for single-window frames (arguably intentional per the old shell-pop--kill-and-delete-window which also checked one-window-p), but it also meant eshell history was not written in that case. This is now moot because the target function no longer exists, but should be cleaned up as part of fixing finding #1 to avoid any confusion if someone attempts to restore the advice pattern.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

