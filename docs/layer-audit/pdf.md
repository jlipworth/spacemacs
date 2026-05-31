# Layer audit: `pdf`  (`+readers/pdf`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the layer is underbuilt. Finding 1 (shadowed keybinding) and Finding 2 (:custom override) are both real correctness bugs actively harming this user's setup. The transient state inconsistency is worse than the auditor described: four annotation types are missing (not three), the hint mislabels 'at' as 'text' when it actually opens attachment-dired, and pdf-annot-add-text-annotation has no transient binding at all. The maturity rating stands as underbuilt.

## Findings

### HIGH · bug · effort S — Shadowed 'SPC m at' keybinding silently loses pdf-annot-attachment-dired

_status: adjusted · deliverable: issue_

The duplicate 'at' key means: (1) leader key SPC m a t -> add-text-annotation (second binding wins); (2) transient state 'at' -> attachment-dired (uses first binding, which is not the leader winner). These two surfaces now do different things with the same key sequence. Fix by assigning attachment-dired to a free key (e.g. 'aa') in both packages.el and funcs.el transient, fixing the README.org:166 table entry to show the correct key, and removing the duplicate leader key binding. The transient state also needs add-text-annotation added as a binding. Submit upstream.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:49 — first 'at' binding: pdf-annot-attachment-dired
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:55 — second 'at' binding: pdf-annot-add-text-annotation (this wins in the leader keymap)
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/funcs.el:98 — transient state has ('at' pdf-annot-attachment-dired) — the OPPOSITE winner to the leader key; the transient and leader key are now inconsistent with each other
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/README.org:166 — documents non-existent ~SPC m a a~ for attachments (no 'aa' binding exists anywhere in packages.el)
- Confirmed identical in upstream: git show syl20bnr/develop:layers/+readers/pdf/packages.el lines 49 and 55 are byte-for-byte the same

### HIGH · bug · effort S — :custom override silently discards the user's pdf-view-use-scaling layer variable

_status: confirmed · deliverable: issue_

The sequence: (1) Spacemacs startup calls set-default pdf-view-use-scaling t from the user's layer variable; (2) when the first PDF file is opened, pdf-tools loads, and use-package :custom runs customize-set-variable with nil, overwriting the user's value. This is especially harmful because the user is on macOS with a Retina display where pdf-view-use-scaling t is the correct setting. Fix: remove the :custom stanza entirely (the package default is already t); add a config.el defvar with a docstring documenting the HiDPI trade-off; if a nil guard is still wanted for non-HiDPI users, use an :init (unless (bound-and-true-p pdf-view-use-scaling) (setq pdf-view-use-scaling nil)) guard that the layer variable will override.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:127-128 — user sets (pdf :variables pdf-view-use-scaling t)
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:34 — :custom (pdf-view-use-scaling nil)
- /Users/jlipworth/.emacs.d/core/core-configuration-layer.el:1600 — set-default called at layer declaration time (eager, during startup)
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/pdf-tools-20260102.1101/pdf-view.el:102 — defcustom default is t, confirming the layer's nil is also fighting the package default
- use-package :custom runs when the package loads (lazily, on first PDF open), after set-default has already run — so customize-set-variable overwrites the user's value

### MEDIUM · gap · effort S — Missing config.el — no formal layer variable declarations

_status: confirmed · deliverable: issue_

Create layers/+readers/pdf/config.el declaring at minimum (defvar pdf-view-use-scaling t "Whether images should be scaled for HiDPI displays. Set to nil if you experience performance problems after zooming.") following the djvu layer pattern. This makes the variable discoverable via C-h v, enables Spacemacs layer variable validation, and documents the trade-off. The defvar in config.el is also the prerequisite fix for Finding 2.

**Evidence:**
- find /Users/jlipworth/.emacs.d/layers/+readers/pdf — only funcs.el, packages.el, README.org exist; no config.el
- /Users/jlipworth/.emacs.d/layers/+readers/djvu/config.el — sibling layer has config.el with a single defvar as the pattern
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:34 — pdf-view-use-scaling hard-coded in :custom with no corresponding defvar anywhere

### MEDIUM · gap · effort S — Transient state hint omits four annotation types and mislabels a fifth

_status: adjusted · deliverable: issue_

The transient state is missing four leader-key annotation bindings (ah highlight, ao strikeout, as squiggly, au underline) and additionally mislabels 'at' in its hint as 'text' when the transient actually calls pdf-annot-attachment-dired. pdf-annot-add-text-annotation has no transient binding. Extend the transient state body in funcs.el to add ah/ao/as/au bindings, correct the '[_at_] text' label to '[_at_] attach', and add '[_aT_]' or similar for text annotation. The annotation section of the hint may need a second row. The auditor's count of 'three missing' was an undercount; ao (strikeout) is also absent.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/funcs.el:59 — hint shows '[_at_] text' in Annotations column
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/funcs.el:98 — actual transient binding: ('at' pdf-annot-attachment-dired :exit t) — NOT text annotation
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:50 — 'ah' (highlight) bound as leader key but absent from transient state
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:53 — 'ao' (strikeout) bound as leader key but absent from transient state
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:54 — 'as' (squiggly) bound as leader key but absent from transient state
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:56 — 'au' (underline) bound as leader key but absent from transient state
- grep for 'text-annotation' in funcs.el returns empty — pdf-annot-add-text-annotation has no transient binding at all

### LOW · bug · effort S — README documents ghost binding SPC m a a that does not exist

_status: confirmed · deliverable: issue_

Once the attachment-dired shadow is fixed (Finding 1) and the binding is moved to 'aa', the README entry will become accurate. In the interim, the entry is actively wrong — pressing SPC m a a does nothing. Update README.org:166 to reflect the actual key once Finding 1 is resolved.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/README.org:166 — '~SPC m a a~ | List all attachments in a dired buffer'
- grep for '"aa"' in packages.el returns empty — no 'aa' binding exists
- Upstream README.org:166 is byte-for-byte identical (confirmed via git diff)

### LOW · modernization · effort M — pdf-view-restore is less capable than saveplace-pdf-view for position persistence

_status: confirmed · deliverable: issue_

Consider replacing or supplementing pdf-view-restore with saveplace-pdf-view. saveplace-pdf-view persists page, scale, and scroll position via Emacs built-in save-place; stores state in save-place-file rather than next to the PDF; and is more actively maintained. Implementation: add saveplace-pdf-view to pdf-packages, enable save-place-mode and saveplace-pdf-view-mode in the init function, gate behind a layer variable (e.g. pdf-position-store, default 'restore for backward compat). Update README.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:25-26 — layer includes pdf-view-restore
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/README.org:90-95 — README itself warns about the Calibre storage problem
- pdf-view-restore on MELPA — last release 2019-09-04 (package timestamp from elpa: pdf-view-restore-20190904.1708)

### LOW · enhancement · effort M — No optional pdf-continuous-scroll-mode integration

_status: confirmed · deliverable: issue_

Add an optional pdf-continuous-scroll-mode package gated behind a layer variable (e.g. pdf-enable-continuous-scroll nil). When enabled: add pdf-continuous-scroll-mode to pdf-packages, hook it to pdf-view-mode-hook, and document the SVG requirement in README. This is commonly requested for reading multi-page academic papers.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/packages.el:25-26 — only pdf-tools and pdf-view-restore; no continuous scroll package
- No mention in README.org (grep for 'continuous' returns empty)

### LOW · enhancement · effort M — No org-noter integration hint or optional package

_status: confirmed · deliverable: issue_

Add an optional org-noter package gated on a layer variable (pdf-org-noter-support nil). When enabled: wire SPC m N to org-noter in pdf-view-mode, document org-noter-set-notes-window-location and org-noter-set-start-location. Alternatively, document the integration in README.org as a Tips subsection without adding a package dependency. The current README silence on this common research workflow is a notable gap given the user's LaTeX context.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+readers/pdf/README.org — grep for 'org-noter' returns empty
- /Users/jlipworth/GNU_files/.spacemacs:121-125 — user enables latex layer, indicating academic/research use where PDF annotation workflows matter

## Additional gaps caught in verification

- **(low/bug)** README leader-keys table documents SPC m s (wrong) for pdf-occur; actual key is SPC m s s — The leader-keys table at README.org:188 lists SPC m s for pdf-occur, but the actual binding in packages.el is 'ss' (SPC m s s). The prose at README.org:84 correctly says SPC m s s. Fix: update README.org:188 to ~SPC m s s~. This is a one-character typo but causes user confusion since SPC m s is a prefix key for slice operations.
- **(medium/bug)** Transient state hint at funcs.el:59 mislabels 'at' as 'text' when it actually calls attachment-dired — In the transient state (funcs.el), the hint line 59 labels 'at' as 'text' implying pdf-annot-add-text-annotation, but the transient binding (line 98) maps 'at' to pdf-annot-attachment-dired. This is an active mislabel: a user seeing the hint will get the wrong action. This is a direct consequence of Finding 1 (the shadow leaves the transient state with the old first-binding's intent while the hint was written for the intended text-annotation use). The fix is to: correct the hint label to 'attach' or add a new 'aT' binding for text annotation in the transient, and relabel accordingly.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

