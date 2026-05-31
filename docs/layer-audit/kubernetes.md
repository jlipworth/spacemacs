# Layer audit: `kubernetes`  (`+tools/kubernetes`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the underbuilt rating. The layer is three files (packages.el, README.org, img/), zero config.el/funcs.el, one global keybinding, no layer variables, and no SPC m menu. kubernetes-evil does provide modal bindings inside the kubernetes-overview buffer, which partially mitigates the missing SPC m gap but does not change the overall structural picture. The maturity rating stands.

## Findings

### HIGH · gap · effort M — No layer variables — zero user-customisable behaviour

_status: confirmed · deliverable: issue_

Confirmed. There is no config.el, no defvar/defcustom for any kubernetes-specific setting in the layer, and no :variables declaration in defconst kubernetes-packages. At minimum, a config.el should expose: kubernetes-kubectl-executable (default "kubectl"), a namespace default variable, and tramp-related variables (tramp-kubernetes-context, tramp-kubernetes-namespace) for Emacs 29+ users. Wire these in packages.el init functions via :init blocks. The user has no way to configure the layer behaviour without editing user-config directly.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/packages.el:26-30 — defconst kubernetes-packages lists three entries with no :variables anywhere in the layer
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/ contains only packages.el, README.org, and img/ — no config.el exists
- /Users/jlipworth/GNU_files/.spacemacs:204 — user enables the layer as bare `kubernetes` with no variables (confirmed by reading the file)

### MEDIUM · gap · effort M — No SPC m major-mode menu — kubernetes-overview buffer has no Spacemacs leader bindings

_status: adjusted · deliverable: issue_

There is genuinely no spacemacs/set-leader-keys-for-major-mode for kubernetes-overview-mode or kubernetes-mode. However, kubernetes-evil (which this layer loads) already provides a comprehensive set of evil motion-state bindings covering logs, exec, describe, delete, refresh, config, labels — making the SPC m gap less severe in practice than the auditor implies. For magit-style interactive buffers (like magit itself and docker's overview buffer), Spacemacs conventionally relies on the package's own keymap rather than duplicating everything under SPC m. The gap is real for discoverability (which-key won't show these under SPC m), but the commands are accessible. Severity adjusted down from high to medium.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/packages.el:32-46 — no spacemacs/set-leader-keys-for-major-mode call anywhere in the file
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/kubernetes-evil-20260402.429/kubernetes-evil.el — provides extensive modal (evil motion) bindings: l=kubernetes-logs, e=kubernetes-exec, d=kubernetes-describe, D=kubernetes-mark-for-delete, gr=kubernetes-refresh, c=kubernetes-config-popup, etc.
- /Users/jlipworth/.emacs.d/layers/+tools/docker/packages.el:36 — docker layer similarly omits SPC m for docker-mode itself, only adds SPC m for dockerfile-mode (file-editing context)

### MEDIUM · modernization · effort L — Modern alternative packages (kele.el, kubed, kubel) not considered

_status: confirmed · deliverable: both_

Confirmed as a real modernization gap. The user runs Emacs 30.2, which is well above the Emacs 29+ threshold for both kubed and kele.el. Neither is installed locally, which is expected since the layer provides no mechanism to select an alternative backend. Adding a kubernetes-backend layer variable accepting 'kubernetes-el (current default) or 'kubed would bring the layer in line with patterns used in other layers (e.g., python-backend). Effort L is appropriate.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/packages.el:26-46 — only kubernetes, kubernetes-evil, kubernetes-tramp; no mechanism to select a backend
- Emacs 30.2 confirmed installed (emacs --version); kubed requires Emacs 29+ and is on GNU ELPA
- kubernetes-evil-pkg.el URL: https://github.com/kubernetes-el/kubernetes-el — same org as kubernetes package; README still references old chrisbarrett URL
- kubed on GNU ELPA: https://elpa.gnu.org/packages/kubed.html

### LOW · gap · effort S — kubernetes-tramp toggle condition is inverted and misleading

_status: adjusted · deliverable: issue_

The toggle condition is logically CORRECT — it loads kubernetes-tramp only on Emacs < 29 and skips it on 29+, which is the right behaviour given that Emacs 29+ ships a native kubernetes TRAMP method via tramp-container.el. The auditor's title 'condition is inverted' is factually wrong; the condition is not inverted. The real issue is purely documentary: the README describes only kubernetes-tramp (the third-party package) with no version caveat, so any user on Emacs 29+ reading the README will follow instructions that silently don't apply to them. This is a documentation gap, not a bug. Finding 7 in the original audit covers the same ground more accurately; the two should be consolidated. Reclassified from kind=bug/severity=medium to kind=gap/severity=low.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/packages.el:30 — `(kubernetes-tramp :toggle (version< emacs-version "29.0.50"))`
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/README.org:33-40 — TRAMP section has no Emacs version caveat
- Running Emacs 30.2 confirmed via `emacs --version`; kubernetes-tramp is therefore silently skipped on this machine

### LOW · gap · effort M — No YAML/Helm-chart LSP integration wired from this layer

_status: confirmed · deliverable: issue_

Confirmed. lsp-yaml is installed (part of lsp-mode), the user has yaml-enable-lsp t, and lsp-yaml-schemas defaults to empty. The kubernetes layer makes no attempt to wire kubernetes schema validation. A post-init-lsp-mode function conditioned on (configuration-layer/package-used-p 'lsp-mode) that sets lsp-yaml-schemas to include kubernetes glob patterns would give the user automatic schema validation for manifest files. This is a genuine gap though low severity since it requires coordination with the yaml layer.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:104-106 — `(yaml :variables yaml-enable-lsp t)` — user has yaml LSP enabled
- /Users/jlipworth/.emacs.d/layers/+lang/yaml/packages.el — no reference to kubernetes or lsp-yaml-schemas (grep returned no output)
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-yaml.el:90 — `(defcustom lsp-yaml-schemas '())` — variable exists and defaults to empty
- No kubernetes or lsp-yaml-schemas reference in /Users/jlipworth/GNU_files/.spacemacs (grep confirmed)

### LOW · gap · effort S — README documents kubernetes-tramp for all users but it is disabled on Emacs 29+

_status: confirmed · deliverable: issue_

Confirmed. README.org describes only the kubernetes-tramp-based workflow (/kubernetes:container: prefix) with no mention that this package is suppressed on Emacs 29+. A user on Emacs 30.2 following these instructions will find the TRAMP method not available. The fix is a brief version-conditional paragraph: for Emacs < 29, kubernetes-tramp is auto-loaded; for Emacs >= 29, use the built-in TRAMP kubernetes method configured via tramp-kubernetes-context and tramp-kubernetes-namespace. This overlaps with adjusted finding 1 and should be consolidated.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/README.org:33-40 — TRAMP section describes only kubernetes-tramp with no version note
- /Users/jlipworth/.emacs.d/layers/+tools/kubernetes/packages.el:30 — `(kubernetes-tramp :toggle (version< emacs-version "29.0.50"))` silently skips it on Emacs 29+
- User runs Emacs 30.2; kubernetes-tramp is never loaded for this user per the toggle condition

## Additional gaps caught in verification

- **(low/cleanup)** README links to stale chrisbarrett/kubernetes-el URL instead of kubernetes-el org — The README description link points to the original author's personal repo (chrisbarrett/kubernetes-el) which redirects to or has been superseded by the kubernetes-el organisation repo (kubernetes-el/kubernetes-el). The installed package itself already reflects the correct URL. Update README.org:16 to point to https://github.com/kubernetes-el/kubernetes-el. S effort, purely mechanical.
- **(low/bug)** kubernetes-evil binding for 'x' executes marks (bulk delete), not exec — conflicts with evil convention — This is a kubernetes-el package design issue (not a layer issue per se), but the Spacemacs layer could add a layer-level post-init wrapper that rebinds x to something less dangerous, or at minimum documents the x=execute-marks behaviour prominently in README.org. The current README mentions nothing about the mark/execute-marks workflow. A README addition explaining D (mark for delete), u (unmark), U (unmark all), x (execute marks) would prevent accidental pod deletion. The layer could also consider adding a safer binding under SPC m.

## Rejected by verifier (false positives)

- ~~kubernetes-evil loaded with :after kubernetes-overview — always loads eagerly, defeating lazy loading~~ — Verified: (1) kubernetes-overview.el:456 provides 'kubernetes-overview — a real distinct feature. (2) kubernetes-evil-autoloads.el is empty — no commands autoloaded, so package only loads via the :after trigger. (3) use-package with :after wraps the body in eval-after-load, deferring until 'kubernetes-overview is provided. Loading is correctly deferred until the user opens the overview buffer. The 'inverted' and 'eager loading' claims are both false.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

