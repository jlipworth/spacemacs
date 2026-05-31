# Layer audit: `toml`  (`+lang/toml`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the layer is exactly two files (packages.el + README.org), identical to upstream, providing only regex-based syntax highlighting via unmaintained toml-mode. No LSP, no tree-sitter integration, no formatter, no keybindings, no flycheck, no company registration, no config.el, no layers.el. All seven audit findings hold. The user has lsp, auto-completion (company), and flycheck layers active but none of their benefits reach TOML buffers. Rating unchanged.

## Findings

### HIGH · gap · effort M — Add LSP backend support (taplo / tombi) via toml-enable-lsp variable

_status: adjusted · deliverable: issue_

Add a toml-enable-lsp layer variable (default nil, not auto-detected — matching yaml-enable-lsp pattern, not python-backend's auto-detection) in a new config.el. Add layers.el that calls (configuration-layer/declare-layer-dependencies '(lsp)) when toml-enable-lsp is non-nil, mirroring /Users/jlipworth/.emacs.d/layers/+lang/yaml/layers.el. In packages.el, declare lsp as a conditional package and add toml/pre-init-lsp that hooks lsp into toml-mode-hook (and toml-ts-mode-hook when treesit-ready-p). Optionally expose toml-lsp-server ('taplo or 'tombi). The user already has lsp layer active at /Users/jlipworth/GNU_files/.spacemacs:70 and yaml-enable-lsp t at line 105, so the pattern is already familiar.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/toml/packages.el:24-25 — toml-packages is '(toml-mode); no lsp or backend wiring exists
- /Users/jlipworth/GNU_files/.spacemacs:108 — layer is declared bare as 'toml' with no :variables; no LSP opt-in path exists
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-toml.el:158-167 — taplo client registered at priority -1; activation-fn checks (string= (lsp-buffer-language) "toml"); lsp-buffer-language returns "toml" for .toml files (pattern line 839) and falls back to stripping "-mode" from toml-mode symbol name, so toml-mode buffers would activate taplo if (lsp) hook were present
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-toml-tombi.el:45-51 — tombi client registered at priority -2
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/config.el:26-27 — yaml-enable-lsp defaults nil with no auto-detection; /Users/jlipworth/.emacs.d/layers/+lang/yaml/layers.el:24-26 shows the layers.el pattern

### HIGH · modernization · effort M — Adopt built-in toml-ts-mode (Emacs 29+) instead of unmaintained toml-mode

_status: adjusted · deliverable: issue_

The layer should conditionally use toml-ts-mode when (treesit-ready-p 'toml) is true, falling back to toml-mode otherwise. The toml tree-sitter grammar is not currently installed on this system so the guard is load-bearing. Keep toml-mode as fallback. Wire any LSP hook to both toml-mode-hook and toml-ts-mode-hook. The Cargo.lock and .cargo/config patterns in packages.el:29 should be replicated to toml-ts-mode's :mode when adding ts-mode support. The auditor's evidence at evidence[1] cited derived-mode-add-parents as the reason lsp-mode recognises toml-ts-mode, but actually toml-ts-mode has its own explicit entry in lsp-language-id-configuration at lsp-mode.el:1020. The conclusion (lsp fires for toml-ts-mode) is correct but the stated mechanism was wrong.

**Evidence:**
- /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/textmodes/toml-ts-mode.el:1 — confirmed present and built-in in Emacs 30.2
- /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/textmodes/toml-ts-mode.el:156 — (derived-mode-add-parents 'toml-ts-mode '(toml-mode)) confirmed
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:1020 — (toml-ts-mode . "toml") is an explicit entry in lsp-language-id-configuration; toml-ts-mode is already recognized by lsp-mode directly, not via derived-mode-add-parents
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/toml-mode-20161107.1800/toml-mode.el:7 — Package-Version: 20161107.1800 confirmed
- find /Users/jlipworth -maxdepth 5 -name '*toml*.so' returned empty — toml tree-sitter grammar not currently installed; treesit-ready-p guard is therefore essential

### MEDIUM · gap · effort S — Add taplo formatter integration with format-on-save toggle

_status: confirmed · deliverable: issue_

Add a toml-fmt-on-save boolean variable in config.el. When set non-nil, wire a before-save-hook that calls taplo format on the buffer. Expose SPC m = = as the manual format keybinding on toml-mode-map (and toml-ts-mode-map). When LSP is active, delegate to lsp-format-buffer. The user's .spacemacs shows format-on-save is used in other layers (python-format-on-save is set), so there is appetite for this pattern.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/toml/packages.el:24-30 — no formatter package, hook, or before-save-hook anywhere in the layer
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-toml.el:37 — lsp-toml-command is 'taplo'; lsp-format-buffer delegates to taplo when LSP is active, but no LSP is wired today
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:500-506 — ruff-format shows the toggle + format-on-save-hook pattern

### MEDIUM · gap · effort S — Add SPC m prefix keybindings (currently none exist)

_status: confirmed · deliverable: issue_

Once LSP and formatter are wired, add spacemacs/declare-prefix-for-mode and spacemacs/set-leader-keys-for-major-mode calls for toml-mode (and toml-ts-mode). Minimum: SPC m = = (format buffer), SPC m = r (format region). With LSP: SPC m g g (lsp-find-definition), SPC m h h (lsp-describe-thing-at-point). Update README.org with a Key bindings section. Depends on findings 1 and 3 being implemented first.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/toml/packages.el:27-30 — toml/init-toml-mode body contains only :mode and :defer; zero spacemacs/set-leader-keys-for-major-mode calls confirmed
- /Users/jlipworth/.emacs.d/layers/+lang/toml/README.org:14 — feature list is a single line with no key bindings section
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:397-428 — python layer shows expected prefix + binding pattern

### MEDIUM · gap · effort S — Add flycheck/flymake integration for TOML syntax validation

_status: confirmed · deliverable: issue_

Add flycheck to toml-packages and add a toml/post-init-flycheck function calling (spacemacs/enable-flycheck 'toml-mode), mirroring yaml/post-init-flycheck. When LSP is active, lsp-mode delivers taplo diagnostics via flycheck automatically. Without LSP, define a flycheck-define-checker using taplo check. Apply the same hook to toml-ts-mode-hook when treesit mode is active. The user has both the flycheck infrastructure and the lsp layer already active.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/toml/packages.el:24-25 — flycheck not listed in toml-packages; grep returned no output
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el:24-26 — yaml-packages lists flycheck; yaml/post-init-flycheck calls (spacemacs/enable-flycheck 'yaml-mode) at line 32-33
- /Users/jlipworth/GNU_files/.spacemacs:70 — user has lsp layer active; lsp-mode flycheck integration would deliver taplo diagnostics automatically when LSP is wired

### MEDIUM · gap · effort S — Add config.el with layer variables and layers.el for LSP dependency declaration

_status: confirmed · deliverable: issue_

Create config.el defining: toml-enable-lsp (boolean, default nil), toml-lsp-server ('taplo or 'tombi, default 'taplo), toml-fmt-on-save (boolean, default nil). Also add (spacemacs|define-jump-handlers toml-mode) here. Create layers.el that calls (configuration-layer/declare-layer-dependencies '(lsp)) when toml-enable-lsp is non-nil, mirroring yaml/layers.el. These are prerequisites for findings 1, 3, 4, and 5.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/toml/ — confirmed only packages.el and README.org exist; no config.el, no layers.el
- git show syl20bnr/develop:layers/+lang/toml/config.el — exits with code 128 (path does not exist); upstream is equally missing these files
- git show syl20bnr/develop:layers/+lang/toml/layers.el — exits with code 128; same
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/config.el:26-27 — yaml-enable-lsp variable pattern confirmed
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/layers.el:24-26 — (configuration-layer/declare-layer-dependencies '(lsp)) when yaml-enable-lsp pattern confirmed

### LOW · cleanup · effort S — README.org is a stub with no key bindings, no configuration variables, and no feature description

_status: confirmed · deliverable: issue_

After config.el is created with layer variables, expand README.org to include: a Configuration section documenting toml-enable-lsp, toml-lsp-server, toml-fmt-on-save; an Install section noting taplo must be installed (cargo install taplo-cli --features lsp); and a Key bindings table following the standard Spacemacs README template. Blocked on findings 1, 3, 4, and 6 being implemented first.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/toml/README.org:14 — features section: 'Provide editing capabilities for TOML files.' — single line confirmed
- /Users/jlipworth/.emacs.d/layers/+lang/toml/README.org — no Configuration section, no Key bindings section, no variable documentation confirmed by full file read
- /Users/jlipworth/GNU_files/.spacemacs:108 — bare 'toml' with no :variables consistent with no documented variables

## Additional gaps caught in verification

- **(medium/gap)** No company backend registration for non-LSP completion — Add company to toml-packages and add a toml/post-init-company function that calls (spacemacs|add-company-backends :modes toml-mode) unless toml-enable-lsp is non-nil, mirroring yaml/post-init-company. This gives basic dabbrev/capf completion in TOML buffers for users without LSP, and avoids double-registering when LSP is active. The user has the auto-completion layer active so company is available.
- **(low/gap)** No spacemacs|define-jump-handlers call for toml-mode — Add (spacemacs|define-jump-handlers toml-mode) in the new config.el (dependency on finding 6). This registers the SPC m g g / gd jump infrastructure so that when LSP is later wired, lsp-find-definition integrates cleanly into the standard Spacemacs jump handler chain rather than being called only via raw keybinding.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

