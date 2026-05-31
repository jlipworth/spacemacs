# Layer audit: `syntax-checking`  (`+checkers/syntax-checking`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer covers the core flycheck workflow completely and is byte-for-byte identical to upstream. It handles global enable-by-default, configurable tooltip backend, evilified error-list, fringe/margin indicator, and a reasonable SPC e keymap. Gaps confirmed by verification: the tooltip backend remains X11-only with no posframe/child-frame alternative; no mechanism to coordinate with lsp-mode diagnostics (multiple language layers already carry per-layer workarounds as evidence); the README has a genuinely broken copy-pasteable code block; SPC e y is wired but undocumented; lexical-binding is nil across all three .el files; and there are zero ERT tests. Rating unchanged from the audit.

## Findings

### MEDIUM · bug · effort S — README code example for window-position is syntactically broken

_status: confirmed · deliverable: issue_

The #+BEGIN_SRC emacs-lisp block at README.org line 120 demonstrates `syntax-checking-window-position 'right` and `syntax-checking-window-width 60` but is missing the closing `)))` before #+END_SRC (one for the :variables list, one for the `'(...)` dotspacemacs-configuration-layers list, one for `setq-default`). A user copying it verbatim gets an unbalanced-parenthesis reader error. Fix: insert `)))` on a new line before the #+END_SRC marker at line 125. The fix should be upstreamed.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/README.org:120-125 — #+BEGIN_SRC block at line 120 ends at line 125 with `syntax-checking-window-width 60` followed immediately by #+END_SRC; the `setq-default` form and the `:variables` list are both unclosed — three closing parens are missing
- Upstream confirmed identical: `git show syl20bnr/develop:layers/+checkers/syntax-checking/README.org` lines 119-127 show the same truncated block

### MEDIUM · modernization · effort M — flycheck-pos-tip is X11-only with no posframe/child-frame alternative

_status: confirmed · deliverable: issue_

The layer offers no alternative when `flycheck-pos-tip` is non-functional (macOS, Wayland). Since `posframe` is already available in the repo, the dependency cost for `flycheck-posframe` is low. Add a new layer variable `syntax-checking-tooltip-backend` (values `'pos-tip` / `'posframe`, default `'pos-tip`), declare `(flycheck-posframe :toggle (and syntax-checking-enable-tooltips (eq syntax-checking-tooltip-backend 'posframe)))` in `syntax-checking-packages`, and write `syntax-checking/init-flycheck-posframe` to call `(flycheck-posframe-mode 1)`. For now users can work around by setting `syntax-checking-enable-tooltips nil` and relying on `lsp-ui-sideline`.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/packages.el:31 — `(flycheck-pos-tip :toggle syntax-checking-enable-tooltips)` is the only tooltip backend offered
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-visual/packages.el:34 — `posframe` is already a declared package dependency in the repo (init function at line 82)
- User is on macOS Darwin 25.5.0 (confirmed from env context); flycheck-pos-tip uses the X11 tooltip API and does not work reliably on macOS or Wayland
- flycheck-posframe (https://github.com/flycheck/flycheck-posframe) is an actively maintained MELPA package using child frames, which work on macOS

### MEDIUM · gap · effort M — No variable to hand diagnostic responsibility to lsp-mode's native provider

_status: confirmed · deliverable: issue_

When both `lsp` and `syntax-checking` layers are co-loaded, `lsp-mode` defaults `lsp-diagnostics-provider` to `:flycheck`, causing its LSP bridge checker and standalone flycheck checkers to fire simultaneously. Six language layers already carry per-mode `(setq-local lsp-diagnostics-provider :none)` workarounds. Add a layer variable `syntax-checking-lsp-diagnostics-provider` (values `:flycheck` / `:flymake` / `:none` / `nil`; default `nil` meaning hands-off). When non-nil and the lsp layer is co-loaded, set `lsp-diagnostics-provider` inside a `(with-eval-after-load 'lsp-mode ...)` block in `config.el`. This centralizes a decision that is currently made inconsistently across language layers.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:70-76 — user has the lsp layer enabled with `lsp-modeline-diagnostics-scope ':file`
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/config.el — no variable exists to configure interaction with LSP diagnostics; all 46 lines are topology/display variables
- /Users/jlipworth/.emacs.d/layers/+tools/lsp/config.el — lsp config.el has no `lsp-diagnostics-provider` variable either; the lsp layer does not coordinate with syntax-checking
- /Users/jlipworth/.emacs.d/layers/+lang/go/funcs.el:80-84, +lang/typescript/funcs.el:52, +lang/javascript/funcs.el:58, +frameworks/vue/funcs.el:49, +frameworks/svelte/funcs.el:49, +frameworks/react/funcs.el:50 — six language layers already set `lsp-diagnostics-provider :none` locally as workarounds, proving the duplicate-diagnostic problem is real and solved ad hoc at per-language level rather than centrally
- /Users/jlipworth/.emacs.d/layers/+tools/eglot/packages.el:24-36 — eglot layer explicitly declares flycheck-eglot, showing LSP-checker coordination is handled per-LSP-client in the repo

### LOW · bug · effort S — flycheck-copy-errors-as-kill (SPC e y) undocumented in README key-binding table

_status: confirmed · deliverable: issue_

The SPC e y binding is wired at packages.el:57 but has no entry in the README table. Add a row `| ~SPC e y~ | copy errors at point to kill ring |` to the key-binding table. Also upstream this.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/packages.el:57 — `"ey" #'flycheck-copy-errors-as-kill` is bound via `spacemacs/set-leader-keys`
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/README.org:186-198 — the key-binding table lists SPC e b/c/d/h/l/L/s/S/v/x and SPC t s but has no SPC e y row

### LOW · gap · effort M — No helm-flycheck integration despite user using helm as completion framework

_status: adjusted · deliverable: issue_

There is no helm-based flycheck error browser in the syntax-checking layer. The auditor's specific recommendation of `helm-flycheck` (yasuyk/helm-flycheck) is problematic: that package was archived around 2017 and is likely not on MELPA. A more viable path is using the `helm-occur` / `helm-flycheck` fork that is still available, or more practically implementing a thin `spacemacs/helm-flycheck-errors` wrapper using `helm-build-sync-source` over `flycheck-current-errors`. The lsp layer already covers project-level diagnostics via `helm-lsp-diagnostics`. The gap is real but the effort estimate should be M and the recommended package needs vetting before implementation. The compleseus evidence is a key binding comment, not a package declaration — the original evidence description was imprecise on that point.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:36-37 — user has the helm layer enabled with a :variables form
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/packages.el:28-32 — no helm-flycheck or any helm integration package declared
- /Users/jlipworth/.emacs.d/layers/+completion/compleseus/packages.el:123 — keybinding comment reads `("M-g f" . consult-flymake) ;; Alternative: consult-flycheck`, showing consult-flycheck is known but not wired up for compleseus users either
- /Users/jlipworth/.emacs.d/layers/+tools/lsp/funcs.el:152 — the lsp layer already wires `SPC p E` to `helm-lsp-diagnostics` when helm is active, which addresses project-wide LSP diagnostics but not per-buffer flycheck error browsing

### LOW · modernization · effort S — All three .el files declare lexical-binding: nil

_status: confirmed · deliverable: issue_

Change all three file headers to `lexical-binding: t`. The files use no dynamic-binding constructs: the two functions in funcs.el are plain interactive commands with no special variable captures; config.el uses `spacemacs|defc` macros and `defvar`; packages.el uses `use-package` and `spacemacs/set-leader-keys`. Enabling lexical binding is a free performance and correctness improvement and matches the repo's direction. Test after the change with `make -C tests/core test`.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/packages.el:1 — `;;; packages.el ... -*- lexical-binding: nil; -*-`
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/config.el:1 — `;;; config.el ... -*- lexical-binding: nil; -*-`
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/funcs.el:1 — `;;; funcs.el ... -*- lexical-binding: nil; -*-`
- /Users/jlipworth/.emacs.d/layers/+lang/python/layers.el:1 — gold-standard reference layer uses `lexical-binding: t`

### LOW · gap · effort L — No ERT tests for any layer logic

_status: confirmed · deliverable: issue_

Create `/Users/jlipworth/.emacs.d/tests/layers/+checkers/syntax-checking/` with at minimum: (1) a test that `spacemacs/enable-flycheck` adds the given mode to `flycheck-global-modes` when `syntax-checking-enable-by-default` is t; (2) a test that `spacemacs/toggle-flycheck-error-list` toggles correctly using a mock for `flycheck-get-error-list-window`. The python layer test structure at tests/layers/+lang/python/ is the template to follow.

**Evidence:**
- `ls /Users/jlipworth/.emacs.d/tests/layers/` — only `+distribution` and `+lang` subdirectories exist; no `+checkers` directory
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python — python layer has a test suite (the stated gold standard)
- Upstream also has no tests for this layer (consistent with the upstream delta being zero)

## Additional gaps caught in verification

- **(low/gap)** lsp-ui-sideline provides overlapping tooltip functionality but syntax-checking README does not document the interaction — When both `lsp` and `syntax-checking` are co-loaded, users get two competing tooltip systems: `flycheck-pos-tip` (enabled by default) and `lsp-ui-sideline` (enabled by default in the lsp layer). The README for syntax-checking gives no guidance on disabling one or the other to avoid double tooltips. Add a note in the Tooltip Pop-up section advising users who have the lsp layer to consider setting `syntax-checking-enable-tooltips nil` since `lsp-ui-sideline` already shows error messages inline. Effort is S (README-only change).
- **(low/bug)** syntax-checking--buffer-config uses value of window-position/width/height at definition time, not at display time — The `defvar` for `syntax-checking--buffer-config` on config.el:108 constructs a `list` form whose `:position`, `:width`, and `:height` values are the values of the layer variables at Emacs load time. If a user customizes those variables via `:variables` in their .spacemacs, the variables are set before layers load, so the captured values should be correct in practice. However, the list construction is fragile: if a user later `setq`s `syntax-checking-window-position` (e.g. in `user-config`), `syntax-checking--buffer-config` is not updated because it was evaluated once. The config should either be a function or the popwin push should quote the variable names symbolically so popwin reads them dynamically. Low severity because `:variables` usage is the standard pattern and the bug only manifests with runtime re-assignment.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

