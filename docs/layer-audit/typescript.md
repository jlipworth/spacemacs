# Layer audit: `typescript`  (`+lang/typescript`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the underbuilt rating. All four source files are byte-for-byte identical to syl20bnr/develop, so every deficiency is upstream-shared. The layer has no tree-sitter mode support, no DAP debugging, no test runner, no REPL, a self-acknowledged bug in the tslint linter path, stale playground URL, and incomplete safe-local-variable declarations. Against the python or go layers it is thin. The only adjustment from the original assessment: the lsp-linter bug does not affect the user's eslint configuration and its severity drops to low for this install.

## Findings

### HIGH · gap · effort M — No tree-sitter mode support: typescript-ts-mode and tsx-ts-mode are ignored

_status: confirmed · deliverable: both_

Emacs 29+ ships `typescript-ts-mode` and `tsx-ts-mode` as built-in tree-sitter modes. The layer still pins everything to the third-party `typescript-mode` package and derives a bespoke `typescript-tsx-mode` from `web-mode`. A modernization adds a `typescript-ts-backend` variable (defaulting to `'treesit` when `(treesit-available-p)` and the grammar is installed), wires `typescript-ts-mode` and `tsx-ts-mode` to `.ts`/`.tsx` auto-mode-alist entries, propagates all existing hooks and keybindings to those modes via `spacemacs/add-to-hooks`, and gates the old `typescript-mode`/`web-mode` path behind the legacy case.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/packages.el:24-36: package list contains `typescript-mode` (the external package) and `web-mode`; neither `typescript-ts-mode` nor `tsx-ts-mode` appear anywhere in the file
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/packages.el:127-129: `(define-derived-mode typescript-tsx-mode web-mode ...)` — TSX is handled by wrapping web-mode, not the built-in tree-sitter tsx-ts-mode
- git -C /Users/jlipworth/.emacs.d log --oneline syl20bnr/develop -- layers/+lang/typescript/ shows no commit mentioning typescript-ts-mode or tsx-ts-mode
- md5 comparison of packages.el against syl20bnr/develop confirms fork is byte-for-byte identical: 40662639ab448e6f68966b9b31efb4c9

### HIGH · gap · effort M — DAP debugging entirely absent despite user enabling the dap layer

_status: confirmed · deliverable: issue_

Add `dap-mode` to `typescript-packages` as a conditional package (`:toggle (configuration-layer/layer-used-p 'dap)`). Implement `typescript/pre-init-dap-mode` following the javascript layer pattern: add `typescript-mode` to `spacemacs--dap-supported-modes`, and add a hook to call a new `spacemacs//typescript-setup-dap` that does `(require 'dap-node)` and optionally `(dap-node-setup)`. Bind `SPC m d` prefix analogously to the python layer.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/packages.el:24-36: `dap-mode` is absent from `typescript-packages`
- /Users/jlipworth/GNU_files/.spacemacs:84: `dap` layer is enabled in dotspacemacs-configuration-layers
- /Users/jlipworth/GNU_files/.spacemacs:170-175: typescript configured with `typescript-backend 'lsp` — prerequisite for dap-mode is met
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:28,54-57: sibling javascript layer adds `dap-mode` and calls `spacemacs--dap-supported-modes` and hooks `spacemacs//javascript-setup-dap`
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:30,136-139: python layer pattern for reference — `python/pre-init-dap-mode` hooks `spacemacs//python-setup-dap`

### MEDIUM · gap · effort M — No test-runner integration (jest/vitest) — complete gap relative to python layer

_status: confirmed · deliverable: issue_

Add optional support for running jest via `compile`. Minimally: add a `typescript-test-runner` variable (default `'jest`), a `spacemacs//typescript-run-test` function wrapping `compile` with the project-local jest binary (resolved via `add-node-modules-path`, already wired), and bind `SPC m t a` / `SPC m t t` following the python layer keybinding convention.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/packages.el:24-36: no jest, mocha, vitest, or test-runner package in the list
- grep for jest/test/mocha in funcs.el returns zero results
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:40-41,53: python layer ships `nose` and `python-pytest` with full `SPC m t` keybinding suite

### LOW · bug · effort S — Self-acknowledged bug in typescript/set-lsp-linter — tslint path is incomplete

_status: adjusted · deliverable: issue_

The tslint arm of `typescript/set-lsp-linter` (packages.el line 71) only registers `typescript-tslint` for `typescript-tsx-mode`, leaving `typescript-mode` (.ts files) without tslint when using the LSP backend. The eslint arm correctly registers for both modes. The audit characterizes this as affecting the eslint path, which is wrong — eslint works correctly. The real bug is a tslint-only regression. Fix: add `(flycheck-add-mode 'typescript-tslint 'typescript-mode)` to the tslint arm. The referenced go layer pattern (per-mode hook splitting) is not actually demonstrated in the go layer either, as go has only one mode; a simpler guard suffices.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/packages.el:69-77: `typescript/set-lsp-linter` — tslint arm (line 71) calls `flycheck-add-mode` only for `typescript-tsx-mode`, omitting `typescript-mode`; the TODO comment at lines 72-73 acknowledges the flaw
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/packages.el:74-75: eslint arm correctly adds `javascript-eslint` to BOTH `typescript-tsx-mode` AND `typescript-mode`
- /Users/jlipworth/GNU_files/.spacemacs:174: user sets `typescript-linter 'eslint` — the eslint path works correctly; user is NOT currently affected

### LOW · bug · effort S — Playground URL uses HTTP and outdated /Playground path

_status: confirmed · deliverable: issue_

Change the URL in `spacemacs/typescript-open-region-in-playground` from `http://www.typescriptlang.org/Playground#src=` to `https://www.typescriptlang.org/play#src=`. The `#src=` percent-encoded format remains supported. Update the docstring at line 118 to match.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/funcs.el:123: `(browse-url (concat "http://www.typescriptlang.org/Playground#src=" ...))` — uses HTTP, not HTTPS
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/funcs.el:118: docstring also uses the old http URL

### LOW · gap · effort S — Missing safe-local-variable property declarations on layer variables

_status: confirmed · deliverable: issue_

Add `(put 'typescript-backend 'safe-local-variable #'symbolp)`, `(put 'typescript-fmt-tool 'safe-local-variable #'symbolp)`, `(put 'typescript-linter 'safe-local-variable #'symbolp)`, and `(put 'typescript-lsp-linter 'safe-local-variable #'booleanp)` in config.el after each corresponding `defvar`. The current `spacemacs/typescript-safe-local-variables` helper in funcs.el (which populates `safe-local-variable-values` with specific cons pairs) should be replaced with the property-based approach, which does not require enumerating all valid values in advance and matches the python layer pattern.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/config.el:26-47: five `defvar` declarations — none have `put ... 'safe-local-variable` calls
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/funcs.el:133-137: `spacemacs/typescript-safe-local-variables` only adds specific `typescript-backend` values to `safe-local-variable-values` (enumerated pairs), not a predicate-based declaration
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/packages.el:135: called with `(spacemacs/typescript-safe-local-variables '(lsp tide))` — only covers the two known backends, not fmt-tool, linter, lsp-linter
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:33,37,64,90: python layer uses `(put 'python-backend 'safe-local-variable #'symbolp)` for each per-project variable

### LOW · gap · effort M — No REPL / send-to-process integration (ts-node/Bun/Deno)

_status: confirmed · deliverable: issue_

Add a `typescript-repl-tool` variable (default `'ts-node`, allowing `'deno` and `'bun`). Implement `spacemacs//typescript-start-or-switch-repl` using `comint-run` or `make-comint`. Register via `spacemacs/register-repl` and bind `SPC m '` to start/switch. Add minimal `SPC m s r` (send-region) and `SPC m s b` (send-buffer) bindings. Gate on `(executable-find typescript-repl-tool-binary)` to fail gracefully when no REPL binary is available.

**Evidence:**
- grep for comint/repl/REPL/inferior/ts-node/bun/deno in funcs.el returns zero results
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:384-428: python layer registers REPL via `spacemacs/register-repl` and provides send-region/buffer keybindings

### LOW · cleanup · effort S — README documents node.js v0.12.0 as minimum — a requirement from 2015

_status: confirmed · deliverable: issue_

Update README.org line 80 to state the actual minimum node version required by typescript-language-server (Node 18+). Remove the `0.12.x` workaround suggestion at line 151, which only applied to an ancient tsserver JSON-parse bug. Also remove or downgrade the tslint install instructions (README.org:88-91) since tslint has been deprecated since 2019 — the README itself acknowledges this on line 76-77 but still provides the install command.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/README.org:80: `You will need =node.js v0.12.0= or greater.`
- /Users/jlipworth/.emacs.d/layers/+lang/typescript/README.org:151: `Try node version 0.12.x if you get this error.`
- Node.js v0.12 reached EOL in 2016; typescript-language-server requires Node 18+

## Additional gaps caught in verification

- **(low/bug)** README documents SPC m n c (npm clean) but the binding is never defined — The README advertises `SPC m n c` for `npm-mode-npm-clean` but neither `typescript/post-init-npm-mode` in packages.el nor the javascript layer actually bind this key. The `npm-mode-npm-clean` function exists in npm-mode.el. Fix: add `"nc" 'npm-mode-npm-clean` to both the `typescript-mode` and `typescript-tsx-mode` keybinding blocks in `typescript/post-init-npm-mode`.
- **(low/gap)** typescript-mode and typescript-tsx-mode not registered with spacemacs--prettier-modes — TypeScript modes bypass the shared `spacemacs--prettier-modes` registration mechanism that prettier layer uses to set up `SPC m = =` and before-save hooks. Instead, typescript invokes prettier-js directly via `spacemacs/typescript-format`. While this works, it means future improvements to the prettier layer (e.g. new prettier options, prettier-mode integration) won't automatically apply to TypeScript. Fix: add `typescript-mode` and `typescript-tsx-mode` to `spacemacs--prettier-modes` in typescript/config.el or a `typescript/pre-init-prettier-js` function, and remove the redundant direct prettier call from `spacemacs/typescript-format`. This is a design inconsistency rather than a user-visible bug for the current setup.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

