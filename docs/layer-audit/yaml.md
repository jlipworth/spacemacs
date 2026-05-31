# Layer audit: `yaml`  (`+lang/yaml`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the audit's maturity assessment. All seven findings hold up to code inspection. The layer is a 46-line wiring harness: three packages, one config variable, no SPC m menu, no funcs.el, no formatter integration, no ts-mode support, and no tests. The upstream fork is byte-for-byte identical, so nothing is ahead of baseline. The maturity rating stands.

## Findings

### HIGH · gap · effort M — No yaml-ts-mode support despite Emacs 30.2 being in use

_status: adjusted · deliverable: issue_

yaml-ts-mode ships built-in to Emacs 29+ but requires the yaml tree-sitter grammar to be separately installed. The layer hard-codes yaml-mode everywhere. Add a yaml-enable-ts-mode layer variable (default nil). When enabled and treesit-language-available-p returns t: (1) add :mode entries mapping .yml/.yaml to yaml-ts-mode; (2) use major-mode-remap-alist to redirect yaml-mode to yaml-ts-mode; (3) call define-jump-handlers for yaml-ts-mode; (4) re-hook flycheck and lsp onto yaml-ts-mode-hook. Note: unlike the auditor's claim, gleam-ts-mode is a third-party package, not a built-in — the ts-mode pattern in gleam is inspirational but not directly reusable. The implementation must also guard against the missing grammar with a helpful error or auto-install call (treesit-install-language-grammar 'yaml).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el:24-26 — defconst yaml-packages lists only company, flycheck, yaml-mode; yaml-ts-mode absent
- emacs --batch --eval confirms yaml-ts-mode is fboundp and treesit-available-p returns t in installed Emacs 30.2
- /Users/jlipworth/GNU_files/.spacemacs:104-106 — user has (yaml :variables yaml-enable-lsp t); no ts-mode variable exists to enable
- yaml tree-sitter grammar is NOT yet installed (treesit-language-available-p 'yaml returns nil), so yaml-ts-mode would need grammar installation too — the implementation must handle this gracefully (e.g., prompt via treesit-install-language-grammar or guard with treesit-language-available-p)

### HIGH · gap · effort M — No SPC m keybindings menu — the layer provides zero mode-local leader keys

_status: confirmed · deliverable: issue_

With yaml-enable-lsp t (as the user has configured), lsp-yaml exposes lsp-yaml-select-buffer-schema, lsp-yaml-set-buffer-schema, and lsp-yaml-download-schema-store-db as interactive commands with no discoverable keybinding. The ansible layer even declares yaml-mode leader prefixes itself (mh, mb) as a workaround, confirming the yaml layer's own absence is a known problem. Add a funcs.el, call spacemacs/declare-prefix-for-mode for at minimum: SPC m = (format), SPC m h (help/hover), SPC m S (schema). Bind lsp-yaml-select-buffer-schema to SPC m S s. This follows the pattern of every non-trivial lang layer (gleam, python, rust).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el — rg for spacemacs/set-leader-keys, local-leader, declare-prefix-for-mode returns nothing
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:87-88 — ansible layer post-init-yaml-mode declares 'mh' help and 'mb' buffer prefixes for yaml-mode, exposing the gap in the yaml layer itself
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-yaml.el:210,233 — lsp-yaml-set-buffer-schema and lsp-yaml-select-buffer-schema are interactive commands with no discoverable keybinding
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el — no funcs.el exists in the layer directory

### MEDIUM · gap · effort S — No formatter integration — prettier is installed and yamlfmt is available

_status: confirmed · deliverable: issue_

Add a yaml-formatter layer variable (values: nil, 'prettier, 'yamlfmt). Use reformatter.el (already installed) to define yaml-format-buffer and yaml-format-on-save-mode. Wire as toggled package entries: (prettier-js :toggle (eq 'prettier yaml-formatter)). Bind SPC m = b to the format command. The auditor's reference to python layer line 26 as 'same pattern is viable here' is accurate — the toggle pattern at python/packages.el:26,58,64 directly models this.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el:24-26 — no prettier, reformatter, or apheleia package entry
- which prettier = /Users/jlipworth/.nvm/versions/node/v25.5.0/bin/prettier — prettier is installed and supports YAML natively
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/reformatter-20241204.1051/ — reformatter.el is already installed in this Emacs
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:26,58,64 — python layer uses toggle-based formatter pattern (blacken :toggle, ruff-format :toggle, yapfify :toggle)

### MEDIUM · gap · effort S — lsp-yaml schema variables not exposed as layer variables

_status: confirmed · deliverable: issue_

Add yaml-lsp-schemas (wrapping lsp-yaml-schemas) and yaml-lsp-schema-store-enable (wrapping lsp-yaml-schema-store-enable) as layer variables in config.el, then apply them in post-init-lsp when yaml-enable-lsp is t. Note: lsp-yaml-schema-extensions already ships a Kubernetes entry by default in lsp-yaml.el:181, so users only need yaml-lsp-schemas for additional per-project associations. The auditor's line citation for lsp-yaml-schema-extensions (lsp-yaml.el:181) is correct.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-yaml.el:90 — lsp-yaml-schemas defcustom (alist of schema-uri to glob-list)
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-yaml.el:96 — lsp-yaml-schema-store-enable defcustom
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-yaml.el:181 — lsp-yaml-schema-extensions defcustom (already ships a Kubernetes v1.30.3 entry)
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/config.el:26 — only yaml-enable-lsp defined; no schema wrapper variables
- /Users/jlipworth/.emacs.d/layers/+tools/lsp/packages.el:50 — lsp layer sets lsp-yaml-schema-store-local-db to a custom path, but lsp-yaml-schemas (the user-facing association map) is untouched anywhere

### MEDIUM · enhancement · effort M — yaml-pro package not integrated — structural navigation and scalar editing missing

_status: confirmed · deliverable: issue_

yaml-pro (https://github.com/zkry/yaml-pro) provides path display, structural navigation (yaml-pro-next-subtree), and scalar editing in a detached buffer. It is not currently installed. Add (yaml-pro :toggle yaml-enable-yaml-pro) as a toggled package. Init: add yaml-pro-mode to yaml-mode-hook; bind SPC m k, SPC m j, SPC m e. This is an optional enhancement — severity is medium because the user has LSP active and yaml-pro fills the non-LSP structural editing gap.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el:24-26 — yaml-pro absent from yaml-packages
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/ listing — yaml-pro is not installed in this Emacs (no yaml-pro-* directory found)
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el:43-45 — only keybinding is C-m; no structural movement

### LOW · modernization · effort S — lexical-binding is nil in packages.el and config.el

_status: adjusted · deliverable: issue_

The auditor's framing that 'packages.el and config.el were not updated to t' mischaracterizes the upstream action. Commit 55c9c2fe deliberately added nil to these two files, pending per-file review. The lambda in packages.el:43-45 captures no free variables, so lexical-binding: t is safe. config.el uses no closures at all. Flipping both to t is a safe one-line change per file, but it is a deliberate deferral in upstream, not a forgotten update.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el:1 — -*- lexical-binding: nil; -*-
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/config.el:1 — -*- lexical-binding: nil; -*-
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/layers.el:1 — -*- lexical-binding: t; -*- (fixed by commit c35a6712)
- git show 55c9c2fe -- layers/+lang/yaml/packages.el confirms commit 55c9c2fe explicitly set lexical-binding: nil (not t) in packages.el and config.el, with commit message stating: 'for most files lexical-binding: t should also work without changes. But for each file, someone would need examine it and check whether dynamic binding is relied on somewhere. Hence I went with the current default of lexical-binding: nil'

### LOW · gap · effort M — No layer tests — yaml is absent from tests/layers/+lang/

_status: confirmed · deliverable: issue_

Confirmed gap. Add tests/layers/+lang/yaml/ with an init.el and layers-ftest.el following the python ftest template. Minimum tests: (1) layer loads without error with yaml-enable-lsp nil; (2) layer loads with yaml-enable-lsp t and confirms lsp dependency declared; (3) yaml-mode hook is registered. Low urgency at current layer simplicity, but becomes mandatory once ts-mode toggle, formatter toggle, and schema variables add branching logic.

**Evidence:**
- ls /Users/jlipworth/.emacs.d/tests/layers/+lang/ returns only 'python' — confirmed, yaml has no test directory
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el:28-33 — the yaml-enable-lsp branch (company backend vs lsp hook) is untested
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ — python has functional tests covering layer loading and hook registration

## Additional gaps caught in verification

- **(medium/gap)** yaml-ts-mode requires grammar installation — layer provides no mechanism for it — If yaml-ts-mode support is added (finding 1), the layer must also handle grammar installation. The yaml tree-sitter grammar is not installed on this system, and Emacs will silently fall back or error without a guard. The gleam layer (gleam/funcs.el) demonstrates the correct pattern: check treesit-language-available-p, and if missing call treesit-install-language-grammar. The yaml ts-mode implementation should include this guard, either prompting the user once or auto-installing. This is a prerequisite dependency of finding 1, not just a detail — without it, enabling yaml-enable-ts-mode on a fresh install silently does nothing.
- **(low/bug)** lsp is added via add-hook inside init-yaml-mode rather than via a post-init-lsp function — The Spacemacs convention for integrating with a foreign package is to define a post-init-<pkg> function (e.g., yaml/post-init-lsp) and list lsp in yaml-packages conditionally. The current code instead adds the lsp hook inside init-yaml-mode's :init block, bypassing the package lifecycle. This means lsp keybindings configured via with-eval-after-load 'lsp-mode (as rust layer does for rust-analyzer at packages.el:82) cannot be cleanly separated into a post-init-lsp function. The immediate consequence is that any future SPC m keybindings wired to lsp commands (finding 2) have no clean architectural home. Fix by adding lsp to yaml-packages with a :toggle guard and implementing yaml/post-init-lsp.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

