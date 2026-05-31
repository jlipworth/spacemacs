# Layer audit: `html`  (`+lang/html`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the original rating. Every substantive finding held up: two confirmed runtime bugs (impatient-mode keybinding loop; yasnippet hook list using bare mode symbols), a high-severity stale README (deprecated LSP packages), no tree-sitter integration on an Emacs 30.2 host where both css-ts-mode and html-ts-mode are confirmed available, no format-on-save variable despite the user using it for every peer layer, no eglot path despite an eglot layer existing, and zero tests. Three additional concrete bugs in the README were also found that the auditor missed. The layer is identical to upstream, meaning none of these issues are fixed anywhere.

## Findings

### HIGH · bug · effort S — README documents deprecated LSP server npm packages

_status: confirmed · deliverable: issue_

Replace both npm install lines with a single: npm install -g vscode-langservers-extracted. Also note that lsp-mode can auto-install via M-x lsp-install-server RET css-ls RET / html-ls RET. The json layer in this same repo already has the correct instruction, making this inconsistency visible to users comparing layers.

**Evidence:**
- layers/+lang/html/README.org:91-100: instructs npm i -g vscode-css-languageserver-bin and npm install -g vscode-html-languageserver-bin.
- layers/+lang/html/../../../+lang/json/README.org:87 in same repo already documents npm install -g vscode-langservers-extracted — the correct current package.
- elpa/30.2/develop/lsp-mode-20260518.1214/lsp-css.el:238-240: lsp-mode's installer uses :npm :package vscode-langservers-extracted :path vscode-css-language-server.
- elpa/30.2/develop/lsp-mode-20260518.1214/lsp-html.el:199-201: similarly uses vscode-langservers-extracted.

### HIGH · gap · effort M — No tree-sitter mode integration despite css-ts-mode and html-ts-mode being built into Emacs 29+

_status: confirmed · deliverable: both_

Add css-ts-mode and html-ts-mode support gated on a layer variable html-enable-ts (default (treesit-available-p)). Both modes are built-in and need no extra packages (:location built-in). Wire emmet-mode, company-web, evil-matchit, flycheck, smartparens, and SPC m key prefixes to the ts variants in parallel with classical modes. When Emacs 31 ships mhtml-ts-mode, add it similarly.

**Evidence:**
- emacs --batch -Q: (require 'css-mode) (fboundp 'css-ts-mode) → t; (fboundp 'html-ts-mode) → t; (treesit-available-p) → t — confirmed on user's Emacs 30.2.
- No reference to css-ts-mode or html-ts-mode anywhere in layers/+lang/html/*.el (confirmed with grep).
- css-ts-mode is built into Emacs 30 inside css-mode.elc at /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/textmodes/css-mode.elc.

### MEDIUM · bug · effort S — Bug: impatient-mode keybinding loop always targets web-mode, never css-mode

_status: confirmed · deliverable: issue_

Replace the hard-coded 'web-mode symbol inside the dolist body with the loop variable `mode`: (spacemacs/set-leader-keys-for-major-mode mode "I" 'spacemacs/impatient-mode). One-character fix. Upstream has the same bug and should receive the fix as a PR.

**Evidence:**
- layers/+lang/html/packages.el:143-148: dolist iterates over (web-mode css-mode) but the body hard-codes 'web-mode — the loop variable `mode` is never referenced, so (spacemacs/set-leader-keys-for-major-mode 'web-mode ...) runs twice and css-mode never receives SPC m I.
- README.org:107 says 'You may wish to enable impatient mode in referenced CSS files too' — implies css-mode should have the binding, confirming the intent was to cover both modes.
- git diff syl20bnr/develop -- layers/+lang/html/ produces no output; same bug is in upstream.

### MEDIUM · bug · effort S — Bug: yasnippet hook list uses bare mode symbols instead of hook symbols, missing pug/web/html hooks

_status: adjusted · deliverable: issue_

The auditor correctly identified jade-mode but did not call out that slim-mode has the identical bug (bare symbol, not slim-mode-hook). The fix is to rewrite the list to: (css-mode-hook html-mode-hook pug-mode-hook sass-mode-hook scss-mode-hook slim-mode-hook web-mode-hook). Severity stays medium because css-mode-hook is correct and the affected modes (pug, slim) are less commonly used, but web-mode-hook being absent means the most-used HTML editing mode gets no snippets.

**Evidence:**
- layers/+lang/html/packages.el:252-254: (spacemacs/add-to-hooks 'spacemacs/load-yasnippet '(css-mode-hook jade-mode slim-mode)) — spacemacs/add-to-hooks calls (add-hook hook fun) on each element; 'jade-mode and 'slim-mode are mode symbols, not hook symbols, so add-hook silently does nothing for those two entries.
- line 56 of same file: (add-hook 'slim-mode-hook ...) — the rest of the file uses slim-mode-hook correctly, confirming the bare slim-mode in the yasnippet list is a mistake.
- jade-mode does not exist as a package; pug-mode replaced it. The hook should be pug-mode-hook.
- web-mode-hook and html-mode-hook are absent; web-mode does NOT derive from prog-mode (confirmed via (get 'web-mode 'derived-mode-parent) → nil), so auto-completion layer's prog-mode-hook does not cover it.
- yasnippet-snippets installs snippets for web-mode at elpa/30.2/.../yasnippet-snippets-20251215.1231/snippets/web-mode but those snippets are never loaded.

### MEDIUM · gap · effort S — No `html-fmt-on-save` variable — user silently defaults to web-beautify with no auto-format

_status: confirmed · deliverable: issue_

Add html-fmt-on-save (boolean, default nil) in config.el. In packages.el, inside html/pre-init-prettier-js and html/pre-init-web-beautify, check this variable and add before-save-hook entries. The user's dotfile shows they use prettier+fmt-on-save for JS and TS; the html layer gives them no mechanism to achieve the same for HTML/CSS without custom code.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:181-186: html layer variables block sets css-enable-lsp, less-enable-lsp, scss-enable-lsp, html-enable-lsp but no web-fmt-tool and no fmt-on-save variable.
- /Users/jlipworth/GNU_files/.spacemacs:165-166: javascript layer sets javascript-fmt-tool 'prettier and javascript-fmt-on-save t.
- /Users/jlipworth/GNU_files/.spacemacs:172-173: typescript layer sets typescript-fmt-tool 'prettier and typescript-fmt-on-save t.
- layers/+lang/html/config.el: no fmt-on-save variable defined anywhere (grep confirmed).
- layers/+lang/python/config.el:58: python-format-on-save is a documented layer variable; layers/+lang/typescript/config.el:26: typescript-fmt-on-save exists.

### MEDIUM · gap · effort M — No eglot backend option — layer only supports lsp-mode

_status: confirmed · deliverable: both_

Introduce html-backend accepting 'lsp (default when lsp layer active) or 'eglot. In funcs.el dispatch between (eglot-ensure) and (lsp-deferred). Update layers.el to conditionally declare lsp layer dependency. The four boolean enable-lsp variables can remain for backward compatibility but should be deprecated in favor of html-backend.

**Evidence:**
- layers/+lang/html/funcs.el:65-78: both spacemacs//setup-lsp-for-web-mode-buffers and spacemacs//setup-lsp-for-html-buffer unconditionally call (lsp-deferred).
- layers/+lang/html/config.el:32-43: no html-backend variable; four boolean enable-lsp vars instead.
- layers/+tools/eglot/packages.el exists in this fork (confirmed via find), but html layer does not reference it.
- layers/+lang/fsharp/packages.el: fsharp layer conditionally calls eglot-ensure when fsharp-backend is 'eglot, showing the pattern works in this codebase.

### LOW · modernization · effort M — sass-mode is unmaintained (last commit 2019-05-02) and MELPA may drop it

_status: confirmed · deliverable: issue_

Gate sass-mode behind an opt-in layer variable (html-enable-sass-mode, default nil) since .sass (indented Sass) is rare. For existing users who need it, the fallback is available. For .scss, scss-mode or css-ts-mode is the right choice. Add a code comment noting the unmaintained status.

**Evidence:**
- elpa/30.2/develop/sass-mode-20190502.53: MELPA version frozen at 20190502, confirming last release 2019-05-02.
- layers/+lang/html/packages.el:40-41: sass-mode listed without :location specification (uses MELPA).
- Modern Sass/SCSS tooling has converged on SCSS syntax; css-ts-mode handles .scss in Emacs 30.

### LOW · cleanup · effort S — lexical-binding is nil in packages.el, config.el, and funcs.el

_status: confirmed · deliverable: issue_

Switch all three files to lexical-binding: t. The code has no dynamic-binding idioms. Test after with make -C tests/core test. This is consistent with the upstream direction (layers.el already uses t).

**Evidence:**
- layers/+lang/html/packages.el:1: -*- lexical-binding: nil; -*-
- layers/+lang/html/config.el:1: -*- lexical-binding: nil; -*-
- layers/+lang/html/funcs.el:1: -*- lexical-binding: nil; -*-
- layers/+lang/html/layers.el:1: -*- lexical-binding: t; -*- — already uses lexical binding.

### LOW · gap · effort L — No layer tests

_status: confirmed · deliverable: issue_

Create tests/layers/+lang/html/ with a Makefile, init.el, and layers-ftest.el containing ERT tests that verify: web-mode auto-mode-alist entries, css-mode keybinding registrations, that SPC m r r resolves to web-mode-element-rename, and that LSP hooks are added when html-enable-lsp is non-nil.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*html*' returns nothing.
- tests/layers/+lang/python/ contains Makefile, init.el, layers-ftest.el — the only language layer with functional tests.

## Additional gaps caught in verification

- **(medium/bug)** slim-mode bare symbol (not slim-mode-hook) in yasnippet list — same bug as jade-mode but not called out — This is part of finding #2 but was not named as a separate broken entry. The fix must change both jade-mode → pug-mode-hook AND slim-mode → slim-mode-hook in the same list. Any implementer reading only the auditor's finding would fix jade-mode and leave slim-mode broken. The finding should explicitly enumerate every wrong entry in that list.
- **(low/bug)** README documents SPC m e h for DOM errors but actual binding is SPC m E l — Correct the README table entry from ~SPC m e h~ to ~SPC m E l~ and update the description to match web-mode-dom-errors-show. This is a straightforward documentation fix.
- **(low/bug)** README duplicates SPC m g p and incorrectly attributes CSS navigation to it — Line 121 should be deleted or corrected to SPC m g h. The correct web-mode binding at line 126 (SPC m g p → parent element) should stay. The CSS/SCSS section at line 160 already has the correct entry. This is a copy-paste error that would send users to the wrong key.
- **(low/bug)** SPC m r k (web-mode-element-kill) is bound in code but absent from README key-binding table — Add a row | ~SPC m r k~ | kill current element and children | to the web-mode key binding table. This is distinct from SPC m r d (web-mode-element-vanish, which preserves children).
- **(low/modernization)** scss-mode still pulled from MELPA despite Emacs 30 providing it built-in via css-mode — Switch scss-mode in html-packages to use (:location built-in) on Emacs 30+ or conditionally exclude it. The layer comment from 2024 already identifies this TODO. The flymake workaround at packages.el:182-183 can be removed once the built-in version is used. This would also save a MELPA install of a 2018 package.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

