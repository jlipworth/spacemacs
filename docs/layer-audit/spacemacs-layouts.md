# Layer audit: `spacemacs-layouts`  (`spacemacs-layouts`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer delivers its core mandate without regressions, but two real defects exist (hardcoded helm in layouts-ts-kill-other; helm-quit-hook improper-list construction), the README documents fewer than half of the configurable variables and active key bindings, and a dynamic-binding hack in a lexical-binding file is a latent correctness risk. Rejection of the false-positive compleseus SPC b B finding actually improves the picture slightly for compleseus users (the binding is already correct), but the helm-quit-hook bug the auditor missed adds back risk at the helm layer. Overall rating unchanged.

## Findings

### HIGH · bug · effort S — layouts-ts-kill-other hardcodes helm, breaks for ivy and compleseus

_status: confirmed · deliverable: issue_

spacemacs/layouts-ts-kill-other (funcs.el:247) calls spacemacs/helm-persp-kill unconditionally. For ivy or compleseus users this will error if helm is not loaded. Fix by mirroring layouts-ts-close-other: add a cond with a helm branch (existing call), an ivy branch using ivy-read over persp-names with a kill action, and a compleseus/fallback branch using completing-read. The user runs helm so this does not bite them today, but it is a latent defect for anyone switching completion frameworks.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/funcs.el:247-250 — unconditionally calls (call-interactively 'spacemacs/helm-persp-kill) with no cond branches
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/funcs.el:234-240 — layouts-ts-close-other has cond on (configuration-layer/layer-used-p 'helm) and 'ivy; kill-other sibling was never updated to match

### MEDIUM · gap · effort S — README documents fewer than half the layer's configurable variables

_status: confirmed · deliverable: issue_

Add three Install subsections covering layouts-enable-autosave/layouts-autosave-delay (periodic auto-save of perspectives; default off, delay 900s) and layouts-enable-local-variables (per-layout variable scoping; default t). Extend the Key Bindings table with SPC b W (goto-buffer-workspace), SPC b B (non-restricted buffer list), SPC b a (persp-add-buffer), SPC b r (persp-remove-buffer), SPC p l (project layout switch). Add a Workspace Key Bindings table for the eyebrowse transient-state sub-keys. Update Features to mention consult/compleseus integration.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/config.el:30 — layouts-enable-autosave; absent from README
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/config.el:33 — layouts-autosave-delay; absent from README
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/config.el:106 — layouts-enable-local-variables; absent from README
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/README.org — grep for autosave, local-variables, bW, SPC b, eyebrowse all return zero hits in the key bindings table
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/packages.el:100,135,255-256,267,274 — binds SPC bW, SPC bB, SPC ba, SPC br, SPC pl; none appear in README key bindings table
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/README.org:23 — Features section still says 'helm and ivy' only; consult/compleseus integration not mentioned despite packages.el:32 listing consult

### LOW · cleanup · effort S — defvar result inside lexical-binding function is a fragile dynamic-scoping hack

_status: confirmed · deliverable: issue_

Refactor spacemacs/window-state-walk-windows and helper to use an explicit accumulator instead of defvar/dynamic binding. Make spacemacs/window-state-walk-windows-1 accept and return an accumulator: (defun spacemacs/window-state-walk-windows-1 (window fn acc) ... returning updated acc). Then spacemacs/window-state-walk-windows becomes (spacemacs/window-state-walk-windows-1 (cdr state) fn nil). Eliminates the defvar, byte-compiler warning, and implicit shared state.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/funcs.el:1 — file has lexical-binding: t
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/funcs.el:669 — (defvar result) ;; use dynamic binding inside spacemacs/window-state-walk-windows
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/funcs.el:663 — helper spacemacs/window-state-walk-windows-1 does (push (funcall fn bare-window) result) with no local binding of result, relying on the dynamic special declared above

### LOW · cleanup · effort S — s.el (s-concat) used once in funcs.el — unnecessary external dependency

_status: confirmed · deliverable: issue_

Replace (s-concat ...) at funcs.el:509 with (concat ...) — functionally identical. This removes the implicit runtime dependency on s.el for a single call site. Note: s.el is a transitive dependency of helm so the practical risk is near zero (this function is only callable when helm is loaded), but using concat is strictly cleaner and removes the implicit assumption. One-liner change.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-layouts/funcs.el:509 — (s-concat "Current Perspective: " (spacemacs//current-layout-name)) inside spacemacs/helm-persp-kill
- grep of spacemacs-layouts-packages list (packages.el:24-32) shows no 's' entry; s.el is not declared as a layer dependency

### LOW · enhancement · effort S — User has auto-resume and autosave both disabled with no explicit intent signalled

_status: confirmed · deliverable: issue_

The user kills weak buffers on layout close (persp-autokill-buffer-on-remove 'kill-weak) indicating intentional layout lifecycle management, but has no layout persistence across restarts. Both auto-resume and periodic autosave are off. Consider enabling autosave by adding layouts-enable-autosave t and layouts-autosave-delay 300 to the spacemacs-layouts :variables block, or setting dotspacemacs-auto-resume-layouts t if startup time cost is acceptable. Autosave requires persp-save-dir to be writable (default ~/.emacs.d/.cache/layouts/).

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:444 — dotspacemacs-auto-resume-layouts nil
- /Users/jlipworth/GNU_files/.spacemacs:48-50 — spacemacs-layouts :variables block sets only persp-autokill-buffer-on-remove 'kill-weak; layouts-enable-autosave absent (defaults nil)

## Additional gaps caught in verification

- **(medium/bug)** helm-quit-hook constructed as improper list via (append hook lambda), breaks when hook is non-nil — Both spacemacs//helm-persp-switch-project-action (line 523) and spacemacs//helm-persp-switch-project-action-maker (line 545) construct a let-bound helm-quit-hook via (append helm-quit-hook (lambda () ...)). The lambda form is not wrapped in a list, so append treats it as the dotted tail rather than a proper list element. When helm-quit-hook is nil the result is just the lambda bytecode (accidentally functional as a single-function hook). When helm-quit-hook already has entries, the result is an improper list that run-hooks will fail to iterate. Fix: wrap the lambda in a list: (append helm-quit-hook (list (lambda () (persp-kill-without-buffers project)))).

## Rejected by verifier (false positives)

- ~~SPC b B (non-restricted buffer list) has no implementation for compleseus~~ — Rejected. compleseus/funcs.el:34-39 confirms spacemacs/compleseus-switch-to-buffer (SPC b b) filters via compleseus-switch-to-buffer-sources using compleseus//persp-contain-buffer-p. compleseus/packages.el:165 shows SPC b B → consult-buffer which uses consult-buffer-sources with no persp filter. Running (append nil (lambda () ...)) tests confirm the two paths are distinct. The behavior is correct and symmetric with helm/ivy. The auditor incorrectly asserted consult-buffer is layout-restricted.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

