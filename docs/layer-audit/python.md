# Layer audit: `python`  (`python`)

**Maturity:** `mature`  
**Upstream delta:** n/a

Confirmed mature and byte-for-byte identical to syl20bnr/develop: git diff --numstat across the entire layer directory returns 0 changed files. All advanced features (anaconda+lsp backends, yapf/black/ruff/lsp formatters, pytest+nose cross-runner dispatch with treesit-aware pytest-at-point, REPL/code-cells, dap debugging, and the pyvenv/pyenv/pipenv/poetry/uv/pet env spread) originate upstream; there are no fork-local regressions and no upstream patches the fork is missing. Remaining items are ecosystem-modernization gaps shared with upstream: no python-ts-mode remap (bindings target python-mode not python-base-mode), lsp limited to pylsp/pyright/ngl (no basedpyright option, no ruff LSP linter), lexical-binding nil in three files, a latent free-variable bug in a rarely-hit fallback, obsolete point-at-bol/eol aliases, and missing unit coverage of the custom test/env logic. None changes the mature rating.

## Findings

### MEDIUM · enhancement · effort M — lsp backend supports only pylsp/pyright/ngl; no basedpyright or ruff LSP

_status: adjusted · deliverable: both_

The enhancement is real: the layer offers no basedpyright option and no way to run ruff as an LSP linter (only as a formatter). Pyright does no linting, so an lsp+pyright user gets zero ruff diagnostics in-editor. Approach: extend the funcs.el:94-98 pcase to add a `basedpyright case surfacing lsp-pyright-langserver, document it in README and the config docstring, and add a layer option to register ruff's `ruff server` as a secondary lsp client. NOTE two corrections to the original audit: (1) the dispatch already supports a third value `ngl` (next-gen pyright langserver) which the audit omitted and which the config docstring fails to document; (2) the audit's user-specific evidence is UNVERIFIABLE -- no .spacemacs dotfile exists at any standard path (/Users/jlipworth/.spacemacs, ~/.spacemacs.d/init.el, etc. all absent), so the cited '.spacemacs:131-133' (pyright+ruff) and '.spacemacs:817-819' (commented lsp-ruff block) could not be confirmed, and the README line citations (144-147, 118-139) are out of range since README.org is only 121 lines. This is therefore a general layer enhancement, not a confirmed user-tailored fix.

**Evidence:**
- funcs.el:94-98 pcase dispatch handles `pylsp (lsp-pylsp), `pyright (lsp-pyright), `ngl (lsp-pyright), with `_ -> (user-error "Adjust value of `python-lsp-server'")
- config.el:33-35 python-lsp-server docstring lists only pylsp and pyright (does NOT mention the ngl value that the code actually accepts)
- README.org:72,73,75 table documents pylsp, pyright, ngl -> pyright-langserver
- lsp-pyright upstream exposes lsp-pyright-langserver to select basedpyright (https://github.com/emacs-lsp/lsp-pyright)
- No ruff LSP client registration anywhere in the layer; ruff appears only as ruff-format formatter in packages.el

### MEDIUM · modernization · effort L — No tree-sitter (python-ts-mode) support; all bindings/hooks target python-mode only

_status: confirmed · deliverable: both_

Confirmed shared upstream gap. If python-mode is remapped to python-ts-mode, the layer's keybindings, backend, formatter and test setup do not activate because they bind 'python-mode rather than the shared parent 'python-base-mode (only the pet package uses python-base-mode). Implementation: add a python-tree-sitter layer variable that adds (python-mode . python-ts-mode) to major-mode-remap-alist and installs the grammar; switch set-leader-keys-for-major-mode / add-hook targets to 'python-base-mode (or register both modes); update spacemacs|define-jump-handlers and the window-purpose config. Best pursued upstream-first. Severity medium retained.

**Evidence:**
- packages.el contains 26 quoted 'python-mode references (leader keys, hooks, jump handlers) and only 1 python-base-mode reference (the pet package at line 73)
- grep: python-ts-mode appears 0 times in packages.el; no major-mode-remap-alist entry anywhere in the layer
- config.el:24 (spacemacs|define-jump-handlers python-mode)
- funcs.el:298 and funcs.el:345 both gate on (fboundp 'python-pytest--use-treesit-p), so treesit is half-acknowledged
- Whole layer dir is 0-diff vs syl20bnr/develop, so this is a shared upstream gap, not a fork regression

### MEDIUM · cleanup · effort S — packages.el/config.el/funcs.el use lexical-binding: nil

_status: confirmed · deliverable: issue_

Confirmed. Three of four files declare lexical-binding: nil while layers.el already uses t. Flip the three headers to t, byte-compile, and fix any genuine dynamic-scope reliance (the (let ((python-mode-hook nil)) ...) idiom remains valid under lexical binding). Validate with the repo's headless-config-validation skill. Candidate fork-local improvement or upstream PR. Severity medium is defensible given it both masks bugs and is the modern default.

**Evidence:**
- Line-1 header check: packages.el -> lexical-binding: nil; config.el -> nil; funcs.el -> nil; layers.el -> t (the lone file using t)
- funcs.el:568 free variable `msg` is exactly the class of bug lexical binding catches at compile time

### LOW · bug · effort S — Free variable `msg` in spacemacs/python-shell-send-block fallback path

_status: confirmed · deliverable: issue_

Confirmed real latent bug. In the fallback branch (old python.el lacking python-shell-send-block), `msg` is passed to python-shell-send-region but never bound. Fix: replace `msg` with t (or nil) per the MSG arg of python-shell-send-region, or delete the dead fallback since modern python.el always provides python-shell-send-block. Present upstream too (0-diff layer). Low severity correct because the branch is rarely reached on current Emacs.

**Evidence:**
- funcs.el:561 (python-shell-send-region beg end nil msg t) -- the enclosing let* (funcs.el:557-560) binds only beg and end, never msg
- grep confirms no (defvar msg ...) or other binding of msg in funcs.el (count 0)
- Branch reached only when (fboundp 'python-shell-send-block) is nil (funcs.el:554 prefers the builtin); errors void-variable when hit, and is a compile error under lexical-binding

### LOW · cleanup · effort S — Obsolete point-at-bol / point-at-eol instead of pos-bol / pos-eol

_status: confirmed · deliverable: issue_

Confirmed. Replace point-at-bol/point-at-eol with pos-bol/pos-eol (Emacs 29+) in spacemacs/python-shell-send-line and spacemacs/python-shell-send-with-output. Mechanical, matches the fork's recent modernization pattern (commit 63100e0d). Identical upstream.

**Evidence:**
- grep -n point-at-bol/point-at-eol in funcs.el returns lines 624, 625, 654, 655
- Aliases obsolete since Emacs 29; emit byte-compiler warnings

### LOW · modernization · effort M — Default backend anaconda-mode is effectively unmaintained

_status: confirmed · deliverable: md_

Reasonable roadmap item. Keep anaconda for no-lsp users but emit a deprecation hint when python-backend resolves to anaconda and document pylsp/basedpyright as recommended. Low priority. md deliverable appropriate.

**Evidence:**
- config.el:20-23 python-backend defaults to nil -> resolves to anaconda unless lsp layer used (docstring confirms)
- packages.el wires anaconda-mode and company-anaconda first-class
- README.org documents anaconda-mode startup-failure workarounds

### LOW · gap · effort M — Enumerated funcs.el test/env logic has no unit tests (only functional smoke tests exist)

_status: adjusted · deliverable: issue_

Adjusted. There ARE functional tests in layers-ftest.el (jump-handler registration), so the layer is not test-free. However the specific funcs.el logic the audit enumerates (cross-runner secondary-testrunner mapping, the user-error path in call-correct-test-function, runner-enabled-p with list vs symbol, breakpoint tracer selection) genuinely has no unit coverage. Add ERT unit tests for those functions and wire into the existing Makefile. Low severity because the logic is upstream-maintained and in production use.

**Evidence:**
- tests/layers/+lang/python/ contains init.el, layers-ftest.el, Makefile -- no unit test file
- layers-ftest.el DOES contain functional ert tests (jump-handler smoke tests), so 'essentially no unit tests' overstates the gap
- Untested non-trivial logic remains: cross-runner dispatch (funcs.el ~345-461), runner-enabled-p list-vs-symbol handling, pyenv-executable-find shim resolution, breakpoint tracer selection

## Additional gaps caught in verification

- **(low/cleanup)** config.el python-lsp-server docstring omits the `ngl` value the code accepts — The python-lsp-server defvar docstring lists only pylsp and pyright, but the dispatch in funcs.el also handles `ngl (next-generation pyright langserver) and the README table documents it. Update the config.el docstring to include `ngl so completion/help and the README stay consistent. Mechanical one-line fix. Identical upstream.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

