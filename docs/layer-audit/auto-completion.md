# Layer audit: `auto-completion`  (`auto-completion`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

Verification did not change the overall rating. The layer is functional and complete for company-mode users. All seven findings are real (one adjusted). The layer carries multi-year dead code (ac-ispell TODO, auto-complete path), stale pre-LSP defaults that affect every LSP-heavy user, no ERT coverage for its primary public API, and an unhardened company-box icon table. None of these are blockers; the worst active impact for this user is the default 200ms completion delay and 2-char prefix threshold that the README itself says to lower for LSP. The corfu/cape gap is a forward-looking architectural limitation, not a defect.

## Findings

### MEDIUM · modernization · effort S — spacemacs-default-company-backends includes stale pre-LSP backends

_status: confirmed · deliverable: issue_

For a user running LSP across all major language modes, company-semantic and company-gtags fire on every keypress against non-existent backends. The semantic layer is commented out and no GNU Global setup exists. The user can fix this by adding `spacemacs-default-company-backends '(company-files company-dabbrev)` to the auto-completion :variables block; the README shows this pattern at line 205 but does not say LSP users should do it. A layer-level improvement would be a variable (defaulting nil) to opt out of the legacy backends, with a note in the README directing LSP users to override.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/config.el:27-28: list includes company-semantic, company-gtags, company-etags
- /Users/jlipworth/GNU_files/.spacemacs:146: semantic layer is explicitly commented out with note 'Might not be necessary anymore'
- No other layer under /Users/jlipworth/.emacs.d/layers/ references company-semantic, company-gtags, or company-etags
- /Users/jlipworth/GNU_files/.spacemacs:131,141,163,171,177,105,113: python, c-c++, javascript, typescript, yaml, shell-scripts, ess all use LSP backends
- /Users/jlipworth/.emacs.d/layers/+tools/lsp/packages.el:59-62: lsp sets lsp-completion-provider to :capf (injecting company-capf) unless lsp-manage-backends-manually is set
- /Users/jlipworth/GNU_files/.spacemacs: no lsp-manage-backends-manually override found
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/README.org:197-205: shows override example but does not link it to LSP workflow

### MEDIUM · gap · effort S — User's dotfile omits LSP-recommended idle-delay and prefix-length tuning

_status: confirmed · deliverable: issue_

The layer README explicitly recommends idle-delay 0.0 and minimum-prefix-length 1 for LSP users. This user runs LSP for every major language mode but has neither override in the dotfile, so completions appear 200ms late and require 2 characters to trigger. Fix: add `auto-completion-idle-delay 0.0` and `auto-completion-minimum-prefix-length 1` to the (auto-completion :variables ...) block in .spacemacs. This is a user config gap, not a layer defect, but it is the most immediately impactful issue for this user.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:62-66: auto-completion block sets only return-key nil, tab 'complete, snippets-in-popup t
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/README.org:68,71: explicitly says 'Set to 0.0 for optimal results with lsp mode' and 'Set to 1 for optimal results with lsp mode'
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/config.el:53,56: defaults are minimum-prefix-length 2 and idle-delay 0.2s
- /Users/jlipworth/GNU_files/.spacemacs:104-113, 130-137, 139-145, 163-175, 177-179, 181-186: yaml, shell-scripts, python, c-c++, javascript, typescript, html all use LSP

### LOW · cleanup · effort S — Unresolved TODO: replace ac-ispell with company-ispell

_status: confirmed · deliverable: issue_

The ac-ispell init function (packages.el:47-54) is dead code for any company user. company-ispell ships bundled with the already-installed company package. Remove the ac-ispell package entry and its init function entirely from packages.el. Optionally wire company-ispell as an optional spell-checking backend (gated on the spell-checking layer being present) per the comment's own suggestion to move it there.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/packages.el:45: `; TODO replace by company-ispell which comes with company`
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/company-20260528.130/company-ispell.el verified present
- packages.el:28: ac-ispell toggle is `(not (eq auto-completion-front-end 'company))` — never loads for this user
- No ac-ispell or auto-complete package directory found in /Users/jlipworth/.emacs.d/elpa/30.2/develop/
- git -C /Users/jlipworth/.emacs.d show 769d54da confirms TODO has been present since initial layer commit (April 2015)

### LOW · bug · effort M — company-box icon table hardcodes all-the-icons API with no feature guard

_status: adjusted · deliverable: issue_

The all-the-icons API calls in the company-box :config block are evaluated via backtick/unquote at the time company-box loads, not silently — a missing all-the-icons function would raise a void-function error. The auditor's characterization 'fail silently' is imprecise: the failure would be loud. However, the underlying structure concern is real: there is no guard for the case where the user switches to nerd-icons. The scenario of Spacemacs defaulting to nerd-icons is currently speculative (core-dotspacemacs.el:376 still defaults to all-the-icons). For this user, the issue is completely dormant since company-box is not installed. A forward-looking fix would add `(when (featurep 'all-the-icons) ...)` around the icon table setq or add a parallel nerd-icons branch.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/packages.el:169-196: backtick form evaluates all-the-icons-octicon, all-the-icons-faicon, all-the-icons-material, all-the-icons-alltheicon at :config load time
- No `(featurep 'all-the-icons)` guard or nerd-icons fallback anywhere in the init function
- /Users/jlipworth/GNU_files/.spacemacs: auto-completion-use-company-box is not set (defaults to nil per config.el:70), so company-box is not installed
- /Users/jlipworth/.emacs.d/core/core-dotspacemacs.el:376: dotspacemacs-default-icons-font defaults to 'all-the-icons in the current codebase
- ls /Users/jlipworth/.emacs.d/elpa/30.2/develop/ | grep company-box: returns nothing — package not installed

### LOW · gap · effort M — No ERT tests for the spacemacs|add-company-backends macro

_status: confirmed · deliverable: issue_

The spacemacs|add-company-backends macro is the layer's primary public API, used in 20+ call sites across the codebase, and has no test coverage. A minimal test suite should verify: (1) calling the macro adds a company-mode hook to the target mode's hook list; (2) the generated init function sets company-backends buffer-locally to the declared backends; (3) spacemacs|disable-company removes those hooks; (4) the :variables property generates a correctly-named vars function. Template: /Users/jlipworth/.emacs.d/tests/layers/+lang/python/layers-ftest.el and its Makefile. Target location: tests/layers/+completion/auto-completion/.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*auto*' -o -name '*completion*': returns nothing
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/funcs.el:50-145: 95-line macro generating defvar/defun/add-hook forms
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ contains layers-ftest.el (84 lines) and Makefile — confirmed valid template
- grep -rn 'add-company-backends' /Users/jlipworth/.emacs.d/layers/ shows 20+ call sites across layers including org, rcirc, erc, emoji, nixos, terraform, cmake, shell, systemd, ansible

### LOW · cleanup · effort M — auto-complete front-end is effectively unmaintained but not marked as legacy

_status: confirmed · deliverable: issue_

The auto-complete code path (init-auto-complete, init-ac-ispell, init-fuzzy) is dead code for any current Spacemacs install. Upstream is actively migrating layers away from auto-complete. The README treats it as a first-class peer to company. The fix: add a deprecation notice to the README's 'Replacing company by auto-complete' section stating that the ac front-end receives no active development and new language layers will not add ac backends. Optionally, emit a warning when auto-completion-front-end is non-company.

**Evidence:**
- packages.el:27-28,35: auto-complete, ac-ispell, fuzzy all gated on front-end not being company
- No auto-complete, ac-ispell, or fuzzy packages installed in /Users/jlipworth/.emacs.d/elpa/30.2/develop/
- git -C /Users/jlipworth/.emacs.d log confirms upstream commit 797c2319 titled 'restructuredtext: migrate from auto-complete to company'
- /Users/jlipworth/.emacs.d/layers/+completion/auto-completion/README.org:167-170: 'Replacing company by auto-complete' section presents ac as a live option with no deprecation notice

### LOW · enhancement · effort L — No corfu/cape path: layer cannot serve Emacs-native CAPF completion UI

_status: confirmed · deliverable: md_

corfu+cape uses only the native completion-at-point protocol, making it lighter and better integrated with completion-styles (orderless etc.). Doom Emacs has a dedicated corfu module. There is currently no path to adopt corfu without writing a private layer. A new auto-completion-front-end 'corfu branch would need: corfu and cape added with :toggle; a corfu init function handling prefix-length, idle-delay, kind-icon; cape-company-to-capf wrappers for any language-layer company backends that lack native CAPFs; a parallel spacemacs|add-capf-backends macro or CAPF-aware extension of the existing macro. This is a large undertaking and not a gap for this user's current setup.

**Evidence:**
- packages.el:24-42: package list has company, auto-complete, and accessories — no corfu, cape, or kind-icon
- ls /Users/jlipworth/.emacs.d/elpa/30.2/develop/ | grep corfu: returns nothing
- config.el:34: auto-completion-front-end defaults to 'company
- User is on Emacs 30.2 (emacs --version confirmed earlier in session)

## Additional gaps caught in verification

- **(low/bug)** company-posframe :toggle condition is inconsistent with its :if guard — If a user enables both auto-completion-use-company-posframe t and auto-completion-use-company-box t, the :toggle condition at line 30 passes (installing company-posframe) but the :if guard at line 207 prevents it from loading. This wastes a package download and creates a confusing silent no-op. The :toggle condition should be `(and auto-completion-use-company-posframe (not auto-completion-use-company-box))` to match the :if guard. This is low priority since no reasonable user would enable both simultaneously, but it is a real inconsistency in the layer's own logic.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

