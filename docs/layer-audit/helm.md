# Layer audit: `helm`  (`+completion/helm`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The helm layer covers core use-cases competently and is verified identical to upstream. It is not broken. Two packages carry active FIXME/deprecation markers; five code-quality or correctness issues were confirmed; icon support and wgrep are absent while peer layers have both. Verification changed the picture on finding 3: the README ownership mismatch is a documentation inaccuracy, not a runtime footgun, so the overall maturity rating stays adequate.

## Findings

### MEDIUM · bug · effort M — helm-swoop and helm-ag carry unresolved FIXME-remove markers pointing to a MELPA deprecation PR

_status: confirmed · deliverable: issue_

Both helm-swoop (emacsattic/helm-swoop) and helm-ag (smile13241324/helm-ag fork) are fetched from GitHub recipes because their canonical MELPA listings were removed or are under removal review. The FIXME is acknowledged debt shared with upstream. Resolution options: (1) replace helm-swoop with `helm-occur` (built into Helm, no extra package) and remap the `SPC ss`/`SPC sS`/`SPC s C-s` bindings set at packages.el:472-474, or (2) close the FIXME with an explicit comment accepting the archived-source install. The user's dotfile sets `helm-swoop-pre-input-function` so option 1 requires a migration note.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/helm/packages.el:40-44 — `(helm-swoop :location (recipe :fetcher github :repo "emacsattic/helm-swoop"))` with comment `FIXME Remove obsolete packages helm-swoop / helm-ag etc. (see https://github.com/melpa/melpa/pull/9520)`
- /Users/jlipworth/.emacs.d/layers/+completion/helm/packages.el:30-33 — helm-ag sourced from smile13241324/helm-ag fork, not MELPA
- Upstream syl20bnr/develop carries the identical FIXME comment — confirmed via `git show syl20bnr/develop:layers/+completion/helm/packages.el`

### MEDIUM · gap · effort M — No icon support (helm-icons / helm-ff-icon-mode) while peer layers ivy and compleseus both have opt-in icon toggles

_status: confirmed · deliverable: issue_

Helm 3.x added native icon support via `helm-ff-icon-mode` and `helm-x-icons-provider`. The third-party `helm-icons` package (yyoncho/helm-icons) extends this to buffer lists and other sources. The ivy layer gates its icon package behind `ivy-enable-icons`; compleseus gates behind `compleseus-use-nerd-icons`. The helm layer has no equivalent. The user has `dotspacemacs-default-icons-font 'all-the-icons` but no icon rendering in helm buffers. Implementation: add a `helm-enable-icons` layer variable (default nil); when non-nil, install `helm-icons` and call `(helm-icons-mode 1)` with `helm-icons-provider` set from `dotspacemacs-default-icons-font`.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/ivy/packages.el:26 — `(all-the-icons-ivy-rich :toggle ivy-enable-icons)`
- /Users/jlipworth/.emacs.d/layers/+completion/compleseus/packages.el:37 — `(nerd-icons-completion :toggle compleseus-use-nerd-icons)`
- `grep -rn 'helm-icons\|helm-ff-icon-mode\|helm-x-icons' /Users/jlipworth/.emacs.d/layers/+completion/helm/` — zero results, confirmed
- /Users/jlipworth/GNU_files/.spacemacs:401 — `dotspacemacs-default-icons-font 'all-the-icons`

### LOW · bug · effort S — README documents helm-enable-auto-resize and helm-use-fuzzy as helm layer variables but they are defined in the spacemacs-completion layer

_status: adjusted · deliverable: issue_

These are spacemacs-completion variables, not helm layer variables. The README is inaccurate about ownership. However, the audit's 'footgun' claim is wrong: the load sequence guarantees correctness. Layer `:variables` are applied via `set-default` at declaration time (core-configuration-layer.el:1483), BEFORE `configure-layers` loads config.el files (line 1649). `defvar` does not re-set an already-bound variable, so by the time spacemacs-completion/config.el's `defvar` runs, the user's dotfile value is already set and unchanged. There is no silent no-op or clobber risk. The fix is documentation only: the README should note these are spacemacs-completion internals and redirect users to that layer's documentation.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/helm/README.org:81-87 — documents `helm-enable-auto-resize` as a `(helm :variables ...)` setting
- /Users/jlipworth/.emacs.d/layers/+completion/helm/README.org:122-128 — documents `helm-use-fuzzy` as a `(helm :variables ...)` setting
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-completion/config.el:27 — `(defvar helm-use-fuzzy 'always ...)`
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-completion/config.el:32 — `(defvar helm-enable-auto-resize nil ...)`
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-completion/packages.el:46,50 — both variables consumed in spacemacs-completion init, not helm
- /Users/jlipworth/.emacs.d/layers/+completion/helm/config.el — does not define either variable

### LOW · cleanup · effort S — spacemacs//helm-do-search-find-tool uses `eval` to dispatch search tool functions at runtime

_status: confirmed · deliverable: issue_

The `eval` is syntactically unnecessary. The function builds a quasiquoted cond to call `executable-find` on each tool string at runtime. This is functionally equivalent to `(seq-find (lambda (x) (executable-find x t)) tools)` followed by intern-based function name construction. The `eval` approach also defeats byte-compiler warnings. Replacement: `(let ((tool (seq-find (lambda (x) (executable-find x t)) tools))) (if tool (intern (format (if default-inputp "spacemacs/%s-%s-region-or-symbol" "spacemacs/%s-%s") base tool)) 'helm-do-grep))` with an `fboundp` fallback. Code works correctly today; this is purely a code quality improvement.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/helm/funcs.el:90-107 — `(eval \`(cond ,@(mapcar ...)))` builds and evaluates a cond form to pick the first available search tool
- Same pattern confirmed in upstream via `git show syl20bnr/develop:layers/+completion/helm/funcs.el`

### LOW · bug · effort S — `previous-line` (interactive command) used inside `save-excursion` in two GNE init functions

_status: confirmed · deliverable: issue_

`previous-line` is an interactive command with side effects (respects `goal-column`, signals `beginning-of-buffer` on empty buffer). The non-interactive replacement is `(forward-line -1)`. If the helm-ag or helm-grep results buffer is empty or contains only header lines, `previous-line` at point-max could signal an error that may be swallowed or cause `spacemacs--gne-max-line` to be set incorrectly. Replace both occurrences with `(forward-line -1)`. Shared upstream bug.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/helm/funcs.el:579 — `(previous-line)` inside `(save-excursion (goto-char (point-max)) (previous-line) (line-number-at-pos))` in `spacemacs//gne-init-helm-ag`
- /Users/jlipworth/.emacs.d/layers/+completion/helm/funcs.el:593 — same pattern in `spacemacs//gne-init-helm-grep`
- Upstream confirms same code via `git show syl20bnr/develop:layers/+completion/helm/funcs.el` lines 577,591

### LOW · gap · effort L — No automated tests for the helm layer (or any +completion layer)

_status: confirmed · deliverable: issue_

No test coverage exists for any +completion layer. The search-dispatch logic (`spacemacs//helm-do-search-find-tool`), GNE init functions, and the `spacemacs||set-helm-key` macro are complex enough to warrant unit tests. Suggested approach: create `tests/layers/+completion/helm/` with a `Makefile` and `layers-ftest.el` modeled on the python layer. Start with: (1) tool-selection logic by mocking `executable-find`, (2) max-line computation in `spacemacs//gne-init-helm-ag` against a synthetic buffer.

**Evidence:**
- `find /Users/jlipworth/.emacs.d/tests -name '*helm*'` — zero results
- `ls /Users/jlipworth/.emacs.d/tests/layers/` — only `+distribution` and `+lang` subdirectories; no `+completion` category
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ — reference Makefile-driven ERT test suite

### LOW · gap · effort S — User's sole helm customization (helm-swoop-pre-input-function) is not documented as a supported layer variable in README

_status: adjusted · deliverable: issue_

The user passes `helm-swoop-pre-input-function` as a raw helm-swoop package variable via `:variables`. This is a commonly-desired setting (prevents current symbol from pre-filling the swoop prompt). It will silently stop working if helm-swoop is replaced with helm-occur. The README's Configuration section should add a 'Helm-swoop' subsection documenting this variable and noting it is a raw package variable that will not apply if helm-swoop is removed. This is an enhancement to documentation rather than a code fix.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:37 — `helm-swoop-pre-input-function (lambda () "")` — only helm customization in dotfile
- `grep -n 'helm-swoop-pre-input' /Users/jlipworth/.emacs.d/layers/+completion/helm/README.org` — zero results
- README Configuration section documents 5 variables (helm-enable-auto-resize, helm-no-header, helm-position, helm-use-fuzzy, spacemacs-helm-rg-max-column-number) but not this one

## Additional gaps caught in verification

- **(low/gap)** helm layer lacks wgrep integration while ivy layer ships it explicitly — helm-ag's built-in edit mode (`helm-ag-edit`, `C-c C-e` in results) covers multi-file editing for ag/rg searches, but `wgrep` extends this to any grep-mode buffer including helm-do-grep results. The ivy layer ships `wgrep` as a first-class package with named keybindings. The helm layer is wgrep-aware (it avoids `--vimgrep` specifically to preserve wgrep compatibility) but does not install or configure `wgrep` itself. Adding `wgrep` to `helm-packages` and a `helm/post-init-wgrep` that mirrors ivy's keybindings (`SPC w`/`SPC s` in wgrep-mode) would close the gap and make the helm layer's existing rg/grep edit path consistent with ivy's.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

