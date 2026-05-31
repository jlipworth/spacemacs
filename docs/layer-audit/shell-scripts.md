# Layer audit: `shell-scripts`  (`shell-scripts`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Rating stands. Verification confirmed: no REPL/send bindings, no tree-sitter wiring, a real zsh-dialect bug affecting 4 of 6 dotfile patterns, the private function in the wrong place, no tests, and fish-mode is vestigial. The layer is thinner than claimed on one count (the audit overstates the zsh bug to 6 patterns when sh-mode's own sh--guess-shell already handles .zshrc and .zshenv), but this does not change the overall rating.

## Findings

### MEDIUM · bug · effort S — zsh dialect not set for standard zsh dotfiles

_status: adjusted · deliverable: issue_

The bug is real but the audit overstates its scope. Only 4 of the 6 auto-mode-alist dotfile patterns are affected: zlogin, zlogout, zpreztorc, zprofile. The other two (.zshrc and .zshenv) are already handled correctly by sh-mode's own sh--guess-shell at startup (via the pattern `[.]zsh(rc|env)?\>`). For the 4 remaining patterns, spacemacs//setup-shell's `string-match-p "\.zsh\'"` does not trigger, so they fall back to sh-mode's default shell (typically /bin/sh). Fix: broaden the match in spacemacs//setup-shell to also cover the 4 missing basename patterns. Moving the function to funcs.el is still the correct cleanup.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/packages.el:84-91 — auto-mode-alist maps zlogin, zlogout, zpreztorc, zprofile, zshenv, zshrc to sh-mode
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/packages.el:93-97 — spacemacs//setup-shell only calls sh-set-shell for files matching \.zsh\', i.e. files ending in .zsh
- /opt/homebrew/share/emacs/30.2/lisp/progmodes/sh-script.el:1490-1492 — sh--guess-shell already matches [.]zsh(rc|env)?\> so .zshrc and .zshenv get the correct 'zsh' dialect via sh-mode's own startup call at line 1607; zlogin, zlogout, zpreztorc, zprofile are NOT matched by sh--guess-shell

### MEDIUM · gap · effort M — No send-to-shell (REPL) keybindings despite built-in sh-send support

_status: adjusted · deliverable: issue_

Confirmed: the layer exposes none of the send-to-shell functions under any SPC m prefix. The functions exist in Emacs 30.2 (verified on this machine). The 'since Emacs 29' claim is imprecise — the functions carry no :version tag and appear in no NEWS file, but they exist in the installed Emacs 30.2. The improvement is valid: add SPC m s prefix for sh-mode with bindings to sh-send-line-or-region-and-step, sh-cd-here, and sh-show-shell at minimum.

**Evidence:**
- /opt/homebrew/share/emacs/30.2/lisp/progmodes/sh-script.el:1441-1462 — sh-send-text, sh-cd-here, sh-send-line-or-region-and-step are defined; no :version annotation so the 'since Emacs 29' claim in the audit is unverified
- /opt/homebrew/share/emacs/30.2/lisp/progmodes/sh-script.el:444 — default binding is C-c C-n for sh-send-line-or-region-and-step
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/packages.el — grep for 'sh-send', 'ms', 'send' returns no results; SPC m s prefix is not declared

### MEDIUM · gap · effort M — bash-ts-mode (Emacs 30 built-in) not wired up

_status: confirmed · deliverable: issue_

Confirmed as stated. Emacs 30.2 ships bash-ts-mode inside sh-script.el (already used as a built-in package). The layer makes no reference to it. Adding a shell-scripts-enable-ts-mode variable and a major-mode-remap-alist entry when the bash tree-sitter grammar is available would be a straightforward improvement.

**Evidence:**
- /opt/homebrew/share/emacs/30.2/lisp/progmodes/sh-script.el:1616-1643 — bash-ts-mode is defined in sh-script.el (already a :location built-in package in the layer); activates when (treesit-ready-p 'bash) is non-nil
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/packages.el — grep for 'bash-ts-mode', 'treesit', 'ts-mode' returns no results
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/config.el — no shell-scripts-enable-ts-mode variable; confirmed by read of full file

### LOW · cleanup · effort S — Private function spacemacs//setup-shell defined inside use-package :init instead of funcs.el

_status: confirmed · deliverable: issue_

Confirmed exactly as stated. spacemacs//setup-shell is the only non-trivial function not in funcs.el. The defun is re-evaluated each time the :init block runs (i.e., once per Emacs session after the package is deferred-loaded), which is harmless but inconsistent with layer conventions. Moving it to funcs.el is a clean, low-risk change that also makes the function unit-testable.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/packages.el:93-97 — defun inside use-package sh-script :init block
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/funcs.el — all other helpers (spacemacs//shell-scripts-setup-backend, spacemacs//shell-scripts-setup-company, spacemacs/scripts-make-buffer-file-executable-maybe) live here; setup-shell is the only outlier

### LOW · bug · effort S — flycheck-bashate configured unconditionally but bashate is not installed

_status: confirmed · deliverable: issue_

Confirmed as stated. flycheck-bashate-setup is added to sh-mode-hook unconditionally. bashate binary is not present on this machine. When the binary is absent flycheck disables the checker silently, but the hook still fires on every sh-mode buffer open. Making flycheck-bashate conditional on a shell-scripts-enable-bashate variable is a valid improvement. README.org mentions bashate as a style-checking tool but gives no indication it is optional.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/packages.el:51-54 — flycheck-bashate-setup added to sh-mode-hook with no guard
- which bashate → not found (confirmed on this machine)
- /Users/jlipworth/GNU_files/.spacemacs:112-113 — shell-scripts layer is active with lsp backend

### LOW · gap · effort S — User has shfmt installed but format-on-save is not enabled and no shfmt-args configured

_status: confirmed · deliverable: md_

Confirmed as stated. All cited line numbers are correct. The user enables format-on-save for python (line 135) and rust (line 197) but not shell-scripts, and shfmt is installed. This is primarily a user-config gap, not a layer deficiency. However, the README.org genuinely lacks any documentation of shell-scripts-shfmt-args or common shfmt flag combinations, which is a real documentation gap in the layer.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:112-113 — shell-scripts-format-on-save not set (defaults to nil; confirmed by reading the file)
- /Users/jlipworth/GNU_files/.spacemacs:135 — python-format-on-save t
- /Users/jlipworth/GNU_files/.spacemacs:197 — rustic-format-on-save t
- which shfmt → /opt/homebrew/bin/shfmt version 3.13.1 (installed)
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/README.org — no 'shfmt-args' or 'shell-scripts-shfmt-args' documentation found

### LOW · gap · effort M — No layer tests exist for shell-scripts

_status: confirmed · deliverable: issue_

Confirmed. No test directory or test files exist for the shell-scripts layer. The python layer test structure (init.el + layers-ftest.el + Makefile) is the correct reference. The zsh-dialect bug in spacemacs//setup-shell would be testable with a simple ERT test.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*shell*' → no output
- /Users/jlipworth/.emacs.d/tests/layers/+lang/ → only 'python' directory exists
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ — contains init.el, layers-ftest.el, Makefile

### LOW · gap · effort M — fish-mode has no LSP backend wired (fish-lsp exists but is unacknowledged)

_status: adjusted · deliverable: issue_

Confirmed that fish-mode has no LSP backend, no keybindings prefix, and no formatter. fish-lsp (npm package fish-lsp@1.1.3) is a real, maintained language server for fish shell. The audit's evidence URL (https://github.com/nickel-lang/fish-lsp) is incorrect — nickel-lang is an unrelated configuration language project. The correct URL is https://github.com/ndonfris/fish-lsp. This does not affect the validity of the finding itself. Since fish is not installed on this machine, priority is low, but the README should at minimum document that fish-lsp exists as an optional backend.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/packages.el:56-58 — fish-mode init is a bare use-package with no keybindings, no backend, no LSP
- /Users/jlipworth/.emacs.d/layers/+lang/shell-scripts/README.org:82-84 — bash-language-server only; no mention of fish-lsp
- npm show fish-lsp → fish-lsp@1.1.3 MIT (confirmed installed on npm registry, URL: fish-lsp.dev); correct GitHub URL is https://github.com/ndonfris/fish-lsp not https://github.com/nickel-lang/fish-lsp as the audit cited
- which fish → not found (fish not installed on this machine)

## Additional gaps caught in verification

- **(low/cleanup)** after-save-hook added globally instead of as a buffer-local sh-mode-hook entry — spacemacs/scripts-make-buffer-file-executable-maybe is hooked onto the global after-save-hook rather than sh-mode-hook. This means the function runs on every buffer save across all modes, performing a major-mode check as the guard. The correct approach is to add it on sh-mode-hook so it only fires in sh-mode buffers. Because use-package :defer defers loading, the :init block runs only once (at first sh-mode load), so the hook is registered once, but it applies globally for the rest of the session. Fix: change the hook registration to (add-hook 'sh-mode-hook #'spacemacs/scripts-make-buffer-file-executable-maybe) and update funcs.el to remove the now-redundant (eq major-mode 'sh-mode) guard.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

