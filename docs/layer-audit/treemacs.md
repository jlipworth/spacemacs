# Layer audit: `treemacs`  (`+filetree/treemacs`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer wires up treemacs and its core extension packages competently, with correct golden-ratio exclusion, winum integration, and two project-toggle helpers. Verification confirms it is byte-for-byte identical to upstream develop. The gaps are real: treemacs-tab-bar and treemacs-nerd-icons are absent from both fork and upstream, the treemacs-collapse-dirs README/code mismatch is genuine, git-mode defaults to nil (silent no-op for most users), and lsp-treemacs-sync-mode is never enabled. The persp scoping issue is a real but lower-severity config guidance gap than the audit claimed.

## Findings

### MEDIUM · gap · effort S — treemacs-tab-bar integration absent from layer

_status: confirmed · deliverable: issue_

treemacs-tab-bar provides per-tab-bar-tab workspace scoping, parallel to the existing treemacs-persp integration. Add it to the packages list with `:toggle (eq treemacs-use-scope-type 'Tabs)` conditional, define `treemacs/init-treemacs-tab-bar` mirroring init-treemacs-persp (packages.el:104-108) calling `(treemacs-set-scope-type 'Tabs)`, expand the `treemacs-use-scope-type` defvar docstring to include `'Tabs` as a third valid value, and update the README scope-settings section. The init body is almost identical to init-treemacs-persp.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/packages.el:25-36 — treemacs-packages list has no treemacs-tab-bar entry (verified by direct read)
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/config.el:30-34 — treemacs-use-scope-type docstring lists only 'Frames and 'Perspectives; 'Tabs is not mentioned
- git -C /Users/jlipworth/.emacs.d diff HEAD syl20bnr/develop -- layers/+filetree/treemacs/ produced no output — upstream develop is identical, gap exists in both

### MEDIUM · gap · effort S — treemacs-nerd-icons not supported as an icon theme option

_status: confirmed · deliverable: issue_

Add a `treemacs-use-nerd-icons-theme` layer variable (default nil) in config.el mirroring `treemacs-use-all-the-icons-theme`. Add `(treemacs-nerd-icons :toggle treemacs-use-nerd-icons-theme)` to treemacs-packages in packages.el. Write `treemacs/init-treemacs-nerd-icons` calling `(treemacs-load-theme 'nerd-icons)` on treemacs-mode-hook, using the all-the-icons init at packages.el:114-116 as the direct template. Update README theme section. Add a docstring warning that the two themes are mutually exclusive.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/config.el:51 — only `(defvar treemacs-use-all-the-icons-theme nil ...)` exists; no nerd-icons equivalent (verified by direct read)
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/packages.el:25-36 — packages list has no treemacs-nerd-icons entry
- /Users/jlipworth/GNU_files/.spacemacs:401 — `dotspacemacs-default-icons-font 'all-the-icons` confirmed at exact line

### MEDIUM · bug · effort S — User has treemacs-persp loaded but scope silently stays 'Frames

_status: adjusted · deliverable: issue_

The user has persp-mode active (via spacemacs-layouts) and treemacs-persp is installed automatically by the layer (it is not in dotspacemacs-additional-packages — it appears in the auto-managed package-selected-packages at .spacemacs:887-888 only because Spacemacs installed it). Since treemacs-use-scope-type defaults to 'Frames and the user never sets it, treemacs-persp loads but the scope-type call is never executed. Concrete fix for user: change .spacemacs line 38 from bare `treemacs` to `(treemacs :variables treemacs-use-scope-type 'Perspectives)`. Layer fix: add a README callout that spacemacs-layouts users should set 'Perspectives, optionally add a startup warning when treemacs-persp loads but scope-type is still 'Frames. The audit's severity of 'high' is overstated — treemacs works correctly with frame scoping, just without perspective integration — 'medium' is appropriate.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:38 — bare `treemacs` symbol, no :variables (confirmed by direct read)
- /Users/jlipworth/GNU_files/.spacemacs:48-50 — spacemacs-layouts layer active, which enables persp-mode
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/packages.el:33 — `(treemacs-persp :requires persp-mode)` causes treemacs-persp to be installed whenever persp-mode is present
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/packages.el:104-108 — init-treemacs-persp only calls treemacs-set-scope-type when treemacs-use-scope-type='Perspectives; since user never sets this variable, persp-mode integration loads silently but does nothing

### MEDIUM · gap · effort S — git-mode defaults to nil — file status decorations silently disabled

_status: adjusted · deliverable: issue_

With git-mode nil, treemacs shows no file-status coloring (modified/untracked/ignored). The layer default should change to 'deferred (async, no Python requirement at the file-status level) or at minimum 'simple. The user should add `treemacs-use-git-mode 'deferred` to their dotfile treemacs variables block. Note: treemacs-magit at .spacemacs:887 is auto-installed by the layer (not user-added to additional-packages), which further confirms the user's git integration expectation.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/config.el:36 — `(defvar treemacs-use-git-mode nil ...)` confirmed by direct read
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/packages.el:86-88 — `(treemacs-git-mode -1)` executed when git-mode is not in '(simple extended deferred), confirmed by direct read
- /Users/jlipworth/GNU_files/.spacemacs:38 — bare treemacs, no variables, so git-mode stays nil
- /Users/jlipworth/GNU_files/.spacemacs:887 — treemacs-magit present in package-selected-packages (auto-installed by the layer because magit is active via the git layer), indicating git integration is relevant to this user

### LOW · bug · effort S — README documents treemacs-collapse-dirs as a layer variable but no defvar exists

_status: confirmed · deliverable: issue_

The README implies treemacs-collapse-dirs behaves like the other layer variables, but it is a raw upstream treemacs variable with no layer-level defvar or init-time logic. Users setting it via :variables will get the desired effect only because Spacemacs passes :variables through as setq calls. If upstream ever renames it, the README example silently breaks with no layer-level guard. Fix options: (a) add `(defvar treemacs-collapse-dirs 3 ...)` in config.el to formally own the variable (matching the README promise), or (b) remove it from the README and redirect users to dotspacemacs/user-config. Option (a) is the cleaner approach and matches the pattern of all other layer variables.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/README.org:113-120 — documents `treemacs-collapse-dirs` as a layer variable with a :variables example (confirmed by direct read)
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/config.el — grep confirms zero occurrences of `treemacs-collapse-dirs` in config.el
- /Users/jlipworth/.emacs.d/layers/+filetree/treemacs/packages.el — grep confirms zero occurrences of `treemacs-collapse-dirs` in packages.el

### LOW · gap · effort S — lsp-treemacs-sync-mode never enabled despite lsp + treemacs both being active

_status: confirmed · deliverable: issue_

`lsp-treemacs-sync-mode` ensures adding/removing projects in treemacs automatically registers/unregisters them as LSP workspace folders. It is currently a silent gap for users running both layers. The cleanest fix is adding an optional variable `treemacs-use-lsp-sync` (default nil) to the treemacs layer that calls `(lsp-treemacs-sync-mode 1)` in the treemacs :config block when both lsp and treemacs are active. Alternatively, this is a one-liner addition to the lsp layer's lsp-treemacs init function.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/lsp/packages.el:95-96 — `(defun lsp/init-lsp-treemacs () (use-package lsp-treemacs :defer t))` with no sync-mode call (confirmed by direct read)
- /Users/jlipworth/GNU_files/.spacemacs:70-76 — user has lsp layer active with multiple backends
- /Users/jlipworth/GNU_files/.spacemacs:38 — treemacs layer active
- grep -n 'lsp-treemacs-sync\|sync-mode' in lsp/packages.el produced no output — confirmed absent

## Additional gaps caught in verification

- **(low/bug)** treemacs-use-icons-dired defaults to t but user runs dirvish replacing dired — When `ranger-override-dired 'dirvish` is set, dirvish takes over directory browsing and uses `dirvish-mode` rather than raw `dired-mode`. The `treemacs-icons-dired-mode` hook is attached to `dired-mode`, which may not fire for dirvish buffers. This could result in icons being silently absent in directory views. The user should set `treemacs-use-icons-dired nil` in their treemacs :variables block, or the layer README should document the incompatibility. Low severity because it degrades icon display in dired buffers only, not treemacs itself.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

