# Layer audit: `spell-checking`  (`spell-checking`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer delivers its core contract cleanly and is a zero-delta mirror of upstream syl20bnr/develop. The maturity rating holds: flyspell-correct 1.0.0 has outpaced the layer (flyspell-correct-region, flyspell-correct-previous/next, and a built-in completing-read default are all unexposed), no previous-error keybinding exists, no layer variables for ispell backend, no tests, and the README cites Emacs 25.2. All eight findings are real. The picture did not change materially during verification.

## Findings

### MEDIUM · gap · effort S — flyspell-correct-region not exposed — interactive batch correction unavailable

_status: adjusted · deliverable: issue_

flyspell-correct 1.0.0 ships flyspell-correct-region (line 347 of flyspell-correct.el) which runs flyspell-region to mark errors, then iterates through each overlay and calls flyspell-correct-at-point, giving the user an interactive per-word correction session. The layer binds SPC S r only to flyspell-region (which marks but does not correct). Add SPC S R (or override SPC S r) bound to flyspell-correct-region in spell-checking/init-flyspell-correct's :init block, and add the same key to the transient state doc/bindings. The auditor cited line 108 but the binding is at line 106; the factual claim is otherwise exact.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/packages.el:106 — 'Sr' is bound to flyspell-region (marks errors only); flyspell-correct-region is never referenced anywhere in the layer
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/flyspell-correct-20260106.955/flyspell-correct.el:347 — flyspell-correct-region runs flyspell-region then interactively corrects each error one-by-one through the configured interface
- /Users/jlipworth/GNU_files/.spacemacs:52-55 — user has helm as completion layer and enable-flyspell-auto-completion t, making interactive batch region correction the natural workflow

### LOW · gap · effort S — No 'previous error' navigation binding (SPC S p / transient-state N)

_status: adjusted · deliverable: issue_

flyspell-goto-next-error uses (interactive "P"), so SPC u SPC S n navigates backward already, but there is no dedicated SPC S p binding. The proposed lambda (flyspell-goto-next-error t) in the original audit works since t is truthy, but calling the function interactively with a prefix via a named binding is cleaner. The auditor also cited packages.el:107 for the Sn binding; it is actually at line 108. Claim is otherwise valid.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/packages.el:73 — transient state 'n' bound to flyspell-goto-next-error; packages.el:108 — 'Sn' bound to flyspell-goto-next-error; no backward navigation binding exists anywhere in the layer
- /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/textmodes/flyspell.el:1716 — (defun flyspell-goto-next-error (&optional previous) ... (interactive "P")) — accepts prefix arg for backward navigation
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/flyspell-correct-20260106.955/flyspell-correct.el:298 — flyspell-correct-previous is a dedicated function for backward navigation with correction

### LOW · gap · effort S — No layer variable for ispell backend selection (ispell-program-name / ispell-dictionary)

_status: adjusted · deliverable: issue_

Confirmed as described. config.el ends at line 31 (not 32 as cited), but the substantive claim is correct. The README explicitly tells users to set ispell-program-name in user-init, bypassing the layer variable contract used by every other language layer. Adding spell-checking-backend and spell-checking-default-dictionary as layer variables is a clean improvement.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/config.el:24-31 — only three layer variables defined: spell-checking-enable-by-default, spell-checking-enable-auto-dictionary, enable-flyspell-auto-completion
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/README.org:36-41 — backend selection documented as requiring manual setq ispell-program-name in dotspacemacs/user-init
- /opt/homebrew/bin/aspell — aspell 0.60.8.2 installed; user may want hunspell for multi-dict support without editing user-init

### LOW · modernization · effort S — lexical-binding set to nil — should be audited for t eligibility

_status: confirmed · deliverable: issue_

All three files are safe for lexical-binding: t. funcs.el:73 uses (let (poss ispell-filter) ...) — since ispell-filter is declared with defvar, Emacs treats the let binding as dynamic/special even under lexical-binding: t, so the process filter can still update it via setq and the code at line 80 reads it correctly. ispell-process at line 79 is also a defvar, so it remains special. packages.el and config.el have no closures or dynamic variable captures at all. Switching all three to lexical-binding: t is safe.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/packages.el:1 — lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/config.el:1 — lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/funcs.el:1 — lexical-binding: nil
- /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/textmodes/ispell.el:805 — (defvar ispell-process nil) — special/dynamic regardless of lexical-binding
- /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/textmodes/ispell.el:1561 — (defvar ispell-filter nil) — special/dynamic regardless of lexical-binding
- git commit 55c9c2fe (2025-04-22) — upstream left these files at nil pending per-file examination

### LOW · cleanup · effort S — enable-flyspell-auto-completion breaks layer naming convention

_status: confirmed · deliverable: issue_

The naming inconsistency is confirmed: two variables in config.el use the spell-checking- prefix, but enable-flyspell-auto-completion does not. This is the convention used by all other layer variables (verified by scanning +lang/python/config.el, +completion/auto-completion/config.el, etc.). Since the fork is identical to upstream, fixing this would create a local divergence from upstream; a backward-compatibility defvaralias is needed. The auditor correctly notes the user's dotfile at line 54 would need updating.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/config.el:30 — (defvar enable-flyspell-auto-completion nil) — missing spell-checking- prefix, unlike the other two variables in this file
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/packages.el:32 — :toggle enable-flyspell-auto-completion
- /Users/jlipworth/GNU_files/.spacemacs:54 — enable-flyspell-auto-completion t — user's live config uses the wrong-named variable
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+checkers/spell-checking/config.el — upstream has identical variable name; this is an upstream naming bug

### LOW · gap · effort M — No layer tests — spacemacs//word-in-dict-p has untested ispell subprocess logic

_status: confirmed · deliverable: issue_

Confirmed as described. The tests directory has subdirs for +distribution and +lang/python but nothing under +checkers. funcs.el has genuine non-trivial logic across 37 lines (lines 53-89). The python layer pattern (Makefile + layers-ftest.el covering package loading and variable defaults) applies directly here.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*spell*' — returns nothing; no test directory exists for this layer
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/funcs.el:53-89 — spacemacs//add-word-to-dict and spacemacs//word-in-dict-p contain non-trivial ispell subprocess interaction (ispell-send-string, accept-process-output, ispell-process)
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ — python layer has layers-ftest.el + Makefile as the pattern to follow

### LOW · cleanup · effort S — README cites Emacs 25.2 for hunspell multi-dict — 8-year-old caveat

_status: confirmed · deliverable: issue_

Confirmed. README.org line 112 reads exactly as cited. The caveat is anachronistic when all packages in this layer require emacs 29.1 minimum (per MELPA archive-contents). The line should be removed or replaced with a note that multi-dict hunspell has been reliable since Emacs 26+.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/README.org:112 — 'tested with version coming from Emacs 25.2 repository'
- /opt/homebrew/Cellar/emacs-plus@30/30.2 — Emacs 30.2 is in use; this repo targets Emacs 29+ per all package requirements

### LOW · gap · effort S — flyspell-correct-avy-menu interface not exposed for non-ivy/non-helm users

_status: confirmed · deliverable: issue_

Confirmed. The MELPA archive contains flyspell-correct-avy-menu as a valid separate package. The layer forces flyspell-correct-popup for all users who lack ivy or helm, overriding the completing-read default that ships with flyspell-correct itself and would work transparently with vertico, selectrum, or ido. Adding a spell-checking-correct-interface variable or at minimum a toggle for avy-menu would avoid the unnecessary popup.el dependency for many users. The core claim is valid.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/melpa/archive-contents — flyspell-correct-avy-menu 20260106.955 confirmed as standalone MELPA package requiring flyspell-correct 1.0.0 + avy-menu 0.1.1 + emacs 29.1
- /Users/jlipworth/.emacs.d/layers/+checkers/spell-checking/packages.el:30-31 — flyspell-correct-popup is the only non-ivy/non-helm fallback; it overrides flyspell-correct's default completing-read interface
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/flyspell-correct-20260106.955/flyspell-correct.el:64 — (defcustom flyspell-correct-interface #'flyspell-correct-completing-read) — completing-read is the default and works without any sub-package

## Additional gaps caught in verification

- **(low/modernization)** flyspell-popup (enable-flyspell-auto-completion) should offer flyspell-correct-auto-mode as a modern alternative — When enable-flyspell-auto-completion is t the layer installs flyspell-popup, a package that has not been updated since May 2017 and uses the deprecated make-variable-buffer-local. flyspell-correct 1.0.0 (already installed) includes flyspell-correct-auto-mode which provides equivalent idle-correction functionality. The layer could use flyspell-correct-auto-mode instead of (or in addition to) flyspell-popup when flyspell-correct is active, eliminating a stale dependency. Note: the flyspell-correct-auto-mode docstring discourages its use, so any migration should be opt-in rather than a replacement.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

