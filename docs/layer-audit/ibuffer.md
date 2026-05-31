# Layer audit: `ibuffer`  (`+emacs/ibuffer`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the original rating. The layer delivers buffer grouping by modes or by projectile projects, plus five evilified-state keybindings. All four files are identical to upstream develop. evil-collection's ibuffer module is installed but explicitly excluded from Spacemacs's allowed list and therefore inactive. No icon support, no local-leader menu, no ibuffer-vc backend, no display defaults, no tests. The layer is functional at a minimal level but far below parity with comparable setups.

## Findings

### HIGH · gap · effort M — Missing ibuffer-vc grouping backend as a third ibuffer-group-buffers-by option

_status: confirmed · deliverable: issue_

ibuffer-vc groups buffers by their VCS root directory (not by projectile project) and can display a VC status column. This is the preferred grouping mode for git-centric workflows. Add ibuffer-vc to ibuffer-packages with a :requires condition on vc (built-in), add 'vc as a third accepted value for ibuffer-group-buffers-by, write spacemacs//ibuffer-group-by-vc in funcs.el following the pattern of spacemacs//ibuffer-group-by-projects, and document the new value in README.org.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/config.el:24-27 — defvar ibuffer-group-buffers-by documents only 'modes and 'projects
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el — ibuffer-vc is not listed in ibuffer-packages
- ls /Users/jlipworth/.emacs.d/elpa/30.2/develop/ | grep ibuffer — only ibuffer-projectile-20230817.610 is installed; ibuffer-vc is absent
- MELPA archive-contents confirms ibuffer-vc is available

### HIGH · gap · effort M — Evilification covers only 5 bindings; mark, sort, filter, and action operations unreachable in normal state

_status: adjusted · deliverable: issue_

evilified-state for ibuffer-mode exposes only filter-group navigation and refresh. All mark, sort, filter, immediate-action, and batch-operation bindings remain at their vanilla ibuffer defaults, which conflict with evil normal-state keys. The evil-collection ibuffer module is installed in elpa but is explicitly excluded from Spacemacs's allowed list (spacemacs-evil-collection-allowed-list in spacemacs-evil/config.el). Two approaches: (a) expand the evilified-state binding table directly in packages.el, drawing on the evil-collection-ibuffer.el binding list as a reference; or (b) add 'ibuffer to spacemacs-evil-collection-allowed-list and remove the evilified-state block. At minimum add: m (mark), u (unmark), d (mark-for-delete), x (execute), D (do-delete), S (do-save), RET (visit-buffer), go (visit-other-window), yf (copy-filename), and the sort group (o a, o m).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el:45-52 — only gr, gj, ], gk, [ are bound in evilified-state
- /Users/jlipworth/.emacs.d/layers/+spacemacs/spacemacs-evil/config.el:35-46 — spacemacs-evil-collection-allowed-list does NOT include ibuffer; evil-collection's ibuffer module is installed but dormant
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/evil-collection-20251205.1511/modes/ibuffer/evil-collection-ibuffer.el — defines ~80 bindings covering mark (m/u/d/x/D), sort (o a/o m/o v), filter (s RET/s m/s n), visit (RET/go), copy (yf/yb), and batch ops (A/S/V/R) that are all absent from the ibuffer layer

### MEDIUM · cleanup · effort S — defun inside :init blocks should live in funcs.el

_status: confirmed · deliverable: issue_

Two private helper functions (spacemacs//ibuffer-group-by-modes and spacemacs//ibuffer-group-by-projects) are defined inline inside use-package :init blocks rather than in funcs.el, which is the canonical location per layer conventions. This makes them invisible to any hot-patch reload workflow and blurs the boundary between wiring and logic. Move both defuns to funcs.el and leave only the add-hook calls inside :init. No behavioral change required.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el:36 — spacemacs//ibuffer-group-by-modes defined inside use-package :init
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el:58 — spacemacs//ibuffer-group-by-projects defined inside use-package :init
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el — all python helper defuns are top-level in packages.el, not inside :init; all layer-specific helpers live in funcs.el

### MEDIUM · gap · effort M — No all-the-icons-ibuffer (or nerd-icons-ibuffer) icon integration despite user using all-the-icons

_status: confirmed · deliverable: issue_

The user has opted into all-the-icons globally (dotfile line 401) but the ibuffer layer provides no icon column. Add all-the-icons-ibuffer (and conditionally nerd-icons-ibuffer) to ibuffer-packages, gated on a new layer variable ibuffer-icons (default nil) that accepts 'all-the-icons or 'nerd-icons. In the :config block call (all-the-icons-ibuffer-mode 1) when the icon library is loaded. Document the variable in README.org.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:401 — dotspacemacs-default-icons-font is set to 'all-the-icons (confirmed by direct read)
- /Users/jlipworth/GNU_files/.spacemacs:40 — ibuffer layer is loaded without :variables (no icon opt-in possible currently)
- MELPA archive-contents at /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/melpa/archive-contents confirms all-the-icons-ibuffer and nerd-icons-ibuffer are on MELPA and not installed
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el — no reference to all-the-icons or nerd-icons

### LOW · gap · effort S — No SPC m (local leader) menu for ibuffer-mode

_status: confirmed · deliverable: issue_

The layer sets one global binding (SPC b I) but defines no local leader menu for ibuffer-mode. Users expect SPC m (or , in hybrid state) to expose mode-specific actions. A minimal SPC m menu would cover: f (filter), g (group), s (sort), m/u (mark/unmark), x (execute). Implement with spacemacs/set-leader-keys-for-major-mode inside the ibuffer :config block.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el — grep for set-leader-keys-for-major-mode returns no output; only spacemacs/set-leader-keys 'bI' is set (global, not local)
- /Users/jlipworth/.emacs.d/layers/+lang/python/packages.el:82 — python layer uses spacemacs/set-leader-keys-for-major-mode extensively

### LOW · gap · effort S — ibuffer-show-empty-filter-groups and ibuffer-never-show-predicates not configured

_status: confirmed · deliverable: issue_

By default ibuffer shows empty filter groups, which is noisy when many modes are active. The layer should default ibuffer-show-empty-filter-groups to nil. Add a layer variable ibuffer-hide-empty-filter-groups (default t) in config.el and wire it in packages.el via (setq ibuffer-show-empty-filter-groups (not ibuffer-hide-empty-filter-groups)) in the :config block. Optionally expose ibuffer-never-show-predicates as a layer variable.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/config.el — only ibuffer-group-buffers-by is defined; no display defaults
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el — no setq for display vars in :config block

### LOW · bug · effort S — README.org documents TAB/S-TAB/M-n/M-p as layer-managed bindings, but they are native ibuffer bindings that passthrough evilified-state

_status: adjusted · deliverable: issue_

TAB, S-TAB, M-n, and M-p are natively bound in ibuffer's own mode-map (confirmed in ibuffer.el:472-475) and DO work in GUI evilified-state because evilified-state deliberately avoids binding TAB (it uses <C-i> instead). The README is not wrong about the end result, but it is misleading: these bindings appear alongside explicitly layer-managed bindings (gj, gk), implying they are also layer-managed. The bindings could break in terminal mode if a user enables evil-want-C-i-jump, or if evilified-state behavior changes. The fix is to either (a) explicitly add them to the evilify-map call for robustness, or (b) add a note to the README distinguishing native from layer-set bindings. Option (a) is safer.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/README.org:57-58 — documents TAB/M-n and S-TAB/M-p as navigation bindings alongside the explicitly-set gj/] and gk/[
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/packages.el:45-52 — evilified-state-evilify-map does NOT add TAB/S-TAB/M-n/M-p
- /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/ibuffer.el:472-475 — ibuffer's own mode-map natively binds M-n, TAB, M-p, <backtab> to filter-group navigation
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/evil-evilified-state-20250528.133657/evil-evilified-state.el:203-210 — evilified-state uses <C-i> (not TAB) in GUI to avoid shadowing TAB; so ibuffer's native TAB binding survives

### LOW · gap · effort M — No layer tests exist for ibuffer

_status: confirmed · deliverable: issue_

The ibuffer layer has no test suite. spacemacs//ibuffer-create-buffs-group dynamically computes filter groups from live buffer state using recursion and cl-set-difference against a hardcoded ignore-modes list. A unit test mocking (buffer-list) and verifying the output filter groups would catch regressions if ignore-modes or grouping logic is modified. Create tests/layers/+emacs/ibuffer/ with init.el, a basic functional test file, and a Makefile following the pattern at tests/layers/+lang/python/.

**Evidence:**
- /Users/jlipworth/.emacs.d/tests/ — find confirms no +emacs/ibuffer directory under tests/layers/
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ — contains init.el, layers-ftest.el, Makefile as the reference pattern
- /Users/jlipworth/.emacs.d/layers/+emacs/ibuffer/funcs.el:38-58 — spacemacs//ibuffer-create-buffs-group contains non-trivial recursion and cl-set-difference logic that is untested

## Additional gaps caught in verification

- **(medium/gap)** C-x C-b global override is unconditional with no layer variable to disable it — The layer unconditionally rebinds C-x C-b globally to ibuffer, overriding whatever the user had set for list-buffers. There is no layer variable (e.g., ibuffer-replace-list-buffers, default t) to opt out of this. Users who want ibuffer only via SPC b I and wish to preserve C-x C-b for list-buffers or another binding cannot do so without overriding after layer load. Add a defvar ibuffer-replace-list-buffers (default t) in config.el and guard the global-set-key call with it in packages.el.
- **(low/modernization)** All layer files have lexical-binding: nil — should be audited and upgraded to t — The upstream commit 55c9c2fe added lexical-binding: nil cookies as a conservative placeholder, with the commit message explicitly noting that each file needs individual examination before enabling t. The ibuffer layer files are good candidates for enabling lexical-binding: t since funcs.el uses no dynamic binding tricks — all functions are standalone and do not rely on dynamic variable capture. Enabling lexical-binding: t would improve closure performance, eliminate accidental dynamic variable capture in spacemacs//ibuffer-create-buffs-group, and satisfy Emacs 31 byte-compilation requirements. Audit each file and flip to t where safe.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

