# Layer audit: `javascript`  (`+lang/javascript`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the underbuilt rating. The layer has only 6 defvar configuration points vs. the Python layer's 25. All nine findings hold up under code review. The js-ts-mode gap is confirmed real on Emacs 30.2 (fboundp returns t). dap-node is genuinely absent from the DAP setup. The docstring bug at funcs.el:40 is present verbatim in both fork and upstream. Verification also uncovered that only javascript-backend has safe-local-variable registration; the other five layer variables (fmt-tool, import-tool, fmt-on-save, repl, lsp-linter) have none at all, meaning Finding 9 understates the scope of the problem.

## Findings

### HIGH · gap · effort M — No tree-sitter (js-ts-mode) support: layer is fully js2-mode-only

_status: confirmed · deliverable: issue_

Emacs 29+ ships js-ts-mode as a built-in tree-sitter major mode; Emacs 30 (the version in use here) enables it by default when grammars are present. The layer does nothing to enable or configure it: no mode association, no hook, no jump-handler registration, no DAP registration. A user on Emacs 30 with the JavaScript tree-sitter grammar installed will get no Spacemacs keybindings, no backend setup, and no npm-mode in js-ts-mode buffers because all hooks are wired to js2-mode-hook and js2-mode-local-vars-hook. Note: the auditor's suggestion to 'mirror how python layer handles python-ts-mode' is misleading — the Python layer also lacks python-ts-mode support, so js-ts-mode integration would be pioneering work for Spacemacs, not a mirror. Implementation: add a javascript-ts-mode-flavor variable ('js2 or 'treesit); when 'treesit, register js-ts-mode in :mode, define jump handlers, replicate all hooks and SPC m bindings, and add to spacemacs--dap-supported-modes.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:24-45: javascript-packages lists js2-mode, no js-ts-mode
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:106: :mode association only covers \.[cm]?js\' for js2-mode
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/config.el:26: spacemacs|define-jump-handlers js2-mode only
- emacs --batch --eval '(message "%s" (fboundp (quote js-ts-mode)))' returns t on Emacs 30.2
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-javascript.el:54: derived-mode-p check includes js-ts-mode so LSP activation-fn would fire, but Spacemacs hooks wired to js2-mode-hook would not
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/smartparens-20250612.1050/smartparens-javascript.el:55: smartparens already lists js-ts-mode in sp--javascript-modes

### HIGH · gap · effort S — No LSP-server selection variable: ts-ls is hardwired with no way to choose Deno or tsgo

_status: adjusted · deliverable: issue_

lsp-mode ships clients for ts-ls (priority -2, highest for JS), deno-ls (priority -5), and tsgo (priority -4, the Go-based TypeScript server). The layer exposes none of this choice. A user working on a Deno project or wanting to try tsgo must manually override lsp-enabled-clients with no layer-level support. The audit cited lsp-javascript.el:904 for ts-ls priority, but priority -2 is actually at line 872; line 904 is the :server-id declaration. The factual claim is correct. Add a javascript-lsp-server variable mirroring python-lsp-server, with a (put ... 'safe-local-variable #'symbolp) registration so it works per-project via .dir-locals.el.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/config.el:28-31: javascript-backend only distinguishes 'tern/'tide/'lsp, nothing beneath lsp
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-javascript.el:872: ts-ls registered with :priority -2 (server-id 'ts-ls at line 904)
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-javascript.el:1106-1108: deno-ls registered with :priority -5, :server-id 'deno-ls
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-javascript.el:1147-1150: tsgo registered with :priority -4, :server-id 'tsgo
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:35-37: python-lsp-server variable with pylsp/pyright options and (put ... 'safe-local-variable #'symbolp)

### MEDIUM · gap · effort S — Default formatter is web-beautify; no 'lsp value for javascript-fmt-tool

_status: adjusted · deliverable: issue_

The layer default 'web-beautify is a poor choice when lsp backend is active, since ts-ls has built-in document formatting. The more important gap is that there is no 'lsp option for javascript-fmt-tool: if a user wants to use lsp-format-buffer (ts-ls formatting) via SPC m = =, there is no layer-level way to wire it. The auditor's claim that SPC m = = is unbound is incorrect: the prettier and web-beautify sublayers both register SPC m == for their respective modes. The real gaps are: (1) no 'lsp value in the fmt-tool variable; (2) bad default that surprises lsp users; (3) error message typo 'web-beutify' at funcs.el:150. Fix: add 'lsp as a valid value handled by lsp-format-buffer in spacemacs/javascript-format, update defvar docstring, fix the typo.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/config.el:33-34: defvar javascript-fmt-tool defaults to 'web-beautify; docstring lists only 'web-beautify and 'prettier as valid values
- /Users/jlipworth/GNU_files/.spacemacs:163-168: user sets javascript-fmt-tool 'prettier and javascript-fmt-on-save t (no 'lsp value exists to set)
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/funcs.el:143-151: spacemacs/javascript-format pcase only handles 'prettier and 'web-beautify; any other value calls error with 'web-beutify' typo
- /Users/jlipworth/.emacs.d/layers/+tools/prettier/packages.el:30-32: prettier layer registers SPC m == for modes in spacemacs--prettier-modes
- /Users/jlipworth/.emacs.d/layers/+tools/web-beautify/packages.el:30-31: web-beautify layer registers SPC m == for modes in spacemacs--web-beautify-modes
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:48-56: python-formatter includes 'lsp option

### MEDIUM · bug · effort S — DAP setup loads dap-firefox and dap-chrome but never dap-node, ignoring Node.js debugging

_status: confirmed · deliverable: issue_

spacemacs//javascript-setup-lsp-dap at funcs.el:63-66 only requires dap-firefox and dap-chrome. dap-node.el and dap-js.el exist in the installed dap-mode package but are never loaded. A Node.js developer using M-x dap-debug will not see 'Node Run Configuration' or 'pwa-node' debug templates because dap-node was never required. Fix: in spacemacs//javascript-setup-lsp-dap, add (require 'dap-node) and optionally (require 'dap-js). Optionally add a javascript-dap-adapter variable. Also fix the 'elixir' docstring at funcs.el:40 (covered by Finding 5).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/funcs.el:63-66: spacemacs//javascript-setup-lsp-dap requires only dap-firefox and dap-chrome
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/dap-mode-20260523.830/dap-node.el:54-56: dap-register-debug-provider 'node and dap-register-debug-template 'Node Run Configuration both present
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/dap-mode-20260523.830/dap-js.el:66-68: dap-register-debug-provider 'pwa-node and unified JS template present
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:54-57: dap hook on js2-mode-local-vars-hook but dap-node never required
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+lang/javascript/funcs.el confirms same bug upstream

### MEDIUM · gap · effort L — No test-runner integration: zero SPC m t bindings, no jest/vitest/mocha support

_status: confirmed · deliverable: both_

No javascript-test-runner variable, no SPC m t prefix, and no integration with jest, vitest, or mocha. The user's setup (lsp+prettier+npm) strongly implies a project using one of these runners. The npm-mode 'nr' binding (SPC m n r) only runs arbitrary npm scripts and is not a substitute for test-specific keybindings like run-at-point, run-file, run-last. Approach: (1) add javascript-test-runner variable ('jest/'vitest/'mocha); (2) use compile-based approach or a MELPA package for the chosen runner; (3) bind SPC m t prefix consistently with other lang layers.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:24-45: no jest, mocha, vitest, or test-runner package in javascript-packages
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/config.el: no javascript-test-runner defvar
- grep -rn 'jest|vitest|mocha' layers/+lang/javascript/ returns no results
- grep -rn 'jest|test-runner' layers/+lang/react/ and layers/+lang/typescript/ also return no results
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:62-64: python-test-runner defvar with pytest/nose; put safe-local-variable

### MEDIUM · gap · effort S — javascript-repl not set in user's dotfile: user silently gets skewer (browser-based) not nodejs

_status: confirmed · deliverable: issue_

The user has nodejs-repl in additional-packages, indicating intent to use Node.js REPL. However, javascript-repl is not set in their layer variables, so it defaults to 'skewer. Since the nodejs-repl init function is guarded with (when (eq javascript-repl 'nodejs)), none of the SPC m s* keybindings for nodejs-repl are registered. The user would open a JS buffer, try SPC m s s or SPC m ', and get nothing. Their additional-packages entry is also redundant since nodejs-repl is already in the layer's package list. The layer README does document this variable (lines 254-273) but the skewer default is still a footgun for the common Node.js case. The layer should consider defaulting to 'nodejs or at minimum warn when the nodejs-repl package is loaded but javascript-repl is 'skewer.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:163-168: javascript block sets backend/fmt-tool/fmt-on-save/import-tool but no javascript-repl
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/config.el:42-43: default javascript-repl is 'skewer
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:198-199: javascript/init-nodejs-repl guarded by (when (eq javascript-repl 'nodejs))
- /Users/jlipworth/GNU_files/.spacemacs:876: nodejs-repl in dotspacemacs-additional-packages (redundant since layer already owns it, but signals user intent)

### LOW · bug · effort S — funcs.el:40 docstring says 'elixir DAP integration' — copy-paste error from Elixir layer

_status: confirmed · deliverable: issue_

Trivial one-line fix: change the docstring from 'Conditionally setup elixir DAP integration.' to 'Conditionally setup JavaScript DAP integration.' Misleading for describe-function output and code reading.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/funcs.el:39-40: (defun spacemacs//javascript-setup-dap () "Conditionally setup elixir DAP integration.")
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+lang/javascript/funcs.el line 40 is identical — same bug upstream

### LOW · gap · effort M — No layer-level ERT tests: zero functional tests exist for the JavaScript layer

_status: confirmed · deliverable: issue_

The Python layer has ERT functional tests (tests/layers/+lang/python/layers-ftest.el) verifying pyvenv activation, pytest runner discovery, and interpreter detection. The JavaScript layer has none. A minimal test suite should verify: (1) js2-mode activates on .js/.mjs/.cjs files; (2) the correct backend setup function is called for each value of javascript-backend; (3) npm-mode keybindings are registered. Structure: mirror tests/layers/+lang/python/ with tests/layers/+lang/javascript/layers-ftest.el and a Makefile.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*javascript*' returns no results
- ls /Users/jlipworth/.emacs.d/tests/layers/+lang/ shows only python/ subdirectory
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/layers-ftest.el: exists with pytest/pyvenv integration tests
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/Makefile: provides test target

### LOW · modernization · effort S — safe-local-variable registration uses deprecated cons-based add-to-list style, and only covers javascript-backend

_status: adjusted · deliverable: issue_

Two problems, not one: (1) javascript-backend uses the obsolete cons-cell enumeration style in packages.el:111-113 rather than the modern (put ... 'safe-local-variable #'symbolp); (2) the other five layer variables — javascript-fmt-tool, javascript-repl, javascript-import-tool, javascript-fmt-on-save, javascript-lsp-linter — have zero safe-local-variable registration anywhere, meaning they cannot be safely set in .dir-locals.el without triggering Emacs's 'risky local variable' warning. Fix: move all registrations to config.el using (put 'javascript-backend 'safe-local-variable #'symbolp) etc. for each variable, replacing the packages.el dolist entirely.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:111-113: dolist over '(lsp tern tide) adding cons cells to safe-local-variable-values
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/config.el: only javascript-backend registered; javascript-fmt-tool, javascript-repl, javascript-import-tool, javascript-fmt-on-save, javascript-lsp-linter have NO safe-local-variable registration at all
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:33,37,64,90: (put 'var 'safe-local-variable #'symbolp) for four different variables — the modern idiomatic form

## Additional gaps caught in verification

- **(low/bug)** funcs.el:150 has a 'web-beutify' typo in the formatter error message — The catch-all error clause in spacemacs/javascript-format contains a misspelling: 'web-beutify' instead of 'web-beautify'. This is distinct from the docstring bug at funcs.el:40 (which says 'elixir') and is buried inside the error message string, but it will mislead any user who hits the error branch. One-character fix: change 'web-beutify to 'web-beautify at funcs.el:150.
- **(medium/gap)** npm-mode and all other SPC m keybindings are not registered for js-ts-mode (scope clarification for Finding 1) — Beyond the tree-sitter gap in Finding 1, it is worth calling out explicitly that even if a user manually enables js-ts-mode, they will lose: npm-mode (SPC m n* keybindings), add-node-modules-path (so per-project eslint/prettier binaries won't be found), flycheck (syntax checking), imenu-extras, evil-matchit, and company completions — all wired exclusively to js2-mode-hook. This is separable from the 'should the layer support js-ts-mode as a first-class option' question: even a bridging workaround (one line adding js-ts-mode-hook to each add-hook call) would unblock users on Emacs 30 who land in js-ts-mode unexpectedly.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

