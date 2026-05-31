# Layer audit: `lsp`  (`+tools/lsp`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer correctly wraps lsp-mode, lsp-ui, lsp-treemacs, lsp-origami, lsp-sonarlint, and all three completion-framework variants. Core keybinding infrastructure (navigation modes, peek/simple/both, extension API) is solid. Verified issues: three action bindings are permanent stubs, lsp-origami unconditionally activates origami-mode regardless of folding preference, README is out of sync on two keybindings and one default value, five lsp-mode commands that exist upstream are unbound, and there are zero tests. None of the audit's main findings were false positives. Severity on two findings is adjusted (origami from high to medium; lexical-binding correctness claim is overstated). Maturity rating unchanged.

## Findings

### HIGH · bug · effort S — Three code-action bindings are permanent placeholder stubs

_status: confirmed · deliverable: issue_

SPC m a f (fix), SPC m a r (refactor), SPC m a s (source) show 'not supported yet' despite lsp-execute-code-action-by-kind being available. Replace the three placeholder bindings with named functions spacemacs//lsp-action-quickfix, spacemacs//lsp-action-refactor, spacemacs//lsp-action-source calling (lsp-execute-code-action-by-kind "quickfix"), "refactor", "source" respectively. Delete spacemacs//lsp-action-placeholder. Update README.org note on line 227 which still says these are placeholders for 'imminent lsp-mode features'.

**Evidence:**
- layers/+tools/lsp/funcs.el:93-95 — 'af', 'ar', 'as' all bound to spacemacs//lsp-action-placeholder
- layers/+tools/lsp/funcs.el:316-318 — placeholder prints 'Not supported yet... (to be implemented in lsp-mode)'
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:6323 — lsp-execute-code-action-by-kind confirmed present in installed lsp-mode

### MEDIUM · bug · effort S — lsp-origami unconditionally enables origami-mode, overriding the user's configured fold method

_status: adjusted · deliverable: issue_

Every LSP buffer open triggers lsp-origami-try-enable which unconditionally calls (origami-mode 1) before checking whether the server supports foldingRange. Since origami is a dependency of lsp-origami it is always installed. This activates origami-mode per-buffer even when the user's folding method is 'evil, potentially conflicting with evil fold keybindings in those buffers. Fix: in packages.el, wrap the add-hook call in (when (eq dotspacemacs-folding-method 'origami) ...). Alternatively add a layer variable lsp-enable-lsp-origami defaulting to (eq dotspacemacs-folding-method 'origami).

**Evidence:**
- layers/+tools/lsp/packages.el:98-102 — lsp-origami-try-enable added to lsp-after-open-hook with no condition
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-origami-20260507.1743/lsp-origami.el:65-74 — lsp-origami-try-enable calls (origami-mode 1) as its first statement, before the server-capability check
- /Users/jlipworth/GNU_files/.spacemacs:594 — dotspacemacs-folding-method is 'evil
- layers/+spacemacs/spacemacs-editing/packages.el:38 — origami package is toggled on (eq 'origami dotspacemacs-folding-method), but lsp-origami has no equivalent gate

### MEDIUM · bug · effort S — README.org documents 'SPC m g h' as a direct call-hierarchy command but it is now a prefix key

_status: confirmed · deliverable: issue_

README.org line 236 says SPC m g h invokes call-hierarchy directly. Since commit b4d87c6d, 'gh' is a which-key prefix and the actual command is 'ghh'. Update README.org: change '~SPC m g h~' to '~SPC m g h h~' and add a '~SPC m g h~' prefix-only row.

**Evidence:**
- layers/+tools/lsp/README.org:236 — '~SPC m g h~ | goto call hierachy (lsp-treemacs)'
- layers/+tools/lsp/funcs.el:135-136 — 'gh' is now bound as prefix 'hierarchy', actual command is 'ghh' -> lsp-treemacs-call-hierarchy
- git show b4d87c6d — changed funcs.el only; README.org was NOT updated in that commit

### MEDIUM · gap · effort S — Inlay hints (lsp-inlay-hints-mode) has no toggle binding

_status: confirmed · deliverable: issue_

lsp-inlay-hints-mode ships in current lsp-mode and is supported by rust-analyzer, clangd, pyright. No toggle is exposed. The auditor's suggested key 'Tli' (lowercase i) is free since TlI is taken. Add 'Tli' -> #'lsp-inlay-hints-mode in spacemacs/lsp-bind-keys under the Tl toggle prefix. Also expose lsp-inlay-hint-enable as a documented layer variable in README.org (upstream default is nil so inlay hints are opt-in). Note: upstream lsp-mode line 2850 binds 'ai' -> lsp-inlay-hint-accept in the command map, which is absent from the layer's custom keybindings as well.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:10558 — lsp-inlay-hints-mode defined
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:3800-3804 — lsp-inlay-hint-enable defcustom with default nil
- layers/+tools/lsp/funcs.el:115-132 — SPC m T l prefix has toggles for doc/sideline/lens but no inlay hints toggle
- layers/+tools/lsp/funcs.el:121 — 'TlI' is already taken by spacemacs/lsp-ui-sideline-ignore-duplicate

### MEDIUM · gap · effort S — lsp-ui-doc-glance and lsp-signature-activate are unbound in the help prefix

_status: confirmed · deliverable: issue_

lsp-ui-doc-glance (transient doc popup without enabling the persistent overlay) and lsp-signature-activate (manual signature trigger) are standard help commands. Add 'hg' #'lsp-ui-doc-glance and 'hs' #'lsp-signature-activate in spacemacs/lsp-bind-keys. Gate 'hg' on (configuration-layer/package-used-p 'lsp-ui) to avoid unbound-function errors when lsp-use-lsp-ui is nil.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:2838-2841 — upstream command map binds 'hg' -> lsp-ui-doc-glance, 'hs' -> lsp-signature-activate
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-ui-20260512.1516/lsp-ui-doc.el:1239 — lsp-ui-doc-glance confirmed present
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:6075 — lsp-signature-activate confirmed present
- layers/+tools/lsp/funcs.el:103 — SPC m h only has 'hh' -> lsp-describe-thing-at-point; 'hg' and 'hs' absent

### MEDIUM · gap · effort M — Layer has zero tests; lsp keybinding infrastructure is entirely untested

_status: confirmed · deliverable: issue_

The extension API (lsp-define-extensions / lsp-bind-extensions-for-mode) and navigation-mode branching (simple/peek/both) are invoked by every LSP-backed language layer but have no ERT coverage. Create tests/layers/+tools/lsp/ with init.el, Makefile (modeled on tests/layers/+lang/python/Makefile), and layers-ftest.el. Minimum test surface: (1) lsp-define-extensions produces correctly named functions, (2) lsp-bind-extensions-for-mode registers bindings under the right prefix for each lsp-navigation value, (3) spacemacs//lsp-bind-simple-navigation-functions registers expected keys.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests — no +tools/lsp/ directory; no test file references lsp
- tests/layers/+lang/python/ — python layer has layers-ftest.el, init.el, Makefile as the repo reference pattern
- layers/+tools/lsp/funcs.el:175-223 — spacemacs//lsp-bind-extensions-for-mode and spacemacs/lsp-define-extensions contain non-trivial branching logic called by every LSP-backed language layer

### LOW · gap · effort S — lsp-disconnect is unbound; only lsp-workspace-shutdown is exposed

_status: confirmed · deliverable: issue_

lsp-disconnect detaches the client without killing the server process. Add 'bD' -> #'lsp-disconnect in spacemacs/lsp-bind-keys (note: 'bd' is taken by lsp-describe-session at line 107). Update README.org backend table with the new binding.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:2793 — upstream command map binds 'wD' -> lsp-disconnect
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:9834 — lsp-disconnect function confirmed present
- layers/+tools/lsp/funcs.el:107-110 — 'bs' -> lsp-workspace-shutdown; lsp-disconnect absent

### LOW · bug · effort S — README.org documents 'SPC m g p' (goto previous) which is not bound in code

_status: confirmed · deliverable: issue_

README.org lists both 'SPC m g b' and 'SPC m g p' pointing at xref-go-back, but only 'gb' is implemented. Two options: (a) remove the 'SPC m g p' row as a documentation error, or (b) implement 'gp' -> #'xref-go-forward (which exists) and 'gb' -> #'xref-go-back for a symmetric back/forward pair, updating the README accordingly. Option (b) is the more useful fix.

**Evidence:**
- layers/+tools/lsp/README.org:247 — '~SPC m g p~ | goto previous (~xref-go-back~)'
- layers/+tools/lsp/funcs.el:146 — only 'gb' -> xref-go-back is bound; no 'gp' binding exists
- layers/+tools/lsp/README.org:240 — 'SPC m g b' also listed as 'jump back (xref/lsp)' — same function documented under two keys
- emacs --batch confirms xref-go-forward exists as a callable function

### LOW · bug · effort S — README documents lsp-lens-enable default as nil but lsp-mode defcustom default is t

_status: adjusted · deliverable: issue_

The README variables table says lsp-lens-enable defaults to nil, but the upstream defcustom defaults to t since lsp-mode 6.3. Additionally the section intro incorrectly implies all listed variables are defined in config.el — lsp-lens-enable, lsp-headerline-breadcrumb-enable, lsp-modeline-diagnostics-enable, and lsp-modeline-code-actions-enable are all upstream defcustoms not present in the layer's config.el. Fix: update README.org line 74 to show 't' as default, and revise the section intro to clarify which variables are layer-defined vs. upstream pass-throughs.

**Evidence:**
- layers/+tools/lsp/README.org:74 — table shows 'nil' as default for lsp-lens-enable
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:1164 — defcustom lsp-lens-enable t
- layers/+tools/lsp/config.el — lsp-lens-enable is NOT defined here at all; it is purely an upstream defcustom
- layers/+tools/lsp/README.org:66 — section intro claims 'variables exposed via config.el' but lsp-lens-enable, lsp-headerline-breadcrumb-enable, lsp-modeline-* are upstream defcustoms, not layer variables

### LOW · cleanup · effort S — funcs.el, packages.el, and config.el use lexical-binding nil; only layers.el uses t

_status: adjusted · deliverable: issue_

Three of four non-layers files use dynamic binding. The defalias lambdas in spacemacs//lsp-define-custom-extension (funcs.el:285-294) use quasiquoting to embed variable values as literals rather than closures, so they are correct under dynamic binding. However enabling lexical-binding: t is still good practice and future-proofs the code. Enable it in all three files; the quasiquoted defalias forms require no changes since they embed values at construction time regardless of binding mode.

**Evidence:**
- layers/+tools/lsp/funcs.el:1 — -*- lexical-binding: nil; -*-
- layers/+tools/lsp/packages.el:1 — -*- lexical-binding: nil; -*-
- layers/+tools/lsp/config.el:1 — -*- lexical-binding: nil; -*-
- layers/+tools/lsp/layers.el:1 — -*- lexical-binding: t; -*-

## Additional gaps caught in verification

- **(low/gap)** xref-go-forward is unbound; the layer only exposes xref-go-back — xref-go-forward is available in Emacs and is the natural complement to xref-go-back. Add (concat prefix-char 'n') -> #'xref-go-forward (or 'f' if 'n' collides) in spacemacs//lsp-bind-simple-navigation-functions to give users back/forward xref stack navigation. This is a natural companion to the existing gb binding and should be documented in README.org alongside the gb entry.
- **(low/gap)** lsp-treemacs-references and lsp-treemacs-implementations have no bindings in the lsp layer — lsp-treemacs-references and lsp-treemacs-implementations show results in a treemacs tree view with expandable context — more useful for large codebases than xref's flat list. Consider adding bindings under the 'gh' hierarchy prefix (e.g. 'ghr' and 'ghi') in the lsp-treemacs when-block in spacemacs/lsp-bind-keys. The commit message for b4d87c6d mentions 'unhide 6 other commands' — these hierarchy-related treemacs commands are the intended destination for those gh? slots.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

