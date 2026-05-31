# Layer audit: `ranger`  (`+tools/ranger`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

The layer handles core dired evilification, dirvish override mode, and a handful of dirvish extension commands (side, fd, quick-access, narrow, subtree, ls-switches) correctly. However it exposes no yank/vc-configuration/emerge/rsync/peek/collapse/history integration, has no SPC m prefix, no layers.el, no tests, a ghost variable (ranger-show-preview does not exist in ranger.el) documented and recommended in the README, and dead user-facing config for dirvish users who follow the README example. Maturity rating unchanged from the audit.

## Findings

### HIGH · gap · effort L — No layer-level integration for any dirvish extension module

_status: confirmed · deliverable: both_

The layer uses dirvish-side, dirvish-quick-access, dirvish-fd, dirvish-narrow, dirvish-subtree, and dirvish-ls-switches-menu as commands (via autoloads), but configures none of the richer extension modules. The most impactful omissions are: dirvish-yank (async copy/move/symlink ops replacing dired-do-copy), dirvish-vc (vc-state/git-msg attributes plus dirvish-vc-menu dispatch — note that adding vc-state to dirvish-attributes IS sufficient to trigger auto-load of dirvish-vc.el per dirvish--libraries, but the layer neither documents this nor sets up the vc-menu keybinding), dirvish-emerge (ibuffer-style grouping), and dirvish-peek (minibuffer preview). A layer variable ranger-dirvish-extensions (default nil, accepts a list) could drive opt-in activation. At minimum, dirvish-vc-menu should be bound under a dired-mode SPC m g key when the git layer is present (via configuration-layer/layer-used-p).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/packages.el — zero references to dirvish-yank, dirvish-vc (configuration), dirvish-emerge, dirvish-rsync, dirvish-peek, dirvish-collapse, dirvish-history
- /Users/jlipworth/.emacs.d/elpa/30.1/develop/dirvish-20250504.807/ — 20 dirvish-*.el extension files confirmed installed
- /Users/jlipworth/GNU_files/.spacemacs:42-43 — user is a dirvish-only user
- dirvish.el:594-600 — dirvish--libraries shows auto-require logic: vc-state attr auto-loads dirvish-vc, yank attr auto-loads dirvish-yank, but neither is configured or keybind-exposed by the layer

### MEDIUM · bug · effort S — ranger-show-preview / ranger-show-hidden are silently ignored in dirvish mode

_status: adjusted · deliverable: issue_

This finding has two compounded problems the auditor described as one. First, ranger-show-preview is a ghost variable: it is documented in README.org (lines 28 and 36) and recommended as a :variables entry, but it is never defined in ranger.el (the real variable is ranger-preview-file). Any user who follows the README example and sets ranger-show-preview t is writing a no-op. Second, even ranger-preview-file and ranger-show-hidden, if set, are dead in dirvish mode because the ranger package is not loaded (packages.el:30 toggle is false). The user's .spacemacs lines 44-45 are thus doubly dead. Fix requires two changes: (1) correct the README intro to use ranger-preview-file (not ranger-show-preview) and add a note that ranger.el variables have no effect when ranger-override-dired is 'dirvish; (2) document the dirvish equivalents (dirvish-default-layout for preview, dired-omit-mode already handled by dirvish-enable-dired-omit).

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:42-46 — user sets ranger-override-dired 'dirvish and also ranger-show-preview t and ranger-show-hidden t
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/packages.el:30 — (ranger :toggle (not (eq ranger-override-dired 'dirvish))) — ranger package not loaded when dirvish mode is active
- /Users/jlipworth/.emacs.d/.cache/.rollback/30.1/develop/25-11-14_10.46.58/ranger-20210125.330/ranger.el — defcustom list confirms ranger-show-hidden is real (line 110) but ranger-show-preview is ABSENT; the actual variable is ranger-preview-file (line 204)
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/README.org:28,36 — README documents ranger-show-preview as a valid :variables entry in the intro section, but the variable does not exist in ranger.el

### MEDIUM · gap · effort M — No SPC m (major-mode prefix) keybindings for dired/dirvish buffers

_status: confirmed · deliverable: issue_

The layer provides no SPC m prefix in dired or dirvish buffers. All dirvish actions require knowing bare keys or going through SPC a t r. Implementation: call spacemacs/declare-prefix-for-mode 'dired-mode "m" "dirvish" and spacemacs/set-leader-keys-for-major-mode 'dired-mode inside ranger/post-init-dired. Natural SPC m entries: SPC m / (dirvish-narrow), SPC m s (dirvish-side), SPC m TAB (dirvish-subtree-toggle), SPC m g (dirvish-vc-menu when git layer present), SPC m y (dirvish-yank-menu when dirvish-yank module requested), SPC m e (dirvish-emerge-menu).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/packages.el:32-45 — only SPC a t r global prefix; no spacemacs/set-leader-keys-for-major-mode call anywhere
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/README.org:165-213 — keybinding table has no SPC m section

### LOW · cleanup · effort S — config.el has lexical-binding: nil while all other layer files use t

_status: confirmed · deliverable: issue_

config.el is the only file in the layer with lexical-binding disabled. It contains only three defvar forms, so there is no closure-related behavior to preserve. Changing the first-line cookie to lexical-binding: t; is safe and brings the file in line with modern Emacs Lisp practice. The fix can be submitted upstream as well.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/config.el:1 — ;; -*- lexical-binding: nil; -*-
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/funcs.el:1 — ;; -*- lexical-binding: t; -*-
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/packages.el:1 — ;; -*- lexical-binding: t; -*-
- git -C /Users/jlipworth/.emacs.d show syl20bnr/develop:layers/+tools/ranger/config.el — upstream has the same nil; fork could fix locally

### LOW · gap · effort S — Missing layers.el — no inter-layer dependency declarations

_status: confirmed · deliverable: issue_

The helm integration uses a manual dotspacemacs-configuration-layers memq check, which is the only such pattern in the codebase. A layers.el should be added with an optional helm dependency expressed via configuration-layer/declare-layer-dependencies. If dirvish-vc integration is added, a git layer conditional dependency should also be declared there.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/ — no layers.el file (confirmed by ls)
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/packages.el:82-83 — (when (memq 'helm dotspacemacs-configuration-layers) (require 'helm)) — runtime check; this pattern appears nowhere else in the layers/ tree
- /Users/jlipworth/.emacs.d/layers/+lang/python/layers.el — python has a layers.el declaring LSP dependency

### LOW · bug · effort S — README keybindings table omits SPC a t r s (dirvish-side), SPC a t r q (dirvish-quick-access), SPC a t r f (dirvish-fd)

_status: confirmed · deliverable: issue_

Three leader-key bindings set in packages.el are undocumented: SPC a t r s (dirvish-side), SPC a t r q (dirvish-quick-access), SPC a t r f (dirvish-fd). These should be added to the global keybindings table at lines 170-174 of README.org, clearly labeled with the (dirvish only) qualifier, matching the style of the existing SPC a t r r and SPC a t r d entries.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/packages.el:38-40 — atrs dirvish-side, atrq dirvish-quick-access, atrf dirvish-fd all bound
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/README.org:170-174 — only SPC a t r r and SPC a t r d appear in the global keybindings table; dirvish-specific table (lines 203-213) omits these three SPC a t r entries entirely

### LOW · modernization · effort S — No layer variable or documentation for dirvish-large-directory-threshold

_status: adjusted · deliverable: issue_

dirvish-large-directory-threshold exists in the installed package (dirvish.el:106) and when non-nil causes dirvish to open large directories using dirvish-fd rather than dired listing (for performance). The auditor incorrectly described it as 'skip heavy attributes like vc-state' — the actual behavior is to switch the listing backend to fd for directories exceeding the threshold file count. It defaults to nil (disabled). It is a practically useful variable for users with large project trees and should be added as a layer variable in config.el with nil default and documented in the README Dirvish options section. The suggested default of 10000 from the audit is reasonable though not required.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.1/develop/dirvish-20250504.807/dirvish.el:106 — (defcustom dirvish-large-directory-threshold nil ...) confirmed present
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/config.el — only dirvish-enable-dired-omit exposed as a layer variable; no dirvish-large-directory-threshold
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/README.org — no mention of dirvish-large-directory-threshold

### LOW · gap · effort M — No tests for any ranger or dirvish layer behavior

_status: confirmed · deliverable: issue_

There are no ERT tests for the ranger layer. The most valuable tests would cover: (1) ranger//apply-override-dired enables the correct override mode for each of the three values of ranger-override-dired; (2) ranger/dirvish-full-layout does not error when dirvish-default-layout is nil and when it is already set to a non-nil value; (3) ranger//toggle-ranger-deer does not error when called outside ranger-mode (it currently falls through to the else branch and calls deer/ranger). These can be written with cl-letf mocking. Create tests/layers/+tools/ranger/ with a Makefile and ERT test file.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*ranger*' returned nothing
- /Users/jlipworth/.emacs.d/tests/layers/ contains only +distribution and +lang/python
- /Users/jlipworth/.emacs.d/layers/+tools/ranger/funcs.el — ranger//apply-override-dired, ranger//toggle-ranger-deer, ranger/dirvish-full-layout are all unit-testable

## Additional gaps caught in verification

- **(medium/bug)** README recommends ranger-show-preview as a valid :variables entry but the variable does not exist — The README intro and LAYERS.org both document ranger-show-preview as a valid layer variable. It has never existed in ranger.el (the real variable is ranger-preview-file). Any user following the example ends up setting a no-op variable. The auditor folded this into finding #1 but framed it as a dirvish-mode concern, missing that it affects ranger-mode users equally. Fix: replace ranger-show-preview with ranger-preview-file in README.org:36 and LAYERS.org:3179. The intro sentence at README.org:28 ("set ranger-show-preview to t") should be updated to "set ranger-preview-file to t".
- **(low/gap)** README dirvish-attributes example silently recommends vc-state which requires dirvish-vc to be auto-triggered via attribute list — The README recommends including vc-state in dirvish-attributes. This does work at runtime (dirvish auto-requires dirvish-vc when vc-state is detected in the attribute list, per dirvish--libraries), but the README does not explain this dependency. Users who set vc-state via customize before the first dirvish session opens will have it work correctly. However, the README should note that vc-state, git-msg, and git-diff attributes come from the dirvish-vc extension module, which is auto-loaded on first dirvish session. More importantly, no layer variable or configuration guides users to activate vc-state when the git layer is present. The layer should conditionally add vc-state to dirvish-attributes (or at least document this in README) when configuration-layer/layer-used-p 'git returns non-nil.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

