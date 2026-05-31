# Layer audit: `c-c++`  (`c-c++`)

**Maturity:** `adequate`  
**Upstream delta:** n/a

The layer is functional for its primary lsp-clangd and lsp-ccls backends, with working DAP, clang-format, gdb-mi, disaster, and gendoxy. The tree-sitter gap (Emacs 29+ c-ts-mode/c++-ts-mode) and the unbound clangd switchSourceHeader extension are real deficiencies, and the SPC m c / SPC m p prefix skeletons clutter which-key. The earlier finding that clang-format-on-save is a dead function is false — the on-save hook is wired correctly. The maturity rating remains adequate rather than underbuilt because the core LSP path works end-to-end for the user's actual backend (lsp-clangd), but the ts-mode gap will become an increasingly practical problem on Emacs 29+.

## Findings

### HIGH · gap · effort M — No tree-sitter mode support: c-ts-mode and c++-ts-mode are completely absent

_status: confirmed · deliverable: both_

On Emacs 29+, users who follow the recommended upgrade path of adding (c-mode . c-ts-mode) and (c++-mode . c++-ts-mode) to major-mode-remap-alist will find that no Spacemacs keybindings, LSP, DAP, clang-format, company backends, or flycheck activate, because all hooks target c-mode-hook and c++-mode-hook only. Fix: (1) expand c-c++-modes and c-c++-mode-hooks in config.el to conditionally include c-ts-mode and c++-ts-mode when (featurep 'treesit) returns non-nil; (2) add a layer variable c-c++-ts-mode-enable (default nil, set t on Emacs >= 29) that adds major-mode-remap-alist entries. The .cppm/.ixx extensions (finding #4) should also be handled for ts-mode when enabled.

**Evidence:**
- layers/+lang/c-c++/config.el:108-112: c-c++-modes and c-c++-mode-hooks constants hardcode c-mode and c++-mode only
- rg -rn 'c-ts-mode|c++-ts-mode|treesit' layers/+lang/c-c++/ returns zero results
- layers/+lang/c-c++/packages.el:81-82, 111-112, 149-150, 162-163, 166-167, 178-179, 239-240: all per-buffer hooks use c-mode-local-vars-hook and c++-mode-local-vars-hook exclusively
- git show syl20bnr/develop:layers/+lang/c-c++/config.el shows same defconst c-c++-modes with only c-mode and c++-mode — the gap is in upstream too

### MEDIUM · bug · effort S — clangd switchSourceHeader extension defined but never key-bound, and the custom extension wrapper is also wrong

_status: adjusted · deliverable: issue_

Two problems compound: (1) after calling lsp-define-extensions, spacemacs//c-c++-setup-lsp-clangd never calls spacemacs/lsp-bind-extensions-for-mode, so the generated command has no keybinding. (2) More importantly, the generated command is wrong — switchSourceHeader returns a URI string, not a LSP locations array, so lsp-find-locations will error. The correct fix is to bind the upstream lsp-mode function directly: in spacemacs//c-c++-setup-lsp-clangd, add a dolist over c-c++-modes and bind 'lsp-clangd-find-other-file to a key (e.g. SPC m g o, SPC m g O is taken by rtags). The lsp-define-extensions call for this extension can be removed entirely. Severity is medium (not high) because SPC m g a via projectile-find-other-file already provides a working fallback.

**Evidence:**
- layers/+lang/c-c++/funcs.el:80-82: spacemacs/lsp-define-extensions called with 'clangd-other-file and 'textDocument/switchSourceHeader'
- layers/+lang/c-c++/funcs.el:77-84: spacemacs//c-c++-setup-lsp-clangd has no spacemacs/lsp-bind-extensions-for-mode call, unlike the ccls counterpart at funcs.el:148-163 which binds extensions after defining them
- lsp-mode elpa/30.2/develop/lsp-mode-20260518.1214/lsp-clangd.el:304-317: lsp-mode already ships lsp-clangd-find-other-file which uses lsp--text-document-identifier (correct), not lsp-find-locations which expects a locations array response
- lsp-mode elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:6939-6947: lsp-find-locations appends extra as a plist to position params and expects a locations array — switchSourceHeader returns a single URI string, so the generated function spacemacs/c-c++-lsp-clangd-find-clangd-other-file would fail at runtime
- layers/+lang/c-c++/packages.el:98-99: the all-backends fallback SPC m g a (projectile-find-other-file) exists, reducing user impact
- /Users/jlipworth/GNU_files/.spacemacs:141: user backend is lsp-clangd

### MEDIUM · gap · effort S — SPC m c (compile) and SPC m p (project) prefixes declared but completely empty

_status: confirmed · deliverable: issue_

Both prefixes appear in which-key with no children, which is misleading and adds noise. Either bind useful commands (SPC m c c -> compile, SPC m c r -> recompile, SPC m c k -> kill-compilation; SPC m p could be removed as projectile handles project actions globally) or remove the dead declarations. If bindings are added, document them in README.org.

**Evidence:**
- layers/+lang/c-c++/packages.el:94: (spacemacs/declare-prefix-for-mode mode "mc" "compile")
- layers/+lang/c-c++/packages.el:96: (spacemacs/declare-prefix-for-mode mode "mp" "project")
- Full grep of set-leader-keys-for-major-mode across all five layer files shows zero bindings with keys starting with 'c' or 'p' (beyond the declarations themselves)
- git show syl20bnr/develop:layers/+lang/c-c++/packages.el:94,96 confirms both prefixes are in upstream too — not a local issue

### MEDIUM · gap · effort S — C++20 module file extensions (.cppm, .ixx) not registered in the layer

_status: confirmed · deliverable: issue_

Both user-config workarounds are exactly what layer variables exist to absorb. Proposed: (1) add a layer variable c-c++-enable-cpp-module-support (default nil) that registers .cppm and .ixx in auto-mode-alist for c++-mode (and c++-ts-mode if ts-mode support is added); (2) when backend is lsp-clangd and this variable is set, add --experimental-modules-support to lsp-clients-clangd-args. This would let the user remove both user-config blocks.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:778-779: user manually adds .cppm and .ixx to auto-mode-alist in user-config
- /Users/jlipworth/GNU_files/.spacemacs:781-784: user manually appends --experimental-modules-support to lsp-clients-clangd-args in a with-eval-after-load block
- layers/+lang/c-c++/config.el: no .cppm, .ixx, .mpp mention
- layers/+lang/c-c++/packages.el: no .cppm, .ixx mention

### MEDIUM · gap · effort M — No layer tests; python layer has ERT test suite as the comparative standard

_status: confirmed · deliverable: issue_

The python layer is the stated gold standard and has functional tests. At minimum, c-c++ tests should cover: backend dispatch (pcase in spacemacs//c-c++-setup-backend), clang-format-on-save hook installation, and formatter-indent-line setup. Create tests/layers/+lang/c-c++/ mirroring the python structure.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*c-c*' -o -name '*cpp*' returns zero results
- tests/layers/+lang/python/ contains init.el, layers-ftest.el, Makefile (confirmed by ls)

### LOW · cleanup · effort M — ycmd backend is a dead-end dependency: emacs-ycmd is unmaintained

_status: confirmed · deliverable: issue_

emacs-ycmd carries maintenance surface without practical benefit to new users. The recommended path is to add a deprecation notice in config.el and mark the backend as deprecated in README.org, recommending migration to lsp-clangd. The code should not be deleted without a deprecation cycle.

**Evidence:**
- layers/+lang/c-c++/packages.el:54-60: ycmd, company-ycmd, flycheck-ycmd are listed as packages
- layers/+lang/c-c++/config.el:31: ycmd listed as a possible backend value
- README.org:92: ycmd documented as a supported backend
- github.com/abingham/emacs-ycmd last substantive commits are from 2021-2022 based on public record

## Additional gaps caught in verification

- **(low/cleanup)** spacemacs//c-c++-setup-format is dead code that can be removed — spacemacs//c-c++-setup-format was likely introduced as a backend-conditional dispatch pattern (matching spacemacs//c-c++-setup-backend, setup-company, etc.) but was never hooked into any package init or mode hook. The direct call in c-c++/init-clang-format bypasses it. Since clang-format is a standalone tool independent of backend (both lsp-clangd and lsp-ccls would use it identically), the wrapper adds no value and should simply be deleted to reduce confusion.
- **(medium/bug)** lsp-clangd-find-other-file from upstream lsp-mode is ignored in favor of a broken custom extension — The layer should remove the lsp-define-extensions call for clangd-other-file entirely and instead bind lsp-clangd-find-other-file (provided by lsp-mode) directly in spacemacs//c-c++-setup-lsp-clangd. The generated spacemacs/c-c++-lsp-clangd-find-clangd-other-file command would error at runtime because lsp-find-locations calls seq-empty-p on the string URI response. This is a distinct sub-bug from the missing keybinding (finding #1) and should be filed separately.

## Rejected by verifier (false positives)

- ~~clang-format-on-save is correctly wired; finding that spacemacs//c-c++-setup-format is the call path is false~~ — Rejected as stated. The original finding claimed spacemacs//c-c++-setup-clang-format has 'no caller' — this is false. packages.el:108 calls it directly. The correct observation is that spacemacs//c-c++-setup-format (the dispatch wrapper) is dead code, which is a minor cleanup item, not a bug that silently ignores the user's setting.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

