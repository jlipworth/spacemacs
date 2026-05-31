# Layer audit: `vimscript`  (`+lang/vimscript`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

The layer is genuinely underbuilt: a phantom non-LSP backend, no SPC m menu, no formatter, no tree-sitter integration, and no tests. The upstream-delta claim (identical to syl20bnr/develop) is verified by md5 checksums. Maturity rating stands, though the hook-placement finding is weaker than claimed.

## Findings

### HIGH · bug · effort S — company-vimscript backend is a phantom — no such package exists

_status: confirmed · deliverable: issue_

Verified: company-vimscript does not exist on MELPA, GNU ELPA, or nongnu ELPA. When the lsp layer is absent (the default case), vimscript-backend resolves to 'company-vimscript, the setup-company function silently skips (only the 'lsp branch does anything), and the user gets zero completion with no warning. Fix: rename the fallback to 'plain, add a company-dabbrev-code or company-keywords branch in setup-company, and update the docstring and README to remove the fiction of a company-vimscript package.

**Evidence:**
- layers/+lang/vimscript/config.el:28: vimscript-backend defaults to 'company-vimscript when lsp layer absent
- layers/+lang/vimscript/funcs.el:24-31: spacemacs//vimscript-setup-company only activates company-capf for the 'lsp branch; no branch for 'company-vimscript
- MELPA archive at /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/melpa/archive-contents: no entry for company-vimscript
- GNU and nongnu ELPA archives: also contain no company-vimscript entry
- layers/+lang/vimscript/packages.el:24-30: package list is company, flycheck, vimrc-mode, ggtags, dactyl-mode — no company-vimscript
- README.org:34-43: describes company-vimscript as 'very limited IDE capabilities' as if it were functional, but no such package exists

### MEDIUM · gap · effort S — No SPC m major-mode menu — zero layer-specific keybindings

_status: confirmed · deliverable: issue_

Confirmed: grep of all three elisp files finds no spacemacs/set-leader-keys-for-major-mode calls. The README explicitly punts to the LSP layer. At minimum, a SPC m g d / SPC m g r / SPC m h h grouping with which-key prefix declarations would make LSP features discoverable within the mode. This is consistent with the lua, python, and other simple language layers.

**Evidence:**
- layers/+lang/vimscript/packages.el: no call to spacemacs/set-leader-keys-for-major-mode anywhere
- layers/+lang/vimscript/funcs.el: no keybinding definitions
- layers/+lang/vimscript/config.el: no keybinding definitions
- README.org: no Key bindings section exists
- README.org:66-69: directs users to the LSP layer for all keybindings, providing no discovery path for vimscript-specific functionality

### MEDIUM · gap · effort M — No formatter wired in; user has noted the gap explicitly

_status: confirmed · deliverable: issue_

Confirmed: user's .spacemacs at /Users/jlipworth/GNU_files/.spacemacs lines 116-118 explicitly notes the gap. The layer has no formatter integration of any kind. The auditor's apheleia approach is reasonable; the shell-scripts layer's formatter variable pattern is a good model to follow.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:116: comment ';; no formatting supported by lsp' directly above vimscript layer entry at line 117
- layers/+lang/vimscript/packages.el: no reference to format, apheleia, prettier, or any formatter
- lsp-vimscript.el: lsp-clients-vim-initialization-options confirms vim-language-server does not expose textDocument/formatting capability

### MEDIUM · modernization · effort M — vim-language-server is unmaintained; no upgrade path documented

_status: adjusted · deliverable: issue_

The core claim is confirmed: vim-language-server (iamcco/vim-language-server) is unmaintained and the README gives no warning. One important correction to the auditor's detail: lsp-mode's lsp-vimscript.el already registers vimscript-ts-mode as a supported major-mode (line 64), so the claim that 'lsp-mode will need a new client registration' is incorrect — the lsp-mode client already supports the transition. What IS missing from the Spacemacs layer is (a) a vimscript-lsp-server variable for switching, (b) a README caveat about server maintenance status, and (c) integration of vimscript-ts-mode (see missed findings).

**Evidence:**
- lsp-vimscript.el at /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-vimscript.el:53-56: lsp-mode hardcodes 'vim-language-server as the npm package name
- MELPA archive entry for dactyl-mode shows last update 2014-09-06, consistent with project stagnation pattern
- lsp-vimscript.el:64: client already registers both vimrc-mode and vimscript-ts-mode as major-modes — lsp-mode is already prepared for a ts-mode successor
- README.org:62-64: install instruction is npm install -g vim-language-server with no maintenance caveat

### LOW · cleanup · effort S — LSP launched from vimrc-mode-hook instead of vimrc-mode-local-vars-hook

_status: adjusted · deliverable: issue_

The auditor correctly identifies that lua, python, c-c++, java, and javascript use the local-vars-hook for setup-backend, and vimscript does not. However: (1) the majority of +lang layers (24 of 39) also use the raw mode-hook and have not been flagged; (2) lsp-deferred's run-with-idle-timer 0 mechanism means the server does not actually start until Emacs is idle, by which time hack-local-variables has already fired — so the practical root-miscalculation risk is minimal. This is a consistency cleanup worth aligning on the modern pattern, but not a high-severity bug. The auditor's secondary claim that the company setup hook 'should be moved to local-vars-hook symmetrically' is incorrect: spacemacs|add-company-backends auto-wires a per-buffer init function to the mode-hook, which is the macro's intended usage pattern.

**Evidence:**
- layers/+lang/vimscript/packages.el:45-50: spacemacs//vimrc-mode-hook calls spacemacs//vimscript-setup-backend (lsp-deferred) and is added to vimrc-mode-hook
- Survey of 39 +lang layers: 24 use raw mode-hook for setup-backend (shell-scripts:98, elm:53, ruby:102+297, rust:50, php:75, kotlin:48, nim:47, perl5:61, clojure:394, crystal:55, fsharp:55, json:53, latex:70); 15 use local-vars-hook
- lsp-mode/lsp-mode.el:9977-9991: lsp-deferred uses run-with-idle-timer 0, which defers startup until the event loop is idle — after hack-local-variables has already run synchronously
- layers/+spacemacs/spacemacs-defaults/config.el:288: hack-local-variables-hook fires spacemacs//run-local-vars-mode-hook, which runs synchronously before any idle timers

### LOW · gap · effort M — No Vim9script file-extension or syntax support

_status: adjusted · deliverable: issue_

Confirmed: neither the layer nor vimrc-mode handles .vim9 files. However the auditor's framing misses a more modern angle: vimscript-ts-mode (MELPA, October 2024, requires Emacs 29.1) provides tree-sitter-based VimScript highlighting that handles Vim9, and the lsp-mode client already lists it as a supported major-mode. The stopgap of adding .vim9 to vimrc-mode :mode is still valid and easy, but the better fix is to integrate vimscript-ts-mode (see missed findings).

**Evidence:**
- layers/+lang/vimscript/packages.el:41-42: only .vim[rc]? and _vimrc patterns registered; no .vim9
- vimrc-mode autoloads at /Users/jlipworth/.emacs.d/elpa/30.2/develop/vimrc-mode-20250128.635/vimrc-mode-autoloads.el:14-16: package itself registers .vim, [._]?g?vimrc, .exrc — no vim9 coverage
- lsp-vimscript.el:64: vimscript-ts-mode is already in the lsp-mode client's major-modes list, and nverno/vimscript-ts-mode on MELPA (20241020) supports Vim9 syntax

### LOW · cleanup · effort S — dactyl-mode targets dead software (Pentadactyl/Vimperator, EOL ~2017)

_status: confirmed · deliverable: issue_

Confirmed. dactyl-mode is last-updated 2014 on MELPA, Pentadactyl/Vimperator are dead (Firefox dropped XUL extensions in 2017), and it is wired unconditionally. A vimscript-enable-dactyl-mode variable defaulting to nil, with the :toggle keyword in the package declaration, would clean this up without breaking the one-in-a-million user who still has legacy .penta files.

**Evidence:**
- layers/+lang/vimscript/packages.el:52-60: dactyl-mode unconditionally registered for pentadactylrc, vimperatorrc, _pentadactylrc, _vimperatorrc, .penta, .vimp
- MELPA archive entry at /Users/jlipworth/.emacs.d/elpa/30.2/develop/archives/melpa/archive-contents line 997: dactyl-mode version 20140906.1725 — last updated 2014-09-06, over 11 years ago
- README.org:15: 'This layer adds support for vimscript and pentadactyl config files' — no historical caveat
- Installed at /Users/jlipworth/.emacs.d/elpa/30.2/develop/dactyl-mode-20140906.1725/ confirming it is loaded by default for all users

### LOW · gap · effort M — No layer tests

_status: confirmed · deliverable: issue_

Confirmed: no test directory exists. The two functions in funcs.el are short and testable. The phantom backend bug (finding #2) is the clearest example of what a test suite would have caught. Minimum viable test: (1) vimscript-backend defaults, (2) setup-company non-lsp branch behavior, (3) setup-backend lsp guard.

**Evidence:**
- /Users/jlipworth/.emacs.d/tests/layers/+lang/: only python/ subdirectory exists — no vimscript/ subdirectory
- layers/+lang/vimscript/funcs.el: two functions (spacemacs//vimscript-setup-company, spacemacs//vimscript-setup-backend) both trivially testable in isolation
- The phantom company-vimscript bug (finding #2) would have been caught by a test checking the non-lsp branch of setup-company

## Additional gaps caught in verification

- **(medium/modernization)** vimscript-ts-mode on MELPA is completely unintegrated despite Emacs 30 tree-sitter support — nverno/vimscript-ts-mode (MELPA, October 2024, Emacs 29.1+) provides tree-sitter-based VimScript syntax highlighting including Vim9script. The user is on Emacs 30.2 which ships tree-sitter built-in. lsp-mode already registers vimscript-ts-mode as a supported major-mode for the vimls LSP client. The Spacemacs vimscript layer does not declare vimscript-ts-mode as a package, does not optionally enable it, and provides no treesitter-auto hook. The fix is: (1) add (vimscript-ts-mode :requires vimrc-mode) to vimscript-packages with a :toggle on (treesit-available-p); (2) add vimscript-ts-mode to the :mode list; (3) wire vimrc-mode-local-vars-hook hooks for the ts-mode variant; (4) update README. This is the same pattern used by python-ts-mode and javascript-ts-mode in other layers.
- **(low/bug)** vimrc-mode :mode regex silently excludes .vimrc despite layer's stated intent — The :mode regex "\\.vim[rc]?\\'" was presumably intended to match .vimrc and .vim, but [rc]? is a character class (matching a single optional 'r' or 'c'), not the literal string 'rc'. The correct regex to match both .vim and .vimrc would be "\\.vimrc?\\'" (making the 'c' optional after 'vimr'). In practice this is masked by vimrc-mode's own autoload registration which catches .vimrc via [._]?g?vimrc pattern, so users do not see a regression. The .vimr and .vimc patterns that this regex does match are likely unintentional. Fix: replace the regex with "\\.vim\\'" (plain .vim files) and "\\.vimrc\\'" (explicit .vimrc), dropping the confusing character class.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

