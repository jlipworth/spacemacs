# Layer audit: `latex`  (`+lang/latex`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer covers the AUCTeX core well: build, preview, folding, reftex, evil-tex, company backends, and pdf-tools integration. All five layer files are identical to upstream syl20bnr/develop. The key gaps — no lsp-latex keybindings, no formatter integration, no eglot option, dead code, no test coverage — are shared with upstream and not local regressions. The rating stays adequate; the layer is functional but underbuilt for users running texlab who expect LSP protocol feature parity with other layers.

## Findings

### HIGH · gap · effort M — lsp-latex commands loaded but none are bound to SPC m

_status: confirmed · deliverable: issue_

The layer requires lsp-latex and activates texlab via lsp-deferred, but exposes zero texlab-specific LSP protocol commands via the SPC m menu. The user cannot trigger texlab's build (lsp-latex-build), forward-search-to-PDF (lsp-latex-forward-search), clean build artifacts, cancel an ongoing build, or navigate the dependency graph — all via the LSP wire with async progress reporting. These should be added inside latex/init-lsp-latex under a guard. Suggested SPC m bindings: SPC m L b (lsp build), SPC m L f (forward search), SPC m L ca (clean aux), SPC m L cA (clean artifacts), SPC m L x (cancel build), SPC m L g (dependency graph). Use spacemacs/declare-prefix-for-mode 'latex-mode "mL" "lsp-texlab" to document the prefix in which-key.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/latex/funcs.el:52-56 — spacemacs//latex-setup-backend only calls (require 'lsp-latex) and (lsp-deferred); no keybindings
- /Users/jlipworth/.emacs.d/layers/+lang/latex/packages.el:267-269 — latex/init-lsp-latex is literally (use-package lsp-latex :defer t) with no keybinding declarations
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-latex-20251104.1507/lsp-latex.el:1199,1277,1288,1300,1312,1333,1349 — lsp-latex-build, lsp-latex-forward-search, lsp-latex-clean-auxiliary, lsp-latex-clean-artifacts, lsp-latex-change-environment-most-inner, lsp-latex-show-dependency-graph, lsp-latex-cancel-build are all public interactive commands with zero layer exposure
- /Users/jlipworth/GNU_files/.spacemacs:70 — lsp layer is active, so latex-backend auto-resolves to 'lsp via config.el:48 logic

### HIGH · gap · effort M — No formatter integration: no latexindent/tex-fmt variable, no format-on-save

_status: confirmed · deliverable: issue_

Mirroring the python layer pattern, add a latex-formatter variable (options: nil, 'latexindent, 'tex-fmt, 'texlab) and a boolean latex-format-on-save in config.el. In funcs.el add spacemacs//latex-setup-formatter that: (a) for texlab sets lsp-latex-latex-formatter to "texlab" and hooks lsp-format-buffer on save; (b) for latexindent or tex-fmt hooks a shell call on save. Wire into latex/init-auctex config section and add a SPC m = keybinding for on-demand format. Note: lsp-latex-latex-formatter already defaults to "texlab" in the installed package, so the layer not touching it means users get texlab formatting passively via lsp-format-buffer, but there is no layer-managed keybinding or format-on-save hook.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/latex/config.el:1-94 — zero defvar for latex-formatter or latex-format-on-save; confirmed by reading file
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:48-60 — python layer provides python-formatter (yapf/black/ruff/lsp) and python-format-on-save as first-class variables
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-latex-20251104.1507/lsp-latex.el:907 — lsp-latex-latex-formatter defcustom accepts 'texlab' or 'latexindent'; the layer does not surface or configure this variable

### MEDIUM · gap · effort M — No eglot backend option for users not using lsp-mode

_status: adjusted · deliverable: issue_

The layer hard-codes lsp-mode as the only LSP client option. Adding 'eglot as a third value for latex-backend (alongside 'lsp and 'company-auctex) would bring the latex layer to parity with fsharp in terms of LSP client choice. Implementation: add 'eglot option in config.el:48 docstring, add spacemacs//latex-setup-eglot in funcs.el mirroring fsharp/funcs.el:35-39, and add (eglot :location built-in) toggled on the new value. The original finding cited rust layer (packages.el:86) as the reference — this is wrong; rust has no eglot support. The correct reference is fsharp.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/latex/config.el:48 — latex-backend accepts only 'lsp or 'company-auctex; no 'eglot value
- /Users/jlipworth/.emacs.d/layers/+lang/fsharp/config.el:26 and packages.el:27 — fsharp layer is the correct reference layer showing the eglot backend pattern with (eglot-fsharp :toggle (eq fsharp-backend 'eglot))
- /Users/jlipworth/.emacs.d/layers/+lang/fsharp/funcs.el:38 — fsharp uses ('eglot (eglot-ensure)) dispatch pattern
- Texlab works with eglot via (add-to-list 'eglot-server-programs '((LaTeX-mode tex-mode) "texlab")) since Emacs 29 built-in eglot

### LOW · gap · effort S — latex-build-command "LaTeX" suppresses auctex-latexmk despite latexmk on PATH — silent LSP pipeline divergence undocumented

_status: adjusted · deliverable: issue_

The user's choice to set latex-build-command "LaTeX" is intentional and explicitly shown as a documented configuration option in the layer README (README.org:163-168). This is not a bug. The real gap is that the README does not document how latex-build-command interacts with the LSP backend: when latex-backend is 'lsp, the build engine is configured via lsp-latex-build-executable / lsp-latex-build-args independently of latex-build-command, so the two pipelines diverge silently (the AUCTeX SPC m b pipeline uses plain LaTeX; the lsp-latex-build pipeline uses whatever texlab is configured with). The README should document this interaction. Severity is low because this is a documentation gap, not a functional regression.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:122-123 — latex-build-command "LaTeX" is explicitly set
- /Users/jlipworth/.emacs.d/layers/+lang/latex/packages.el:28 — auctex-latexmk toggle is (string= "LatexMk" latex-build-command); package is disabled
- /Users/jlipworth/.emacs.d/layers/+lang/latex/README.org:163-168 — the README explicitly documents setting latex-build-command to "LaTeX" as the way to bypass latexmk
- latexmk is on PATH at /Users/jlipworth/texlive/2026/bin/universal-darwin/latexmk

### LOW · cleanup · effort S — Dead code: latex//build-sentinel defined but permanently commented out

_status: confirmed · deliverable: issue_

latex//build-sentinel (lines 79-82) is unreachable: the set-process-sentinel call that would register it (lines 74-77) is permanently commented out, and the active code path at lines 69-73 chose TeX-command returning nil instead. Either delete the dead sentinel and its commented caller, or implement a proper process-sentinel approach. Option (a) is strongly preferred. Identical in upstream.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/latex/funcs.el:69-82 — latex/build (lines 69-73) uses TeX-command directly; lines 74-77 are the commented-out set-process-sentinel call; lines 79-82 define the orphaned sentinel function

### LOW · modernization · effort M — No tree-sitter (latex-ts-mode) integration or variable

_status: confirmed · deliverable: both_

A latex-ts-mode package exists on MELPA and uses the latex-lsp/tree-sitter-latex grammar. As of May 2025 the grammar is considered experimental. This fork could add it as opt-in via a latex-enable-tree-sitter boolean (defaulting to nil). Implementation: add (latex-ts-mode :toggle latex-enable-tree-sitter) to the package list, add a latex/init-latex-ts-mode that activates it for .tex files via major-mode-remap-alist, and keep AUCTeX hooks firing by mapping latex-ts-mode-hook to LaTeX-mode-hook. Default-off is appropriate until the grammar matures.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/latex/packages.el:24-45 — no tree-sitter package or ts-mode remap; confirmed by file read
- /Users/jlipworth/.emacs.d/layers/+lang/latex/config.el:1-94 — no latex-enable-tree-sitter variable

### LOW · gap · effort L — No test suite for the latex layer

_status: confirmed · deliverable: issue_

The layer has zero test coverage. The latex//autofill function (iterating nested environments checking membership in latex-nofill-env) has testable logic. A minimal test suite at tests/layers/+lang/latex/ following the python Makefile pattern would provide a safety net if formatter or LSP backend changes are made. Low urgency but important if the higher-severity findings above are acted on.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*latex*' returns no output
- /Users/jlipworth/.emacs.d/layers/+lang/latex/funcs.el:84-102 — latex//autofill and latex/auto-fill-mode are non-trivial logic that could be unit-tested

### LOW · gap · effort S — SyncTeX forward search not bound as a first-class SPC m key

_status: confirmed · deliverable: issue_

SyncTeX is enabled and the pdf layer integration sets pdf-sync-forward-display-action, but pdf-sync-forward-search (jump from tex buffer to matching PDF page+line position) is not bound to any SPC m key. Add SPC m V (or SPC m pv) for pdf-sync-forward-search and document it in the README. When the LSP backend is active, lsp-latex-forward-search (the texlab variant) should be preferred and is already covered under the larger finding 1.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/latex/packages.el:95 — SPC m v is bound to TeX-view; no binding for pdf-sync-forward-search
- /Users/jlipworth/.emacs.d/layers/+lang/latex/funcs.el:65 — pdf-sync-forward-display-action is configured when pdf layer is present, confirming SyncTeX infrastructure is live
- /Users/jlipworth/.emacs.d/layers/+lang/latex/packages.el:60,68 — TeX-source-correlate-start-server and TeX-source-correlate-mode are configured

## Additional gaps caught in verification

- **(low/bug)** SPC m iC binds org-ref-insert-cite-key without declaring org-ref/bibtex layer dependency — When latex-backend is 'lsp, packages.el:172 binds SPC m iC to org-ref-insert-cite-key. However, org-ref is owned by the bibtex layer (bibtex/packages.el:31), not the latex layer. If the user runs the lsp backend without the bibtex layer active, org-ref is not loaded and the binding silently calls an unresolved symbol. The fix is either: (a) add a (configuration-layer/layer-used-p 'bibtex) guard around the binding, or (b) declare (bibtex) as an optional dependency in layers.el when latex-backend is 'lsp. This is consistent with upstream behavior and affects any user with lsp backend who does not use the bibtex layer.

## Rejected by verifier (false positives)

- ~~lsp-latex is listed in dotspacemacs-additional-packages redundantly with layer package~~ — Rejected. Read the file: line 840 starts the custom-set-variables block with '(package-selected-packages ...). The dotspacemacs-additional-packages list (lines 220-228) does not include lsp-latex. The auditor confused the auto-generated Customize block with a user-maintained package list.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

