# Layer audit: `ess`  (`+lang/ess`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the underbuilt rating. The layer ships a working minimum (REPL, tracebug, LSP via lsp-mode, flycheck, org-babel) but has no formatter, no polymode/quarto integration for .Rmd/.qmd, zero ERT tests, three files stuck at lexical-binding:nil, and a README that documents only one of two layer variables in its Options section. The ess-eval-visibly :variables usage works but is undocumented at the layer level. Nothing in the verification raised the overall assessment.

## Findings

### HIGH · gap · effort M — No formatter backend: styler, Air, and format-on-save are entirely absent

_status: adjusted · deliverable: issue_

The layer provides no code formatting at all. R has two viable formatter options: the mature styler CRAN package (wrappable via reformatter-define) and the posit-dev/air Rust binary (Feb 2025, fast, not yet registered in lsp-mode as of May 2026). The auditor's claim that Air can be wired as an LSP client via the existing lsp-mode plumbing is premature — lsp-r.el has no Air client. A practical implementation: add a new `ess-r-formatter` layer variable (values: nil, 'styler) and `ess-r-format-on-save` boolean, with a reformatter-define wrapping `Rscript -e 'styler::style_file(…)'`. Air could be tracked as a future option once lsp-mode or eglot ships an Air client. The styler path is actionable today.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/ess/config.el:28-32 — only two defvars (ess-r-backend, ess-assign-key); no ess-r-formatter or ess-format-on-save
- /Users/jlipworth/.emacs.d/layers/+lang/ess/packages.el:24-31 — packages list is company, flycheck, ess, ess-R-data-view, golden-ratio, org; no styler or air entry
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-r.el — lsp-mode only registers one R client (r-languageserver); Air is not yet a lsp-mode client, so an Air integration would require a separate reformatter-define or process wrapper, not an lsp-mode server switch
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:48-60 — python layer provides python-formatter variable toggling yapf/black/ruff/lsp and python-format-on-save boolean

### HIGH · gap · effort M — No polymode / quarto-mode integration for .Rmd and .qmd files

_status: confirmed · deliverable: issue_

R Markdown (.Rmd) and Quarto (.qmd) are the dominant literate-programming formats in the R ecosystem; the ESS layer ignores them. The layer handles .Rnw (Sweave) via auto-mode but not .Rmd. Add optional polymode and quarto-mode packages, toggleable via a new `ess-enable-polymode` variable (default t). Wire .Rmd to poly-markdown+r-mode (from polymode + poly-R) and .qmd to quarto-mode. The existing org pre-init hook (packages.el:127-129) demonstrates the pattern for optional format integration.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/ess/packages.el:24-31 — packages list has no polymode or quarto-mode entries
- /Users/jlipworth/.emacs.d/layers/+lang/ess/packages.el:54-80 — auto-mode-alist wires .Rnw to Rnw-mode but has no .Rmd or .qmd entries
- rg across /Users/jlipworth/.emacs.d/layers/ for polymode|quarto|rmarkdown|Rmd returned zero hits — no other layer covers this
- /Users/jlipworth/.emacs.d/layers/+lang/ess/README.org — no mention of Rmd or Quarto in any section (confirmed by full read)

### MEDIUM · gap · effort S — No ess-r-lsp-server selector variable or safe-local-variable property on ess-r-backend

_status: adjusted · deliverable: issue_

The auditor's claim that lsp-mode supports multiple R LSP servers is not accurate today — lsp-r.el only registers r-languageserver. However, the real gap is that ess-r-backend has no `(put 'ess-r-backend 'safe-local-variable #'symbolp)` declaration, unlike every backend variable in the python layer. This means .dir-locals.el overrides of ess-r-backend will trigger safe-variable prompts. Additionally, lsp-clients-r-server-command (in lsp-mode) could be customized per project if the layer exposed a thin wrapper, but it does not. The fix is minimal: add the safe-local-variable put for ess-r-backend, and document that lsp-clients-r-server-command can be set per project via .dir-locals.el.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/ess/config.el:28-29 — ess-r-backend defvar has no (put ... 'safe-local-variable #'symbolp) call
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-r.el:40-43 — lsp-mode currently registers only one R LSP client (r-languageserver); no second server to select between
- /Users/jlipworth/.emacs.d/layers/+lang/python/config.el:33,37 — python-backend has (put ... 'safe-local-variable #'symbolp); python-lsp-server also has this
- /Users/jlipworth/GNU_files/.spacemacs:158 — user sets ess-r-backend 'lsp as :variable but there is no way to override it per-project via .dir-locals.el

### MEDIUM · gap · effort S — ess-eval-visibly and other raw ESS package variables set via :variables without layer documentation

_status: adjusted · deliverable: issue_

ess-eval-visibly is a standard ESS defcustom, and the Spacemacs :variables mechanism (core-configuration-layer.el:1596, set-default) works reliably on any variable — so the 'fragile' characterization in the audit is too strong. The genuine gap is lack of documentation: ess-eval-visibly is not documented in the README, not wrapped with a layer defvar, and not validated. Similarly, ess-offset-continued, ess-nuke-trailing-whitespace-p, and ess-default-style are hardcoded in the packages.el :init block without documentation, preventing users from knowing they can be overridden. Promote ess-eval-visibly to a documented layer variable with a defvar wrapper in config.el, and document the other configurable settings in the README Options section.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:157-161 — user sets ess-eval-visibly nil as a :variables entry in the ess layer block
- /Users/jlipworth/.emacs.d/layers/+lang/ess/config.el — no defvar for ess-eval-visibly; two defvars only (ess-r-backend, ess-assign-key)
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/ess-20260526.1432/ess-custom.el:1863 — ess-eval-visibly is a defcustom with default 'nowait in the ESS package itself
- /Users/jlipworth/.emacs.d/layers/+lang/ess/packages.el:83-86 — four ESS variables hardcoded in :init block (ess-use-company, ess-offset-continued, ess-nuke-trailing-whitespace-p, ess-default-style) with no layer variable wrappers
- /Users/jlipworth/.emacs.d/layers/+lang/ess/README.org:67-73 — Options section mentions only ess-assign-key

### MEDIUM · gap · effort M — Zero layer tests: no ERT test suite exists for ESS

_status: confirmed · deliverable: issue_

The python layer has a tests/layers/+lang/python/ directory with a Makefile-driven ERT suite. The ESS layer has nothing. Create tests/layers/+lang/ess/ with init.el and layers-ftest.el testing: (1) spacemacs/ess-start-repl dispatches correctly per ess-language value (funcs.el:104-111), (2) spacemacs//ess-may-setup-r-lsp only calls lsp-deferred when ess-r-backend is 'lsp, (3) ess-assign-key wires ess-insert-assign when set. These are pure unit tests requiring no running R process.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*ess*' returned no results
- /Users/jlipworth/.emacs.d/tests/layers/+lang/ contains only a python/ directory
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/layers-ftest.el — python has ERT tests for interpreter detection and virtualenv behavior
- /Users/jlipworth/.emacs.d/layers/+lang/ess/funcs.el:104-111 — spacemacs/ess-start-repl dispatches on ess-language string; logic is trivially testable with ERT mocks

### LOW · cleanup · effort S — ESS Julia keybindings and company backend registered unconditionally even when julia layer handles .jl

_status: adjusted · deliverable: issue_

The auditor's claim that ess-julia-mode is 'being deprecated by ESS upstream' is not substantiated — ess-julia.el is present and functional in the May 2026 ESS package. There is no formal deprecation notice. The actual issue is narrower: the ESS layer registers Julia company backends and keybindings unconditionally, even when `julia-mode-enable-ess` is nil (the default) and ess-julia-mode is never active. This is dead-code-at-runtime waste rather than a conflict. A guard `(when (or (configuration-layer/layer-used-p 'ess) (not (configuration-layer/layer-used-p 'julia)))...)` is not needed — the julia layer already handles this via its own flag. At minimum, add a README note that users preferring modern Julia tooling should use the julia layer.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/ess/packages.el:34-37 — company-ess-julia-objects backend unconditionally registered for ess-julia-mode
- /Users/jlipworth/.emacs.d/layers/+lang/ess/packages.el:100 — spacemacs/ess-bind-keys-for-julia called unconditionally in :config block
- /Users/jlipworth/.emacs.d/layers/+lang/julia/config.el:29 — julia-mode-enable-ess defaults to nil, so the julia layer does NOT route .jl to ess-julia-mode by default
- /Users/jlipworth/.emacs.d/layers/+lang/julia/packages.el:38-42 — julia layer only adds ess-julia-mode to auto-mode-alist when julia-mode-enable-ess is non-nil
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/ess-20260526.1432/ess-julia.el — ess-julia-mode still ships in the current ESS package (20260526), not formally deprecated

### LOW · cleanup · effort S — config.el, packages.el, funcs.el use lexical-binding: nil

_status: confirmed · deliverable: issue_

Commit 55c9c2fe set all three non-layers.el ESS files to nil deliberately as a deferred task. The dolist loops in funcs.el:93 and packages.el:114,122 are safe for lexical binding. Flip all three files to `lexical-binding: t`. Verify with headless-config-validation after applying. This is the correct next step in what upstream already identified as pending work.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/ess/config.el:1 — lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+lang/ess/packages.el:1 — lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+lang/ess/funcs.el:1 — lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+lang/ess/layers.el:1 — lexical-binding: t (fixed by upstream c35a6712)
- git show 55c9c2fe: commit message explicitly says 'someone would need to examine and check whether dynamic binding is relied on' — nil was set intentionally to silence Emacs 31 warnings, not as a correctness choice
- git show c35a6712: only touched layers.el files across the repo

### LOW · gap · effort S — README Options section is minimal and does not document the full set of configurable behaviors

_status: adjusted · deliverable: issue_

ess-r-backend is mentioned briefly in the Install/LSP section (lines 60-64) but is not in the Options section and there is no variables summary table. ess-assign-key is the only entry in Options. Add a Configuration Variables table to the Options section listing all layer variables with their defaults and accepted values: ess-r-backend, ess-assign-key, and any new variables added per other findings. The auditor's claim that ess-r-backend is 'not documented at all' is slightly overstated, but the Options section gap is real.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/ess/README.org:67-73 — Options section contains only the ess-assign-key example (confirmed by full read)
- /Users/jlipworth/.emacs.d/layers/+lang/ess/README.org:59-65 — ess-r-backend IS mentioned in the Install/LSP section but not in the Options section and not in a variables table
- /Users/jlipworth/.emacs.d/layers/+lang/ess/config.el:28-32 — two layer variables exist with no cross-reference between config.el and a README Options table
- wc -l: README.org is 174 lines vs python README.org at 663 lines

## Additional gaps caught in verification

- **(medium/bug)** ess-r-mode-hook uses spacemacs//ess-may-setup-r-lsp but local-vars hook is never used — The ESS layer hooks `spacemacs//ess-may-setup-r-lsp` into `ess-r-mode-hook`, which fires before .dir-locals.el variables are applied. The python layer hooks its backend setup into `python-mode-local-vars-hook` specifically to allow per-project .dir-locals.el overrides of the backend variable. As a result, any attempt to set `((ess-r-mode . ((ess-r-backend . ess))))` in a project .dir-locals.el will not prevent LSP from being started, because the hook runs before local vars. Change the hook from `ess-r-mode-hook` to `ess-r-mode-local-vars-hook` (Spacemacs fires this after applying local variables).
- **(low/gap)** No DAP (debug adapter protocol) integration for R — The ESS layer wires ESS-tracebug for debugging but does not integrate with the dap layer, unlike the python layer. The r-dap project provides a DAP server for R. While not yet MELPA-packaged, the dap layer's `dap-register-debug-template` pattern would allow opt-in support. This is low severity since tracebug covers the core debugging workflow, but should be tracked as a modernization gap.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

