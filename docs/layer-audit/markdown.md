# Layer audit: `markdown`  (`+lang/markdown`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification upholds the underbuilt rating. All seven findings are real. The layer ships only keybindings and basic preview/TOC; no LSP, no formatter, no flycheck integration, no layers.el. Two gaps (grip-mode, LSP) force the user into dotfile workarounds. The README has a confirmed keybinding documentation bug. The layer is byte-for-byte identical to upstream develop, so none of these gaps are fork-specific fixes — they are shared upstream gaps, but this repo's user is actively working around them manually.

## Findings

### HIGH · gap · effort M — No LSP backend (marksman) — lsp-mode support exists but is unwired

_status: confirmed · deliverable: issue_

Add a `markdown-backend` layer variable (default `nil`, accept `'lsp`). Create a `layers.el` that calls `(configuration-layer/declare-layer-dependencies '(lsp))` when `markdown-backend` is `'lsp`, matching the pattern in `layers/+lang/python/layers.el`. In `packages.el`, add `lsp` to `markdown-packages` with a `:toggle` guard, and add a `markdown/post-init-lsp` function that calls `(lsp)` in `markdown-mode-hook` and requires `lsp-marksman`. The user already has lsp-mode and the activation client (`lsp-marksman.el`) is installed — only the wiring is missing.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-marksman.el:85 — lsp-mode ships activation-fn `(lsp-activate-on "markdown")` for marksman; the client is fully defined and auto-downloadable
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/config.el:26-30 — only one layer variable (`markdown-live-preview-engine`); no `markdown-backend` variable exists
- No layers.el in /Users/jlipworth/.emacs.d/layers/+lang/markdown/ — confirmed by `ls` (file does not exist); compare /Users/jlipworth/.emacs.d/layers/+lang/python/layers.el which conditionally declares lsp dependency
- /Users/jlipworth/GNU_files/.spacemacs:70-74 — user has lsp layer enabled globally with `lsp-auto-guess-root t`; every other backend-aware layer in their config explicitly sets `*-backend 'lsp`
- git diff syl20bnr/develop HEAD -- layers/+lang/markdown/ produces no output — fork is identical to upstream; gap exists in both

### HIGH · gap · effort S — grip-mode manually wired in user dotfile instead of being a layer-managed package

_status: confirmed · deliverable: issue_

Add `(grip-mode :toggle (eq 'grip markdown-live-preview-engine))` to `markdown-packages` in `packages.el`. Extend the `markdown-live-preview-engine` docstring in `config.el` to include `'grip` as a third valid value (alongside `'eww` and `'vmd`). Add a `markdown/init-grip-mode` function that binds `SPC m c g` to `grip-mode` in all `markdown--key-bindings-modes` (both `markdown-mode` and `gfm-mode` — the user's manual binding only covers `markdown-mode`). This removes the dotfile hack at `.spacemacs:768-771`.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:226 — grip-mode in dotspacemacs-additional-packages
- /Users/jlipworth/GNU_files/.spacemacs:768-771 — user manually hooks `with-eval-after-load 'markdown-mode` to bind `SPC m c g` to `grip-mode` (only for markdown-mode, not gfm-mode)
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/packages.el:35 — only `vmd-mode` is an optional preview package; grip-mode is absent from `markdown-packages`
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/grip-mode-20260529.310/grip-mode.el — grip-mode is already installed in elpa (installed version 20260529.310)
- /Users/jlipworth/.local/bin/grip -> /Users/jlipworth/.local/pipx/venvs/grip/bin/grip — grip binary is present on the system

### MEDIUM · gap · effort M — No formatter integration (prettier is installed and supports Markdown)

_status: confirmed · deliverable: issue_

Add a `markdown-formatter` variable to `config.el` (default `nil`, accept `'prettier`). Add `(prettier-js :toggle (eq 'prettier markdown-formatter))` to `markdown-packages`. Add a `markdown-format-on-save` boolean variable. In `markdown/pre-init-prettier-js`, add `markdown-mode` to `spacemacs--prettier-modes` when `markdown-formatter` is `'prettier`, following the pattern at `layers/+lang/javascript/packages.el:246-248`. Prettier supports Markdown out of the box; no additional configuration is needed beyond enabling the mode.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/packages.el — no formatter package (prettier, apheleia, etc.) in `markdown-packages`
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/config.el — no `markdown-formatter` or `markdown-format-on-save` variable
- /Users/jlipworth/GNU_files/.spacemacs:131-135 — user sets `python-backend 'lsp`, `python-formatter 'ruff`, `python-format-on-save t`; the per-layer formatter variable pattern is established but absent for markdown
- /Users/jlipworth/.nvm/versions/node/v25.5.0/bin/prettier — prettier 3.x is installed at this path and supports Markdown natively
- /Users/jlipworth/.emacs.d/layers/+lang/javascript/packages.el:42 — `prettier-js` is already in the javascript layer packages list, confirming the integration pattern exists in this repo

### MEDIUM · gap · effort S — No flycheck/lint integration despite flycheck supporting markdownlint natively

_status: adjusted · deliverable: issue_

Add `flycheck` to `markdown-packages` and a `markdown/post-init-flycheck` function that enables flycheck in `markdown-mode-hook`. No new checker needs to be defined — flycheck already ships `markdown-markdownlint-cli` and `markdown-markdownlint-cli2` definitions. A `markdown-enable-flycheck` toggle variable (default `nil` for safety, not `t`, since markdownlint-cli2 is not pre-installed) would allow opt-in. The user has the syntax-checking layer active and prettier installed; adding `npm install -g markdownlint-cli2` would complete the chain.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/flycheck-20260320.1715/flycheck.el:175-178 — flycheck defines checkers `markdown-markdownlint-cli`, `markdown-markdownlint-cli2`, `markdown-mdl`, `markdown-pymarkdown` in its checker list
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/flycheck-20260320.1715/flycheck.el:11165-11172 — `(flycheck-define-checker markdown-markdownlint-cli ...)` is fully defined with config-file and option-list support
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/packages.el — no `flycheck` in `markdown-packages`, no `markdown/post-init-flycheck` function
- /Users/jlipworth/GNU_files/.spacemacs:68 — `syntax-checking` layer is enabled, confirming flycheck is active globally

### MEDIUM · bug · effort S — README documents wrong keybinding for follow-thing-at-point (SPC m o vs SPC m f)

_status: confirmed · deliverable: issue_

In `README.org` line 164, change `~SPC m o~` to `~SPC m f~`. The code at `packages.el:179` binding `"f"` to `markdown-follow-thing-at-point` is the authoritative source. Note that `SPC m o` as a bare prefix does not exist in the layer at all — the auditor's note that `co` (SPC m c o) binds `markdown-open` is accurate but explains why SPC m o was mistakenly written (confusion between `co` and `o`). Also, `SPC m f` is entirely missing from the README tables, so the fix is to correct line 164 from `~SPC m o~` to `~SPC m f~`.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/packages.el:179 — code binds `"f"` to `markdown-follow-thing-at-point` (i.e., `SPC m f`)
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/README.org:164 — README documents `~SPC m o~` as 'follow thing at point' — this key does not exist in the code
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/packages.el:118 — `"co"` is bound to `markdown-open` (this is `SPC m c o`); there is no bare `"o"` binding at all
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/README.org:194 — README correctly documents `~SPC m c o~` as 'open' (separate entry), so `SPC m o` in line 164 is purely erroneous
- git show syl20bnr/develop:layers/+lang/markdown/README.org line 164 — upstream README has the same wrong `~SPC m o~` entry; bug is shared with upstream
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/README.org — `SPC m f` (`markdown-follow-thing-at-point`) is entirely absent from the README key bindings tables

### LOW · modernization · effort M — No tree-sitter mode (markdown-ts-mode) support for Emacs 30

_status: confirmed · deliverable: issue_

Add an optional `markdown-enable-tree-sitter` variable (default `nil`). When enabled, add `(markdown-ts-mode :location (recipe ...))` from MELPA and add `auto-mode-alist` entries to map `.md`/`.mkd`/`.mdk`/`.mdx` to `markdown-ts-mode`. The dual-parser architecture (block + inline parsers) in markdown-ts-mode can have rendering edge cases, so the variable should default to `nil` until the mode is stable for Emacs 31. This follows the opt-in tree-sitter pattern used by other language layers in this repo.

**Evidence:**
- GNU Emacs 30.2 confirmed via `emacs --version`
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/yasnippet-snippets-20251215.1231/snippets/markdown-ts-mode — yasnippet already ships markdown-ts-mode snippets, implying the mode is expected to be available
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/packages.el — no tree-sitter mode in the package list
- markdown-ts-mode is available on MELPA (https://github.com/LionyxML/markdown-ts-mode) for Emacs 29+

### LOW · cleanup · effort S — vmd-mode dependency is dead weight — binary not installed and package not in elpa cache

_status: confirmed · deliverable: issue_

vmd-mode's `:toggle` guard prevents any runtime error, so this is a documentation and discoverability issue rather than a code bug. The fix is README-only unless grip-mode is added as a proper package (see finding 2): update `README.org` line 36 to demote vmd to a historical/optional note and add grip as the recommended GitHub-flavored preview engine. If finding 2 is also fixed, the README update and code addition can be done together.

**Evidence:**
- `which vmd` returns 'vmd not found' — vmd npm package is not installed on this system
- `find /Users/jlipworth/.emacs.d/elpa -name 'vmd-mode*'` returns no output — vmd-mode Emacs package is not installed
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/packages.el:35 — `(vmd-mode :toggle (eq 'vmd markdown-live-preview-engine))` is guarded so it won't load unless explicitly set, preventing runtime harm
- /Users/jlipworth/.emacs.d/layers/+lang/markdown/README.org:36 — README still promotes vmd as a headline feature ('Fast GitHub-flavored live preview via vmd-mode') while grip-mode (which the user actively uses) is unmentioned

## Additional gaps caught in verification

- **(low/bug)** README 'Following and Jumping' table is missing SPC m N and SPC m P entries — In README.org, move the `~SPC m N~` (next link) and `~SPC m P~` (previous link) entries from the Movement table (lines 211-212) to the Following and Jumping table (lines 160-167). These bindings navigate links (structural following), not text movement (paragraphs/headings), so they belong in the Following section. This is a pure documentation organisation fix with no code changes needed.
- **(low/bug)** grip-mode dotfile binding only covers markdown-mode, not gfm-mode — The user's manual grip binding at `.spacemacs:769-771` registers `SPC m c g` only for `markdown-mode`, not `gfm-mode`. GitHub READMEs and PR descriptions open in `gfm-mode`, so grip-mode (which renders GH-flavored markdown) would be most useful there but is unreachable. This is subsumed by finding 2 (adding grip as a proper layer package using `markdown--key-bindings-modes`), but worth noting as a standalone bug in the current dotfile workaround.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

