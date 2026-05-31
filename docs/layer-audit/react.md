# Layer audit: `react`  (`react`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer is a competent rjsx-mode-based React setup: it wires LSP/tide/tern backends, flycheck (eslint/standard), prettier/web-beautify with format-on-save, emmet (with jsx className already enabled at funcs.el:59), import-js, js-doc, yasnippet, smartparens and evil-matchit, and inherits the full javascript SPC m menu via set-keymap-parent to spacemacs-js2-mode-map (packages.el:84). It covers day-to-day React editing. It is held back from 'mature' by: (1) being built on rjsx-mode (js2-mode derivative, no TypeScript/TSX, no tree-sitter path); (2) a real react-backend bug - the user sets react-backend 'lsp at .spacemacs:178 but the dispatch ignores it and keys off javascript-backend (funcs.el:28), and react-backend is not even defined in config.el; (3) no tests. The layer files are byte-identical to upstream syl20bnr/develop - the fork has not advanced this layer, so all improvements are net-new (ideally upstream-bound) work rather than fork regressions. The audit's findings are substantially correct; its .spacemacs citations are accurate (verified the user does enable react+typescript with lsp backends and sets react-backend). The two main adjustments are minor: the modernization finding's note to 'add emmet jsx className' is redundant since it already exists, and the backend-pcase test suggestion is harder to isolate than implied.

## Findings

### HIGH · modernization · effort L — Layer is built on rjsx-mode; no tree-sitter (tsx-ts-mode / typescript-ts-mode) path and no TSX support

_status: adjusted · deliverable: both_

rjsx-mode handles only JS+JSX, not TS+TSX, the dominant React dialect. A best-in-class 2025 layer should offer an opt-in tree-sitter backend: add a layer variable (e.g. react-use-tree-sitter, default nil for back-compat); when enabled and (treesit-available-p), register tsx-ts-mode/typescript-ts-mode in auto-mode-alist for .jsx/.tsx with grammar auto-install guidance, replicating the existing rjsx hooks (add-node-modules-path, prettier/web-beautify, emmet, lsp-deferred, flycheck eslint, yasnippet) onto the *-ts-mode hooks. Factor the rjsx hook wiring into a mode-agnostic helper so both backends share it. ONE CORRECTION to the audit's implementation note: emmet-expand-jsx-className? is ALREADY set (funcs.el:59), so do not list it as new work. The core gap (no TSX, no tree-sitter) is genuine. Note this is an upstream-level limitation, not a fork regression - the layer is byte-identical to syl20bnr/develop.

**Evidence:**
- packages.el:34,68-116 the entire layer is anchored on rjsx-mode (a js2-mode derivative); every hook targets rjsx-mode-hook / rjsx-mode-local-vars-hook
- funcs.el:63-74 spacemacs//javascript-jsx-file-p only auto-enables rjsx for .js/.jsx files importing React; .tsx is not handled (no *-ts-mode references anywhere in the layer)
- rjsx-mode is js2-mode-based and cannot parse TypeScript; Emacs 29+ ships built-in tsx-ts-mode / typescript-ts-mode backed by tree-sitter-typescript which parse JSX and TSX
- user enables react + typescript both with backend 'lsp (/Users/jlipworth/GNU_files/.spacemacs:170-179), so TSX React code falls to the typescript layer with no React-specific affordances

### MEDIUM · bug · effort S — react-backend variable set by the user is ignored; backend dispatch keys off javascript-backend

_status: confirmed · deliverable: issue_

react-backend is undefined in the layer (config.el defines no such variable) yet the user sets it at .spacemacs:178, making it a silent no-op; the actual dispatch keys off javascript-backend (funcs.el:28,35). Both the README contract and the user's config are inconsistent with the code. Resolve by deciding the contract: (a) if React should follow the javascript layer, document that backend is inherited and remove react-backend from the user's block (README.org:35 already says backend comes from the javascript layer, supporting this reading); or (b) if React should be independently configurable, define react-backend in config.el with a sensible default like (or react-backend javascript-backend) and change react-setup-backend / react-setup-company to pcase on react-backend. NOTE: this mirrors upstream exactly (files are byte-identical to syl20bnr/develop), so option (a) is the lower-risk fix and could flow upstream; the user-facing confusion is real and worth a docs/config clarification at minimum.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:177-178 the user writes (react :variables react-backend 'lsp) - confirmed via Read and rg
- funcs.el:26-31 spacemacs//react-setup-backend dispatches with (pcase javascript-backend ...) and never reads react-backend
- funcs.el:33-36 spacemacs//react-setup-company likewise branches on javascript-backend (eq javascript-backend 'tide)
- there is NO config.el variable defining react-backend; the layer config.el (read in full) contains only (spacemacs|define-jump-handlers rjsx-mode), so react-backend is an undefined symbol the user is setting as a no-op
- it only works for this user by coincidence because they also set javascript-backend 'lsp at .spacemacs:164

### MEDIUM · gap · effort M — No tests for the layer; well below the python gold standard

_status: confirmed · deliverable: both_

Add tests/layers/+frameworks/react/ with an ERT suite mirroring tests/layers/+lang/python/. Highest-value cases: (1) spacemacs//javascript-jsx-file-p returns non-nil for a buffer containing `import React from 'react'` and nil when that text is inside a string/comment (explicit nth-3/nth-4 ppss handling, easy to regress); (2) the layer defconst react-packages contains the expected package set. Note the backend-pcase test the audit lists is less tractable in isolation since react-setup-backend dispatches into cross-layer setup fns (spacemacs/tern-setup-tern, spacemacs//tide-setup) - the jsx-file-p regex test and the defconst test are the cleaner starting points. Provide a Makefile target consistent with the python layer so it runs in CI. Real gap, though it mirrors upstream (upstream ships no react tests).

**Evidence:**
- No tests/layers/+frameworks directory exists (verified: framework_tests_present=0; only +distribution and +lang test dirs exist)
- tests/layers/+lang/python exists with init.el, layers-ftest.el, Makefile (python_tests_present=1; CLAUDE.md references make -C tests/layers/+lang/python test)
- funcs.el has non-trivial pinnable logic: spacemacs//javascript-jsx-file-p (funcs.el:63-74, magic-mode regex + nth 3/nth 4 syntax-ppss string/comment guard) and the backend pcase (funcs.el:26-31)

### LOW · cleanup · effort M — Legacy/abandoned dependencies: tern and web-beautify backends still first-class

_status: confirmed · deliverable: issue_

tern and web-beautify are dead weight for a modern React workflow. Demote them: keep selectable for back-compat but document lsp as the default backend and prettier as the default formatter (the user already chooses both - .spacemacs:164,165). Trim README's tern section to a short 'legacy' note and de-emphasize the .jsbeautifyrc block. Mostly docs + defaults; do not delete code paths. Note this mirrors upstream exactly (byte-identical to syl20bnr/develop), so the change ideally flows upstream.

**Evidence:**
- packages.el:36,125-126 tern is wired (react/post-init-tern adds rjsx-mode to tern--key-bindings-modes) and funcs.el:29 dispatches to spacemacs/tern-setup-tern
- README.org:156-165 documents a full tern keybinding table; README.org:69-97 still recommends a .jsbeautifyrc with e4x:true (tern_readme=1, jsbeautifyrc_readme=1)
- packages.el:37,128-131 web-beautify offered as a formatter alongside prettier-js (packages.el:118-120)
- tern unmaintained since ~2018, superseded by LSP; js-beautify rarely used for React vs prettier

### LOW · gap · effort M — No DAP/debug or test-runner integration for React

_status: confirmed · deliverable: md_

A mature React layer could offer (a) DAP debugging via dap-mode with node/chrome adapters hooked into rjsx (and any future ts modes), and (b) a Jest runner under an SPC m t prefix to run/watch the test at point or file. Wire via post-init hooks gated on the relevant layers being present and declare the leader-key prefixes. Forward-looking enhancement, not a defect; matches upstream (upstream react layer also lacks these). The audit's evidence reference to 'me/eval and ms/skewer prefix' is accurate - both are declared at packages.el:90 and :107 respectively.

**Evidence:**
- react-packages (packages.el:24-38) lists no dap-mode and no jest/mocha runner (verified dap and jest absent from packages.el)
- the rjsx :config block declares me/eval (packages.el:90) and ms/skewer (packages.el:107) prefixes but nothing for debug or running component tests
- the javascript layer it inherits from provides dap support, but no React-specific test-runner workflow is wired

## Additional gaps caught in verification

- **(low/cleanup)** Layer is byte-identical to upstream syl20bnr/develop; the fork has not advanced it (contradicts audit's 'could not diff' caveat) — This is not a defect but a scoping observation the audit's upstream_delta got tentative about: it said it 'could not complete a byte-level diff.' The diff CAN be completed and shows zero fork divergence in this layer. Any improvement (tree-sitter backend, tests, tern/web-beautify demotion) should be treated as net-new work, ideally contributed upstream rather than carried as a fork patch, since the fork tracks upstream cleanly here. No code change required for this item; it is context that sharpens the other findings' framing.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

