# Layer audit: `nginx`  (`+tools/nginx`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verified: the layer is a 3-line stub — packages.el declares `(nginx-mode)` and a bare `:defer t` use-package form, nothing else. No config.el, funcs.el, layers.el, or tests exist. The systemd layer (same +tools category, also a config-file editing layer) ships company, flycheck, and SPC m bindings out of the box — nginx is clearly underbuilt even by the peer standard, not just the python gold standard. lsp-mode ships lsp-nginx.el which already registers an nginx-language-server client for nginx-mode; the layer doesn't even wire it. Maturity rating stands.

## Findings

### HIGH · gap · effort M — No LSP integration despite mature server support

_status: adjusted · deliverable: issue_

lsp-mode already contains lsp-nginx.el which registers nginx-language-server for nginx-mode — no manual `lsp-register-client` call is needed. The layer simply needs: (1) add `lsp-mode` to `nginx-packages` as a post-init target, (2) create `config.el` with `(defvar nginx-enable-lsp nil ...)`, (3) create `layers.el` with `(when nginx-enable-lsp (configuration-layer/declare-layer-dependencies '(lsp)))`, (4) add `nginx/post-init-lsp-mode` that does `(add-hook 'nginx-mode-hook #'lsp-deferred)` when `nginx-enable-lsp` is set. Pattern reference: `/Users/jlipworth/.emacs.d/layers/+tools/terraform/funcs.el:39` and `/Users/jlipworth/.emacs.d/layers/+tools/docker/funcs.el:26-27` both use `(lsp-deferred)` gated by a backend variable. The audit's suggestion to 'mirror how ansible layer calls (lsp) conditionally' is wrong — ansible does NOT call lsp; it only gates company-ansible off yaml-enable-lsp. Use docker/terraform as the correct reference.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/packages.el:24 — `(defconst nginx-packages '(nginx-mode))`, no lsp-mode entry
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-nginx.el:54-60 — lsp-mode already ships lsp-nginx.el which calls `(lsp-register-client ...)` for nginx-mode at :priority -1; no client registration is needed in the layer, only wiring
- /Users/jlipworth/GNU_files/.spacemacs:181-186 — user enables LSP for adjacent html layer (css-enable-lsp, less-enable-lsp, scss-enable-lsp, html-enable-lsp), establishing intent for LSP in config-file layers
- /Users/jlipworth/GNU_files/.spacemacs:187 — nginx is configured as bare symbol with no :variables

### HIGH · gap · effort S — No SPC m major-mode keybinding menu at all

_status: confirmed · deliverable: issue_

Even without LSP, the layer should declare at minimum `SPC m =` (reindent buffer) and `SPC m h h` (browse nginx docs at nginx.org/en/docs/). Add a `:config` block to `nginx/init-nginx-mode` with `spacemacs/declare-prefix-for-mode` and `spacemacs/set-leader-keys-for-major-mode` calls. Once LSP is added, `SPC m g g` and `SPC m h h` for lsp actions become natural additions. The systemd layer at `/Users/jlipworth/.emacs.d/layers/+tools/systemd/packages.el:36-42` is the most direct peer pattern.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/packages.el:26-27 — `(use-package nginx-mode :defer t)` has no :config body; grep for spacemacs/set-leader-keys-for-major-mode and spacemacs/declare-prefix-for-mode across the entire nginx layer directory returns nothing
- /Users/jlipworth/.emacs.d/layers/+tools/systemd/packages.el:36-42 — the peer systemd layer (also a config-file editing layer in +tools) defines SPC m hd and SPC m ho bindings inside its use-package :config block

### MEDIUM · gap · effort S — No completion backend (company-nginx or LSP capf)

_status: adjusted · deliverable: issue_

No standalone company-nginx package exists on MELPA. Completion path is via LSP (nginx-language-server). The layer should add `(spacemacs|add-company-backends :backends company-capf :modes nginx-mode)` inside `nginx/post-init-lsp-mode`, which is exactly what the systemd layer does for its own backend. The evidence line numbers cited in the original audit (.spacemacs:845-846) are slightly off — company-ansible is on 845, company-terraform and company-web are on 847. The substance is correct.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/packages.el:24 — package list is `(nginx-mode)` only
- /Users/jlipworth/GNU_files/.spacemacs:845,847 — user has company-ansible (line 845) and company-terraform, company-web (line 847) in package-selected-packages; no company-nginx
- /Users/jlipworth/.emacs.d/layers/+tools/systemd/packages.el:29,33-34 — peer systemd layer wires systemd-company-backend via spacemacs|add-company-backends

### MEDIUM · gap · effort S — No flycheck/diagnostics wiring

_status: adjusted · deliverable: issue_

The audit's Option A implementation detail contains a minor inaccuracy: it cites the 'dockerfile layer' as the model for a custom `nginx -t` checker, but the docker layer does NOT define a custom flycheck-define-checker — it only calls `(spacemacs/enable-flycheck 'dockerfile-mode)` which relies on flycheck's built-in hadolint support. For nginx, flycheck has no built-in checker, so a `flycheck-define-checker` with `:command ("nginx" "-t" "-c" source)` must actually be written from scratch (in a new funcs.el). The approach is otherwise sound. Add `flycheck` to `nginx-packages`, write `nginx/post-init-flycheck` in funcs.el defining the checker.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/packages.el:24 — no flycheck entry
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/flycheck-20260320.1715/flycheck.el — grep for 'nginx' returns zero results; flycheck has no built-in nginx checker (confirmed)
- /Users/jlipworth/.emacs.d/layers/+tools/systemd/packages.el:30,38-39 — peer systemd layer adds flycheck and calls `(spacemacs/enable-flycheck 'systemd-mode)` in post-init-flycheck
- /Users/jlipworth/.emacs.d/layers/+tools/docker/packages.el:30,61-62 — docker layer uses the same spacemacs/enable-flycheck pattern (relying on flycheck's built-in hadolint checker, NOT a custom-defined checker)

### MEDIUM · gap · effort S — Missing config.el — no layer variables defined

_status: confirmed · deliverable: issue_

Verified: directory contains only packages.el and README.org. Create `config.el` with at minimum `(defvar nginx-enable-lsp nil "Enable LSP for nginx-mode.")`. The terraform layer's config.el at `/Users/jlipworth/.emacs.d/layers/+tools/terraform/config.el` is a better peer reference than python for this layer's scope.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/ — directory listing confirms only packages.el and README.org exist (no config.el, funcs.el, layers.el)
- /Users/jlipworth/GNU_files/.spacemacs:187 — `nginx` is a bare symbol with no :variables
- /Users/jlipworth/.emacs.d/layers/+tools/terraform/config.el:26-32 — peer terraform layer defines `terraform-auto-format-on-save` and `terraform-backend` defvars in config.el

### LOW · modernization · effort L — Tree-sitter grammar exists but no nginx-ts-mode integration

_status: confirmed · deliverable: both_

No Emacs nginx-ts-mode package exists on MELPA as of May 2026. This is a legitimate future enhancement to track, but requires writing a new Emacs package first. Defer until an Emacs-native package appears on MELPA. The finding is accurate as a forward-looking tracker.

**Evidence:**
- https://github.com/opa-oz/tree-sitter-nginx — grammar exists, last active 2025-01-25
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/packages.el:24 — no treesit-auto or nginx-ts-mode entry
- No nginx-ts-mode package found in /Users/jlipworth/.emacs.d/elpa/ — confirmed not installed

### LOW · cleanup · effort S — packages.el uses lexical-binding: nil — should be audited for upgrade

_status: confirmed · deliverable: issue_

The nginx packages.el is 28 lines with one defconst and one use-package form. The systemd layer (direct peer) already uses `lexical-binding: t`. When the layer is expanded with closures in hooks (LSP, flycheck), starting with lexical binding prevents subtle bugs. Change line 1 to `;;; packages.el --- nginx layer packages file for Spacemacs.  -*- lexical-binding: t; -*-`. Note: all new files (config.el, funcs.el, layers.el) should use `lexical-binding: t` from the start.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/packages.el:1 — `;;; ... -*- lexical-binding: nil; -*-` confirmed
- /Users/jlipworth/.emacs.d/layers/+tools/systemd/packages.el:1 — peer systemd layer already uses `lexical-binding: t` as default
- nginx packages.el is 28 lines total with zero dynamic binding reliance: one defconst and one defun containing a single use-package call

### LOW · gap · effort S — README.org has no Key Bindings section or Installation prerequisites

_status: adjusted · deliverable: issue_

README should gain a Prerequisites section (nginx binary for flycheck, pip install nginx-language-server for LSP) and a Key Bindings table once SPC m menu is added. The original audit's claim that 'nginx-mode auto-activates for files in nginx/ directories and sites-enabled/sites-available/' is partially wrong: nginx-mode.el auto-mode-alist only covers `nginx.conf` and `/nginx/*.conf` patterns, not sites-enabled/available directories. A magic-fallback handles nginx-like content heuristically. The README should accurately describe the actual auto-mode patterns, not overstate them.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/nginx/README.org:1-24 — README has only Description and Install sections; confirmed by read
- nginx-mode auto-mode-alist (verified in nginx-mode.el:179-181) covers `nginx\.conf\'` and `/nginx/.+\.conf\'` only — NOT sites-enabled or sites-available (the audit's claim about sites-enabled/available auto-detection is inaccurate)

## Additional gaps caught in verification

- **(medium/gap)** No layers.el — layer cannot conditionally declare LSP dependency — The nginx layer has no layers.el. When nginx-enable-lsp is added, a layers.el is needed to declare the lsp layer dependency conditionally: `(when nginx-enable-lsp (configuration-layer/declare-layer-dependencies '(lsp)))`. Without this, lsp-mode will not be loaded even if nginx-enable-lsp is set. This is a required companion to the LSP finding — the audit omitted it entirely.
- **(low/cleanup)** systemd layer is the correct peer benchmark, not python — The audit benchmarks nginx exclusively against the python gold standard, but the most relevant peer is the systemd layer (also in +tools, also editing a system config-file format). systemd ships company, flycheck, SPC m keybindings, and lexical-binding: t. The apache layer (same +tools category, same original author as nginx-mode) is equally bare, suggesting this is a systemic underinvestment in config-file layers. Noting the correct peer in the issue text will help prioritize and frame the work accurately.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

