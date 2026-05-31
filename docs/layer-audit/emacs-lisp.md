# Layer audit: `emacs-lisp`  (`+lang/emacs-lisp`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

All seven audit findings hold up under verification: two medium bugs (format-on-save undocumented/untoggleable; overseer shadows ERT's tb/tq due to alphabetical package init order), one low bug (README table shows SPC m : instead of SPC m T n for nameless), one medium gap adjusted for precision (flycheck-elsa is not literally a no-op due to its predicate guard, but is functionally useless without undocumented Cask/Eask+Elsa setup), two low gaps (no test suite; lexical-binding: nil upgrade deferred), and one low enhancement (elisp-autofmt as opt-in formatter). The 'adequate' rating stands: the layer covers the core elisp developer workflow (IELM, edebug, ERT, flycheck-package, nameless, srefactor, auto-compile) but has real gaps in documentation, keybinding consistency, and test coverage that prevent a 'mature' rating.

## Findings

### MEDIUM · bug · effort S — emacs-lisp-format-on-save defaults to t but is undocumented and has no toggle

_status: confirmed · deliverable: issue_

Confirmed exactly as described. The format-on-save variable defaults to t and runs indent-region + whitespace-cleanup on every elisp buffer save. The README has no Layer Variables section and no mention of emacs-lisp-format-on-save anywhere. Only emacs-lisp-hide-namespace-prefix is documented (README lines 122-130 in prose, not in a formal variables table). The user's dotfile uses the bare `emacs-lisp` symbol, so the default t applies silently. Fix: (1) add `SPC m T f` toggle mirroring the nameless toggle pattern at packages.el:262-267; (2) document both layer variables in a new 'Layer variables' section in README.org; (3) consider flipping default to nil, matching python layer's conservative choice.

**Evidence:**
- layers/+lang/emacs-lisp/config.el:33 — `(defvar emacs-lisp-format-on-save t ...)`
- layers/+lang/emacs-lisp/README.org — zero matches for 'format-on-save' or 'emacs-lisp-format' anywhere in the file
- layers/+lang/emacs-lisp/packages.el:262-267 — `spacemacs|add-toggle` exists only for nameless (:evil-leader-for-mode (emacs-lisp-mode . "Tn")); no equivalent toggle for format-on-save
- layers/+lang/emacs-lisp/funcs.el:147,156 — `spacemacs//make-elisp-buffers-format-on-save-maybe` and `spacemacs//format-elisp-buffer` both gate on `emacs-lisp-format-on-save`; they run `indent-region` + `whitespace-cleanup` on every save
- /Users/jlipworth/GNU_files/.spacemacs:102 — bare `emacs-lisp` symbol with no :variables override, so default t silently applies
- layers/+lang/python/config.el:58 — `(defvar python-format-on-save nil ...)` uses nil as the safer default for comparison

### MEDIUM · bug · effort S — overseer silently shadows ERT's SPC m t b and SPC m t q keybindings

_status: confirmed · deliverable: issue_

Confirmed. Spacemacs processes packages in alphabetical order (core-configuration-layer.el:393 confirms sorted list). Since 'emacs-lisp' < 'overseer' alphabetically, `emacs-lisp/init-emacs-lisp` is called first, then `emacs-lisp/init-overseer` overwrites tb and tq for emacs-lisp-mode. The ERT `spacemacs/ert-run-tests-buffer` becomes unreachable via SPC m. The README documents both sets of bindings under the same key without flagging the conflict. Fix: give overseer distinct keys (e.g., `tB`/`tQ`) or gate the overseer bindings on absence of ERT usage, and update README accordingly.

**Evidence:**
- layers/+lang/emacs-lisp/packages.el:220-221 — `"tb" 'spacemacs/ert-run-tests-buffer` and `"tq" 'ert` bound in `emacs-lisp/init-emacs-lisp`
- layers/+lang/emacs-lisp/packages.el:280,285 — `"tb" 'overseer-test-this-buffer` and `"tq" 'overseer-test-quiet` bound in `emacs-lisp/init-overseer`
- core/core-configuration-layer.el:393 — packages are configured in alphabetical order ('emacs-lisp' < 'overseer'), so overseer's init runs after and overwrites ERT bindings
- layers/+lang/emacs-lisp/packages.el:48 — `overseer` is listed unconditionally in `emacs-lisp-packages` with no `:toggle` or `:requires` guard
- README.org:188-189 — documents SPC m t b as 'run tests of current buffer' (ERT); README.org:203-205 — documents SPC m t b again as 'test buffer' (overseer) with no conflict notice

### MEDIUM · gap · effort S — flycheck-elsa integration is a no-op: elsa linter is not declared as a package dependency

_status: adjusted · deliverable: issue_

The finding is real but needs a precision adjustment. The audit states flycheck-elsa is 'a no-op' — this is partially correct but slightly overstated. flycheck-elsa-setup does add the checker to flycheck-checkers, but the checker has a :predicate (flycheck-elsa--enable-p) that checks for a Cask.el or Eask file containing elsa as a dependency before running. So it won't actively error out, but it does silently register a checker that will never fire for most users. The core problem stands: neither the Elsa binary nor any setup documentation exists. The README has zero mentions of elsa, cask, or eask. Fix: document in README that flycheck-elsa requires a Cask/Eask-managed project with elsa as a declared dependency; optionally gate it on a new `emacs-lisp-enable-elsa-support` layer variable defaulting to nil.

**Evidence:**
- layers/+lang/emacs-lisp/packages.el:39 — `(flycheck-elsa :requires flycheck)` in package list
- layers/+lang/emacs-lisp/packages.el:316-321 — `emacs-lisp/init-flycheck-elsa` calls `flycheck-elsa-setup` via transient hook
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/ — contains `flycheck-elsa-20230217.1640` but no `elsa` package
- flycheck-elsa.el:103-113 — `flycheck-elsa--enable-p` predicate guards execution: requires Cask/Eask config file AND elsa listed as a dependency in that file
- layers/+lang/emacs-lisp/README.org — zero matches for 'elsa', 'cask', or 'eask'

### LOW · bug · effort S — README.org key bindings table documents wrong key for nameless toggle

_status: confirmed · deliverable: issue_

Confirmed exactly. README.org line 191 claims SPC m : toggles nameless, but line 120 (same file) and packages.el:267 both confirm the actual binding is SPC m T n. SPC m : is not bound to anything by this layer. Fix is a one-line README edit: change `~SPC m :~` to `~SPC m T n~` at README.org:191.

**Evidence:**
- layers/+lang/emacs-lisp/README.org:191 — table row: `| ~SPC m :~ | toggle nameless minor mode |`
- layers/+lang/emacs-lisp/README.org:120 — prose section: 'It can be toggled with ~SPC m T n~.'
- layers/+lang/emacs-lisp/packages.el:267 — `:evil-leader-for-mode (emacs-lisp-mode . "Tn")` confirms actual binding is SPC m T n

### LOW · gap · effort M — No layer-level test suite while python gold standard has one

_status: confirmed · deliverable: issue_

Confirmed. No test directory exists for this layer. The python layer's test structure (tests/layers/+lang/python/) with ERT-based layers-ftest.el and Makefile is the established pattern. The emacs-lisp layer has several functions worth covering: spacemacs/ert-run-tests-buffer (buffer-scoping logic), spacemacs/eval-current-form (backward regexp search), and format-on-save hook registration/deregistration.

**Evidence:**
- `find /Users/jlipworth/.emacs.d/tests -name '*emacs-lisp*'` returns nothing
- tests/layers/+lang/python/ contains init.el, layers-ftest.el, Makefile
- layers/+lang/emacs-lisp/funcs.el:173-180 — `spacemacs/ert-run-tests-buffer` is a non-trivial function worth testing
- layers/+lang/emacs-lisp/funcs.el:27-34 — `spacemacs/eval-current-form` uses `search-backward-regexp` which could regress

### LOW · enhancement · effort M — elisp-autofmt was added then reverted upstream — reconsider as an opt-in formatter

_status: confirmed · deliverable: issue_

Confirmed. The upstream history clearly shows the add-then-revert cycle within 3 days (Dec 8-11 2025). The revert gives no technical rationale. The current formatter is bare indent-region + whitespace-cleanup. Implementing elisp-autofmt as an opt-in via a `emacs-lisp-formatter` layer variable (values: `default` or `elisp-autofmt`) would mirror the python layer's `python-formatter` pattern and be safe for existing users.

**Evidence:**
- Upstream commit 86b1a5ff (Dec 8 2025) added elisp-autofmt; commit 120814a2 (Dec 11 2025) reverted it — confirmed via `git log syl20bnr/develop -- layers/+lang/emacs-lisp/`
- Revert message: 'Revert Add elisp-autofmt integration and improve formatting'; original commit message: 'enable consistent, automated formatting for Emacs Lisp code'
- layers/+lang/emacs-lisp/funcs.el:154-159 — current formatter is `indent-region` + `whitespace-cleanup` only
- layers/+lang/python/config.el:48-56 — python layer uses `python-formatter` variable with multiple values as the pattern to follow

### LOW · modernization · effort S — All three layer files carry lexical-binding: nil — audit for safe upgrade to t

_status: confirmed · deliverable: issue_

Confirmed as a valid modernization candidate. The upstream commit explicitly called this deferred work. Examination of all three files reveals no reliance on dynamic binding that would be broken by `lexical-binding: t`: all free variable references in funcs.el are to `defvar`-declared special variables (emacs-lisp-format-on-save, buffer-file-name, edebug-mode, golden-ratio-mode), which remain dynamically scoped under lexical-binding: t. packages.el and config.el use only standard let-bindings and macro forms. The upgrade path is: change the cookie in all three files and run `make -C tests/core test`.

**Evidence:**
- layers/+lang/emacs-lisp/packages.el:1 — `;;; packages.el ...  -*- lexical-binding: nil; -*-`
- layers/+lang/emacs-lisp/funcs.el:1 — `;;; funcs.el ...  -*- lexical-binding: nil; -*-`
- layers/+lang/emacs-lisp/config.el:1 — `;;; config.el ...  -*- lexical-binding: nil; -*-`
- Upstream commit 55c9c2fe (Apr 22 2025): 'for each file, someone would need examine it and check whether dynamic binding is relied on somewhere. Hence I went with the current default of lexical-binding: nil for now to pacify the warnings in Emacs 31.'
- funcs.el — uses `emacs-lisp-format-on-save`, `buffer-file-name`, `edebug-mode`, `golden-ratio-mode` as free variables; all are declared `defvar`/special so they remain dynamically scoped even under lexical-binding: t

## Additional gaps caught in verification

- **(low/bug)** README Format code section attributes srefactor-lisp bindings to 'semantic' — The README Format code section says 'formatting with semantic can be used' and labels the SPC m = b/d/o/s bindings as 'semantic' operations. The actual bound commands are all `srefactor-lisp-*` functions from the srefactor package, not semantic functions. While srefactor uses semantic as a parsing backend, users searching for the srefactor package name in the docs will find nothing. Fix: change the README prose to reference srefactor (e.g., 'formatting with srefactor-lisp can be used if the srefactor package is available') and update the keybinding table descriptions from 'with semantic' to 'with srefactor'.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

