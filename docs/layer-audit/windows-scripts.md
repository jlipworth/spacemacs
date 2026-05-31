# Layer audit: `windows-scripts`  (`windows-scripts`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the underbuilt rating. The layer delivers syntax highlighting and a limited keybinding surface for bat/cmd/PowerShell files but ships zero IDE-era integrations: no LSP backend wiring for powershell-mode despite lsp-pwsh.el being installed and lsp-mode already active for every other language layer in the user's config, no flycheck, no REPL send commands, no SPC m prefix group declarations for powershell-mode, and a broken .bat lazy-load path (auto-layer.el registers dos-mode for .bat but dos-mode is neither installed nor in the packages list, so lazy-load silently drops the major mode). None of the nine findings were falsified.

## Findings

### HIGH · gap · effort M — No LSP/eglot backend for PowerShell despite lsp-pwsh shipping full plumbing

_status: confirmed · deliverable: issue_

Add a powershell-backend layer variable in config.el mirroring shell-scripts-backend: (defvar powershell-backend (when (configuration-layer/layer-used-p 'lsp) 'lsp) ...). In packages.el, add a post-init-lsp function that calls (spacemacs//powershell-setup-backend) from powershell-mode-local-vars-hook. The setup function dispatches to (lsp) for the lsp backend. Also add spacemacs/declare-prefix-for-mode declarations for powershell-mode covering at minimum the 'e', 'g', 'h', 'r', and '=' groups. The auditor's detail incorrectly says to gate 'company-capf setup' — the existing company-capf setup is for bat-mode only (packages.el:79), not powershell-mode, so no gating is needed there.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el:84-96 — init-powershell wires only syntax highlighting and one SPC m r r key; no powershell-mode-local-vars-hook, no backend variable, no lsp or eglot-ensure call
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/powershell-20251122.1430/powershell.el:795-796 — with-eval-after-load eglot runs powershell--register-langserver automatically, which adds powershell-mode to eglot-server-programs IF the PSES binary is found; server registration is conditional but eglot-ensure is never called by the layer
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/powershell-20251122.1430/powershell.el:1390-1413 — powershell-install-langserver and powershell--register-langserver are fully implemented and handle download/registration
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-pwsh.el:305-327 — lsp-pwsh.el already registers a complete LSP client (completion, diagnostics, formatting, go-to-definition) keyed on :activation-fn (lsp-activate-on 'powershell')
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:933 — lsp-mode maps powershell-mode to language ID 'powershell' so lsp-pwsh would auto-select on (lsp); but the layer never calls lsp on any powershell-mode hook
- /Users/jlipworth/GNU_files/.spacemacs:70-75 — user has lsp layer with lsp-auto-guess-root t; line 206 has bare 'windows-scripts with no backend variable, while every other language layer (python line 131, shell-scripts line 113, vimscript line 118, R line 158, JS line 164, TS line 171, docker line 201, etc.) sets an explicit backend

### HIGH · gap · effort S — No flycheck/flymake linting for PowerShell (PSScriptAnalyzer gap)

_status: confirmed · deliverable: issue_

If the LSP backend finding is addressed first, PSScriptAnalyzer diagnostics arrive automatically via lsp-pwsh. Even without LSP, add flycheck to windows-scripts-packages with a :toggle condition on (not (eq powershell-backend 'lsp)), and add windows-scripts/post-init-flycheck calling (spacemacs/enable-flycheck 'powershell-mode). The flycheck-powershell MELPA package provides a standalone PSScriptAnalyzer checker for the non-LSP path.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el — flycheck is not in windows-scripts-packages; no post-init-flycheck function exists anywhere in the layer
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:147-151 — python layer pattern: post-init-flycheck calls spacemacs/enable-flycheck for the mode
- https://github.com/PowerShell/PSScriptAnalyzer — PSScriptAnalyzer is the canonical PS linter; bundled with PSES and delivered via LSP diagnostics, but also accessible standalone

### MEDIUM · gap · effort M — PowerShell has no SPC m eval/send-to-REPL keybindings despite powershell.el shipping an inferior shell

_status: confirmed · deliverable: issue_

Add to funcs.el: windows-scripts/powershell-send-region, windows-scripts/powershell-send-buffer, and windows-scripts/powershell-send-line wrapping powershell-simple-send. In init-powershell, add spacemacs/declare-prefix-for-mode declarations for 'me' (eval) and 'mh' (help) and wire them via :spacebind or set-leader-keys-for-major-mode. The SPC a t s p global binding already starts the inferior shell but nothing sends code to it.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el:95-96 — only one SPC m key for powershell-mode: 'rr' (regexp transform); no 'e' eval group, no 's' send group
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/powershell-20251122.1430/powershell.el:999-1016 — (defun powershell ...) starts an inferior PowerShell comint shell
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/powershell-20251122.1430/powershell.el:1239 — powershell-simple-send exists but no interactive send-region/send-buffer wrappers are defined in the layer
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el:97-100 — upstream TODO explicitly notes 'get help output with mgg (Get-Help)' and has an empty third bullet indicating unfinished intent

### MEDIUM · bug · effort S — Orphaned dos-mode jump handler — dos-mode is neither a managed package nor installed

_status: adjusted · deliverable: issue_

The orphaned dos-mode problem has two distinct symptoms beyond the jump handler: (1) config.el:26 runs jump handler registration against a mode that doesn't exist, generating latent warnings. (2) auto-layer.el:96 registers a lambda for .bat files that will call (funcall 'dos-mode) only if (fboundp 'dos-mode) — since dos-mode is never installed, .bat files opened when windows-scripts is lazily installed get no major mode. Fix: change auto-layer.el:96 from dos-mode to bat-mode (matching packages.el), remove the jump handler from config.el or add (spacemacs|define-jump-handlers bat-mode) instead. bat-mode is built-in and is the mode that packages.el actually manages.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/config.el:26 — (spacemacs|define-jump-handlers dos-mode) is called unconditionally at layer load
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el:24-29 — windows-scripts-packages contains bat-mode, bmx-mode, ggtags, powershell; dos-mode is absent
- /Users/jlipworth/.emacs.d/layers/auto-layer.el:96 — lazy-install registers windows-scripts for .bat files using dos-mode as the target mode
- find /Users/jlipworth/.emacs.d/elpa -name 'dos-mode*' returned nothing; no dos-mode in Emacs built-ins at /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/
- /Users/jlipworth/.emacs.d/core/core-configuration-layer.el:1283-1289 — configuration-layer//auto-mode calls (when (fboundp mode) (funcall mode)); since dos-mode is never installed, .bat files get no major mode activation through the lazy-install path

### MEDIUM · bug · effort S — bat-outline uses raw evil/local-set-key instead of Spacemacs keybinding APIs

_status: confirmed · deliverable: issue_

The define-key on evil-normal-state-local-map at funcs.el:32 bypasses which-key group labels and Spacemacs prefix declaration tracking. Replace with spacemacs/set-leader-keys (or spacemacs/set-leader-keys-for-major-mode called after outline-mode activates) to bind SPC m z to 'bat-mode while in outline state. The local-set-key for [return] at line 31 is fine. The [mouse-1] lambda at line 30 is also fragile: (bat-mode) (beginning-of-line) calls the major mode then moves point, but would be cleaner as outline-minor-mode toggle. For a minimal fix: replace only line 32 with (spacemacs/set-leader-keys-for-minor-mode ...) or define a named outline-toggle keymap.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/funcs.el:30 — local-set-key [mouse-1] lambda that calls bat-mode before beginning-of-line
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/funcs.el:31 — local-set-key [return] 'bat-mode
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/funcs.el:32 — (define-key evil-normal-state-local-map (kbd 'SPC m z') 'bat-mode) mutates evil state map directly, bypassing which-key and prefix declarations
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el:50 — the same SPC m z key is declared via :spacebind for bat-mode to enter outline mode; the exit path at funcs.el:32 uses an incompatible API

### LOW · cleanup · effort S — config.el has wrong docstring ('packages File' instead of 'Configuration')

_status: confirmed · deliverable: issue_

Change line 1 of config.el from 'Windows Scripts Layer packages File for Spacemacs' to 'Windows Scripts Layer Configuration File for Spacemacs'. One-line fix.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/config.el:1 — header reads ';;; config.el --- Windows Scripts Layer packages File for Spacemacs'; the word 'packages' is a copy-paste error from packages.el

### LOW · gap · effort S — .psd1 (PowerShell Data/Module Manifest) extension not registered in :mode

_status: confirmed · deliverable: issue_

Add ("\\.psd1\\'" . powershell-mode) to the :mode list in init-powershell. PowerShell data files (.psd1, used for module manifests and hash tables) use identical PowerShell syntax to .ps1 and benefit from the same LSP and highlighting. In non-lazy-install sessions (packages already installed) .psd1 files currently open in fundamental-mode.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el:86-87 — :mode list has only .ps1 and .psm1; .psd1 is absent
- /Users/jlipworth/.emacs.d/layers/auto-layer.el:97 — lazy-install regex '\(\.ps[dm]?1\'\|\.ps1$\)' does match .psd1 (the [dm]? covers 'd') so the lazy-install path would call (funcall 'powershell-mode) for .psd1 files; but when powershell is already installed the use-package :mode block does not put .psd1 in auto-mode-alist
- /Users/jlipworth/.emacs.d/core/core-configuration-layer.el:1264-1272 — lazy-install adds to auto-mode-alist only for the purpose of calling configuration-layer//auto-mode; once packages are installed, the use-package :mode entries govern

### LOW · gap · effort M — No layer tests directory

_status: confirmed · deliverable: issue_

Add tests/layers/+lang/windows-scripts/ with at minimum: (1) a test that windows-scripts-packages contains expected symbols, (2) a test that bat-mode activates for .bat files, (3) a test that the SPC m e b key binding resolves to bat-run. Follow the ERT test patterns in tests/layers/+lang/python/.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*windows*' -o -name '*bat*' -o -name '*powershell*' returned no results
- /Users/jlipworth/.emacs.d/tests/layers/+lang/ contains only 'python' — windows-scripts has no test directory at all

### LOW · modernization · effort S — No lexical-binding: t upgrade — all three files are locked at nil

_status: confirmed · deliverable: issue_

funcs.el contains only windows-scripts/bat-outline using setq-local and define-key — no dynamic binding reliance. config.el contains only a macro call. packages.el uses use-package forms and lambda closures that would benefit from lexical binding. Review each, flip the cookie to t, and verify with byte-compile. This is an Emacs-31 readiness fix.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/funcs.el:1 — lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/packages.el:1 — lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+lang/windows-scripts/config.el:1 — lexical-binding: nil
- git show 55c9c2fe commit message: 'For most files lexical-binding: t should also work without changes. But for each file, someone would need examine it... Hence I went with the current default of lexical-binding: nil' — this commit touched all three windows-scripts files setting nil as a safe placeholder
- git show 55c9c2fe --stat shows layers/+lang/windows-scripts/config.el, funcs.el, packages.el all modified by 55c9c2fe

## Additional gaps caught in verification

- **(medium/gap)** No company backend configured for powershell-mode — Add powershell-mode to post-init-company or add a separate spacemacs|add-company-backends call for powershell-mode with at minimum company-capf and company-files. Without this, auto-completion in powershell-mode buffers uses only the global company backend list, missing any completion-at-point integration. When LSP is enabled (finding 1), company-capf will delegate to lsp-completion-at-point automatically, but the explicit declaration is still needed for non-LSP configurations.
- **(medium/bug)** auto-layer.el .bat lazy-install registers dos-mode as the activation mode — bat files get no mode in lazy-install sessions — The auditor's finding 4 covered the orphaned dos-mode jump handler in config.el, but missed this distinct sub-bug: the lazy-install path for .bat files in auto-layer.el:96 specifies dos-mode as the target, which means any user who triggers lazy-install by opening a .bat file for the first time will have the windows-scripts layer installed but .bat will remain in fundamental-mode (because (fboundp 'dos-mode) is nil). Change auto-layer.el:96 from dos-mode to bat-mode to match packages.el:34. This is a separate fix from removing the jump handler.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

