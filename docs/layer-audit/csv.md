# Layer audit: `csv`  (`+lang/csv`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the underbuilt rating. The layer is a 48-line single-file wrapper with no config.el, no funcs.el, no tests, and no optional packages. Four interactive commands added to csv-mode since the layer was written (csv-insert-column, csv-guess-set-separator, csv-set-separator, csv-set-comment-start) have no SPC m binding. Evil normal-mode TAB navigation is silently broken because csv is absent from spacemacs-evil-collection-allowed-list. The layer is identical to upstream and has never been extended in the fork.

## Findings

### MEDIUM · gap · effort S — Newer csv-mode commands not exposed in SPC m menu

_status: adjusted · deliverable: issue_

Four interactive commands in the installed csv-mode 1.27 have no SPC m binding: csv-guess-set-separator (auto-detect/set delimiter), csv-insert-column (insert blank column), csv-set-separator (manual override), and csv-set-comment-start (bound by csv-mode itself to C-c C-c but not exposed via SPC m). Add them to packages.el under a new 'c' prefix: e.g., 'cg' → csv-guess-set-separator, 'ci' → csv-insert-column, 'cs' → csv-set-separator, 'cc' → csv-set-comment-start. Note: the original finding also claimed csv-tab-command and csv-backtab-command need to be added 'in csv-mode-map via define-key' — this is wrong; csv-mode.el lines 328-329 already bind TAB/backtab in csv-mode-map. TAB navigation in evil normal-mode is a separate issue (see missed finding).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/csv/packages.el:32-46 — keybindings stop at the original set; zero references to csv-insert-column, csv-guess-set-separator, csv-set-separator, csv-set-comment-start
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/csv-mode-1.27/csv-mode.el:995,1867,421,392 — csv-insert-column, csv-guess-set-separator, csv-set-separator, csv-set-comment-start are all (interactive) commands present in the installed 1.27 package
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/csv-mode-1.27/csv-mode.el:127-134 — changelog entries confirm csv-insert-column added in 1.21, csv-guess-set-separator added in 1.20, csv-set-separator/csv-set-comment-start added with same era

### LOW · gap · effort M — No layer variables for optional column-highlighting (rainbow-csv)

_status: adjusted · deliverable: issue_

The rainbow-csv package is not available from any of the three configured package archives (GNU ELPA, MELPA, non-GNU ELPA). The audit's claim that it's on 'JCS-ELPA' may be accurate for that third-party archive, but JCS-ELPA is not configured in this Spacemacs instance and adding a non-standard archive is a heavier lift than the 'M' effort implies. A recipe-based install via :location (recipe :fetcher github :repo "emacs-vs/rainbow-csv") would work but requires the package to be maintained. Severity is downgraded from medium to low because the feature is not installable from a standard source without extra configuration, making the layering effort non-trivial. The gap is real but the original framing overstates how easily it can be added.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:110 — bare `csv` symbol with no :variables, confirmed by direct read
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/melpa/archive-contents — grep for 'rainbow-csv' returns no results
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/gnu/archive-contents — grep for 'rainbow-csv' returns no results
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/nongnu/archive-contents — grep for 'rainbow-csv' returns no results
- No JCS-ELPA entry in any Spacemacs package-archives configuration

### LOW · gap · effort S — No config.el — no default separator or alignment customisation surface

_status: confirmed · deliverable: issue_

csv-mode exposes at least six defcustom variables that users commonly want to adjust (csv-separators, csv-align-style, csv-align-padding, csv-header-lines, csv-invisibility-default, csv-field-quotes). None are documented or surfaced in the layer. A config.el with defvar layer variables (e.g., csv-layer-separator-style) or at minimum commented setq examples for the most useful defcustoms gives users a clear extension point. The python layer config.el (line-equivalent comments + defvars) is the canonical pattern. Note: absence of config.el is not abnormal for purely trivial layers (e.g., toml also lacks one), but csv-mode is rich enough to warrant it.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/csv/ — directory listing confirms packages.el and README.org only; no config.el
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/csv-mode-1.27/csv-mode.el:186-297 — csv-separators, csv-align-style, csv-align-padding, csv-header-lines, csv-invisibility-default, csv-field-quotes are all defcustom variables with clear user-facing semantics
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/config.el — confirms the defvar + docstring pattern for layer variables in config.el
- /Users/jlipworth/.emacs.d/layers/+lang/toml/ — toml layer also has no config.el, showing the absence is not universally abnormal for very simple layers

### LOW · bug · effort S — Layer header docstring incorrectly says 'csharp Layer'

_status: confirmed · deliverable: issue_

The file-local docstring on line 1 names the wrong layer ('csharp' instead of 'csv'). Change to ';;; packages.el --- CSV Layer packages File for Spacemacs  -*- lexical-binding: nil; -*-'. This is a copy-paste bug in the upstream repo; it should also be submitted as a trivial upstream PR to syl20bnr/develop.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/csv/packages.el:1 — ';;; packages.el --- csharp Layer packages File for Spacemacs  -*- lexical-binding: nil; -*-'
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+lang/csv/packages.el line 1 — same wrong string upstream, confirming origin and that the fork inherited but did not introduce the bug

### LOW · modernization · effort S — lexical-binding set to nil without audit — should be t

_status: confirmed · deliverable: issue_

The file is 48 lines and contains no dynamic binding reliance (no funcall on let-bound symbols, no make-local-variable, no dynamic variable capture). Setting lexical-binding to t is safe, improves byte-compilation under Emacs 29+/30.2, and is a prerequisite for adding closures in a future funcs.el. Update line 1 to read ';;; packages.el --- CSV Layer packages File for Spacemacs  -*- lexical-binding: t; -*-' (this can be combined with the docstring fix). Upstream the change.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/csv/packages.el:1 — 'lexical-binding: nil;'
- git log for layers/+lang/csv/ confirms commit 55c9c2fe added nil cookies as a blanket unaudited sweep
- /Users/jlipworth/.emacs.d/layers/+lang/csv/packages.el full file — 48 lines; grep for funcall, apply, symbol-function, fset, defadvice, advice-add all return empty; no dynamic binding patterns present

### LOW · gap · effort M — No layer tests

_status: confirmed · deliverable: issue_

No tests exist for the csv layer. Create tests/layers/+lang/csv/csv-layer-test.el following the python layer pattern. At minimum: one test verifying layer loads without error, one verifying csv-mode activates for .csv files, one verifying a known SPC m binding (e.g., 'a' → csv-align-fields) is registered. Add a Makefile stub consistent with tests/layers/+lang/python/Makefile.

**Evidence:**
- /Users/jlipworth/.emacs.d/tests/layers/+lang/ — contains only python/ subdirectory; no csv directory
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ — contains init.el, layers-ftest.el, Makefile as reference pattern

### LOW · enhancement · effort M — casual transient menu not integrated (Emacs 30+ user)

_status: adjusted · deliverable: issue_

The package is named `casual` (not `casual-csv`), is a monorepo on both MELPA and non-GNU ELPA that includes CSV transient menu support, and requires (emacs 30.1) + (transient 0.9.0) + (csv-mode 1.27) — all satisfied. Add an optional integration gated on a layer variable csv-enable-casual (default nil) in a new config.el. Include (casual :toggle csv-enable-casual) in csv-packages and add a csv/init-casual that binds the csv transient to SPC m ? or SPC m m. The package name in the recipe should be 'casual', not 'casual-csv'.

**Evidence:**
- emacs --version → GNU Emacs 30.2, satisfying casual's Emacs 30.1+ requirement
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/melpa/archive-contents:533 — casual package entry confirms '(csv-mode (1 27))' dependency and availability on MELPA
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/nongnu/archive-contents — casual also available on non-GNU ELPA
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/csv-mode-1.27/csv-mode-pkg.el — installed csv-mode is 1.27, satisfying casual's dependency

## Additional gaps caught in verification

- **(medium/bug)** Evil normal-mode TAB navigation broken: csv absent from evil-collection-allowed-list — In evil normal-mode, pressing TAB does not call csv-tab-command because evil intercepts TAB before the csv-mode-map binding is reached. The evil-collection package ships evil-collection-csv.el specifically to fix this by binding TAB/backtab in evil's normal-state keymap, but it only activates modes in spacemacs-evil-collection-allowed-list. Since csv is absent from that list, field navigation via TAB is silently broken in evil normal-mode. Fix: add 'csv' to spacemacs-evil-collection-allowed-list in the csv layer's config.el (to be created) or in packages.el via (with-eval-after-load 'evil-collection (add-to-list 'spacemacs-evil-collection-allowed-list 'csv)). Alternatively, add an explicit evil normal-state binding directly in csv/init-csv-mode: (evil-define-key 'normal csv-mode-map (kbd "<tab>") 'csv-tab-command (kbd "<backtab>") 'csv-backtab-command).


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

