# Layer audit: `org`  (`+emacs/org`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The org layer is wide in package coverage (30+ optional packages) with comprehensive keybindings, transient states, and evilification. Verification confirmed the two most impactful gaps: the keybinding collision between verb and org-roam is wider than the auditor found (both 'rf' and 'ru' collide), and org-cite/citar is entirely absent despite the user having the latex layer active. The org-roam v2 evilify concern was overstated — no void-variable error occurs — but the evilified-state approach is non-standard compared to how evil-collection handles the same map. The valign/org-modern guard gap is confirmed. Missing v2 org-roam commands and the absent test suite are confirmed. Adequate rating stands: functional but with real, fixable gaps.

## Findings

### HIGH · bug · effort S — Keybinding collision: SPC m r f and SPC m r u bound by both org-roam/org-roam-ui and verb in org-mode

_status: adjusted · deliverable: issue_

Two org-mode major-mode keybinding collisions exist when multiple optional packages are co-enabled. (1) SPC m r f: set by org-roam (packages.el:989) and by verb (packages.el:1022). Since verb is listed at line 65 and org-roam at line 66, Spacemacs processes org-roam last, so org-roam-node-find wins and verb-send-request-on-point is silently dropped. (2) SPC m r u: set by verb (packages.el:1028) and by org-roam-ui (packages.el:1110). Org-roam-ui is processed last, so org-roam-ui-mode wins and verb-export-request-on-point-curl is silently dropped. In addition, the 'mr' prefix is declared as 'org-roam' (line 980) but verb's 9 keybindings also use this prefix, so which-key misleadingly shows them all under the 'org-roam' heading. Fix by rekeying verb's org-mode bindings under SPC m V (for Verb) and declaring a separate prefix, updating the README table accordingly.

**Evidence:**
- packages.el:989 — (spacemacs/set-leader-keys-for-major-mode 'org-mode "rf" 'org-roam-node-find)
- packages.el:1022 — (spacemacs/set-leader-keys-for-major-mode 'org-mode "rf" #'verb-send-request-on-point)
- packages.el:1028 — (spacemacs/set-leader-keys-for-major-mode 'org-mode "ru" #'verb-export-request-on-point-curl)
- packages.el:1110 — (spacemacs/set-leader-keys-for-major-mode 'org-mode "ru" 'org-roam-ui-mode)
- packages.el:65-66 — verb listed before org-roam in org-packages; Spacemacs processes in list order so org-roam's registrations run after verb's, meaning org-roam wins for 'rf', verb wins for 'ru' (org-roam-ui is processed after verb but after org-roam)
- packages.el:980 — (spacemacs/declare-prefix-for-mode 'org-mode "mr" "org-roam") — verb keys appear under the 'org-roam' which-key label, causing UI confusion regardless of collision winner

### HIGH · gap · effort M — No org-cite / citar integration: built-in citation system is completely absent

_status: confirmed · deliverable: both_

Org 9.5 introduced org-cite (OC) as the new built-in citation engine. The org layer has no knowledge of org-cite and the bibtex layer's org-mode integration is limited to one org-ref-insert-link keybinding that itself carries a FIXME (org-ref-completion-library no longer exists). This user has both the latex and pdf layers active, making the gap particularly impactful. A best-in-class org layer would: (1) add a layer variable org-enable-cite-support; (2) when enabled, require citar from ELPA and wire SPC m i c → citar-insert-citation and SPC m f c → citar-open-notes; (3) optionally add citar-embark if the embark layer is used. Implementation: add citar entry to org-packages with :toggle org-enable-cite-support, write org/init-citar mirroring the ob-mermaid toggle pattern, add the defvar to config.el.

**Evidence:**
- packages.el:24-72 — org-packages list contains no reference to org-cite, citar, or citar-embark
- layers/+lang/bibtex/packages.el:31,37,55,59 — bibtex layer wires only org-ref-insert-link as the org-mode citation key; no org-cite
- layers/+lang/bibtex/packages.el:67 — FIXME comment: 'org-ref-completion-library does not exist anymore' — the bibtex layer's org integration is itself broken
- README.org:93-95 — only points users to bibtex layer for citation support
- org-cite ships built-in since Org 9.5 (mid-2021) and is the upstream-endorsed citation framework
- /Users/jlipworth/GNU_files/.spacemacs:121-126 — user has the latex layer enabled, making org-cite/citar even more relevant (citar integrates uniformly across org and LaTeX)

### MEDIUM · bug · effort S — valign and org-modern-table conflict not detected or mitigated in code

_status: confirmed · deliverable: issue_

The README documents the incompatibility between valign and org-modern-table but the layer code does nothing to prevent or warn about both being enabled simultaneously. Fix: in org/init-org-modern add (when org-enable-valign (setq org-modern-table nil)) to automatically disable org-modern-table when valign is also active, plus a message informing the user. Alternatively add a startup-time check in layers.el that emits a spacemacs-warning when both variables are set. The user currently only has org-enable-valign t, so the conflict is not active, but the guard would prevent a silent misconfiguration if they later enable org-modern-support.

**Evidence:**
- packages.el:1045-1053 — org/init-valign unconditionally adds valign-mode hook to org-mode-hook
- packages.el:758-766 — org/init-org-modern unconditionally adds org-modern-mode hook to org-mode-hook with no guard for org-enable-valign
- README.org:560-562 — 'Valign and org-modern... both provide visual enhancements for org tables (if org-modern-table is non-nil), and they are not compatible with each other' — documented but not enforced
- /Users/jlipworth/GNU_files/.spacemacs:90 — user has org-enable-valign t; if they add org-enable-modern-support, both hooks fire silently

### MEDIUM · gap · effort S — org-roam missing several v2 commands: ref-find, db-sync, node-random, extract-subtree

_status: confirmed · deliverable: issue_

The org-roam keybinding set is missing several v2 commands that have been stable since the initial v2 release. Suggested additions in org/init-org-roam's :init block: SPC a o r s → org-roam-db-sync, SPC a o r n → org-roam-node-random, SPC a o r R → org-roam-ref-find, SPC a o r e e → org-roam-extract-subtree, mirrored under SPC m r prefix for org-mode. These are additive, non-breaking changes.

**Evidence:**
- packages.el:966-995 — full set of org-roam keybindings: capture, node-find, graph, node-insert, buffer-toggle, tag-add, tag-remove, alias-add, dailies navigation; no ref-find, db-sync, node-random, or extract-subtree
- org-roam v2 API includes: org-roam-ref-find, org-roam-db-sync, org-roam-node-random, org-roam-extract-subtree — all standard Zettelkasten workflow commands

### MEDIUM · gap · effort L — No layer test suite: org is the only complex emacs layer with zero functional tests

_status: confirmed · deliverable: both_

The org layer has no automated tests. The Python layer's tests/layers/+lang/python/ directory provides the template: a Makefile, an init.el, and a layers-ftest.el using ERT. Priority candidates for org layer tests: (1) verify that org-enable-valign t does not also load org-modern-table hooks when org-enable-modern-support is nil; (2) verify that all SPC m b babel bindings are registered after layer load; (3) verify that the verb/org-roam keybinding collision produces a warning or that the expected command wins; (4) verify that org-src-mode keybindings are registered. Large effort but appropriate given the layer's complexity.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests — no directory tests/layers/+emacs/org/ exists
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ contains layers-ftest.el, init.el, and Makefile — the project gold standard
- /Users/jlipworth/.emacs.d/tests/doc/org-export-ftest.el tests org doc export only, not the org layer's own package/keybinding behavior
- The org layer manages configuration for 30+ packages, three transient states, evilification of multiple mode maps, and 12+ toggle variables — high surface area for regressions

### LOW · bug · effort S — org-roam evilify targets org-roam-mode-map with incorrect approach for v2

_status: adjusted · deliverable: issue_

The auditor's claim that org-roam-mode-map 'does not exist in org-roam v2' and 'produces a void-variable error at load time' is incorrect. The installed evil-collection (version 20260304, i.e. March 2026) explicitly declares and uses org-roam-mode-map in org-roam v2. The :config block runs after org-roam is loaded, so org-roam-mode-map is defined when evilify executes. The real (minor) issues are: (a) spacemacs|hide-lighter org-roam-mode is a no-op because org-roam-mode is now a major mode, not a diminishable minor mode; (b) evilified-state-evilify-map creates an 'evilified' evil state for the buffer rather than binding to 'normal state as evil-collection does — this is a mismatch with Spacemacs's own evil-collection integration and could cause unexpected state switching. The fix is to replace the evilify call with evil-define-key on 'normal org-roam-mode-map, mirroring evil-collection-org-roam's approach. This is a low-severity cosmetic/behavioral issue, not a load-time error.

**Evidence:**
- packages.el:998 — (spacemacs|hide-lighter org-roam-mode) — org-roam-mode was a GLOBAL minor mode in v1; in v2 it is a major mode for the org-roam buffer, not a global minor mode, so hide-lighter/diminish is a no-op
- packages.el:1000-1004 — evilified-state-evilify-map org-roam-mode-map with bindings for link-hint-open-link and org-roam-buffer-refresh
- evil-collection-20260304.1628/modes/org-roam/evil-collection-org-roam.el — the 2026 evil-collection still uses org-roam-mode-map and binds keys in 'normal state, not evilified-state
- evil-collection-org-roam.el: (defconst evil-collection-org-roam-maps '(org-roam-grep-map org-roam-mode-map org-roam-node-map org-roam-preview-map)) — org-roam-mode-map exists in v2

### LOW · gap · effort S — org-appear-autoentities not set in init-org-appear: entity auto-reveal disabled

_status: adjusted · deliverable: issue_

org-appear 0.3.0+ added org-appear-autoentities (toggles visibility of Org special entities like \alpha) and org-appear-autolatex (toggles visibility of inline LaTeX fragments like $x^2$). The layer sets the three original variables to t but omits both newer ones. For this user, org-appear-autolatex is the more impactful omission since they use the latex layer. Add both (setq org-appear-autoentities t) and (setq org-appear-autolatex t) to the setq block at packages.el:1060. If intent is per-user control, declare both as layer variables in config.el with docstrings.

**Evidence:**
- packages.el:1060-1062 — setq block sets org-appear-autolinks t, org-appear-autoemphasis t, org-appear-autosubmarkers t but does NOT set org-appear-autoentities or org-appear-autolatex
- MELPA archive-contents shows org-appear version 20240716 with emacs 29.1 requirement — this is a post-0.3.0 release that includes autoentities and autolatex
- The three variables that ARE set are all t, implying intent to enable all auto-reveal features; newer variables are simply missing
- /Users/jlipworth/GNU_files/.spacemacs:121-126 — user has latex layer active, making org-appear-autolatex (LaTeX fragment toggle) particularly relevant

### LOW · gap · effort M — User config is sparse relative to available layer features: roam, modern, appear, capture templates all absent

_status: adjusted · deliverable: issue_

The user config is sparse for the installed org infrastructure. The auditor's claim that org-cliplink etc. appear in 'selected-packages' does not indicate extra user effort — package-selected-packages at line 840 is Emacs's auto-generated install record, not user choices. The core observation is still valid: no org-agenda-files, no org-capture-templates, no org-directory. Actionable suggestions: (1) set org-agenda-files to point at an actual org directory so SPC a o a works; (2) add at minimum one capture template; (3) enable org-enable-appear-support (requires no extra config and complements existing valign usage); (4) given active latex layer, consider enabling org-cite support (see finding 2). This is a dotfile improvement, not a layer defect.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:86-91 — only four org layer variables set: org-todo-dependencies-strategy, org-enable-github-support, org-enable-sticky-header, org-enable-valign
- /Users/jlipworth/GNU_files/.spacemacs:801-802 — only one with-eval-after-load 'org config block: (setq org-startup-indented t)
- No org-agenda-files, org-capture-templates, or org-directory customization in user-config (grep returns no matches)
- org-cliplink, org-download, org-mime, org-rich-yank in package-selected-packages (auto-generated list) at .spacemacs:877 — these are included by the org layer automatically, not extra user installations

## Additional gaps caught in verification

- **(medium/bug)** verb keybindings appear under 'org-roam' which-key prefix label when only verb is enabled — The verb package registers 9 keybindings under SPC m r in org-mode but never declares a prefix for that key sequence. When only verb is enabled, SPC m r shows unlabeled bindings in which-key. When both verb and org-roam are enabled, verb's commands appear under the 'org-roam' which-key label (declared at packages.el:980), actively misleading users who think org-roam is not installed. Fix: add (spacemacs/declare-prefix-for-mode 'org-mode "mr" "verb") inside org/init-verb, or better, remap verb to a distinct prefix (SPC m V) as suggested in finding 1.
- **(low/gap)** org-appear-autolatex not set: LaTeX fragment auto-reveal disabled for latex-layer users — org-appear-autolatex (added in org-appear 0.3.0) controls automatic reveal of inline LaTeX fragments when the cursor enters them. It is distinct from org-appear-autoentities (which handles special entities like \alpha). The installed MELPA version (July 2024) includes both. The layer sets 3 of the 5 auto-reveal variables. For a user with the latex layer active, autolatex is the more impactful gap. Add (setq org-appear-autolatex t) alongside autoentities in the setq block at packages.el:1060.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

