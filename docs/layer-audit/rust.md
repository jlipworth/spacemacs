# Layer audit: `rust`  (`+lang/rust`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the audit's maturity assessment. The layer is a thin skeleton: one DAP template (GDB-only, non-functional on macOS), two test bindings out of six available interactive test commands, a completely stale README keybinding table (one phantom binding, one wrong binding, and ten real bindings entirely absent), no ERT tests, no org-babel integration, and three correctness bugs. The `rustic-format-on-save` obsolescence issue is real and affects both the README and the user's dotfile. The lexical-binding omission is confirmed. No audit finding was found to be a false positive.

## Findings

### HIGH · bug · effort S — README documents `SPC m h h` (describe symbol) that is never bound

_status: confirmed · deliverable: issue_

The README promises `SPC m h h` → 'describe symbol at point', but no such binding is registered anywhere in packages.el. The original binding was `racer-describe`, which is gone. The LSP equivalent is `lsp-describe-thing-at-point`. Fix: add `"hh" 'lsp-describe-thing-at-point` inside the `with-eval-after-load 'lsp-mode` block in `rust/init-rustic`, and update the README to note it is LSP-only.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/rust/README.org:134 — '| ~SPC m h h~ | describe symbol at point |'
- /Users/jlipworth/.emacs.d/layers/+lang/rust/packages.el:82-96 — lsp block defines only `hm` (expand-macro) and `hs` (syntax-tree); `hh` is absent
- git show 9df14a28 confirms the commit added `hh` for `spacemacs/racer-describe` (racer backend); that function and binding were never ported to the rustic/LSP rewrite

### HIGH · bug · effort S — User dotfile and README both use obsolete `rustic-format-on-save`; the replacement is `rustic-format-trigger`

_status: confirmed · deliverable: issue_

Rustic 0.19 deprecated `rustic-format-on-save` in favour of `rustic-format-trigger`. The user's dotfile sets the obsolete variable at line 197, and the README example at line 65 and prose at line 93 both teach the same obsolete pattern. While rustic still honours the old variable via `rustic-format-on-save-p`, this will break silently when the variable is removed. Fix: update the README example to `rustic-format-trigger 'on-save` (both the `:variables` block and the Rustfmt prose section) and add a note for the user to update their dotfile.

**Evidence:**
- /Users/jlipworth/GNU_files/.spacemacs:197 — `rustic-format-on-save t` confirmed
- /Users/jlipworth/.emacs.d/layers/+lang/rust/README.org:65 — `rustic-format-on-save t` in the `:variables` example block; README:93 also references it in prose
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/rustic-20260407.1712/rustic-rustfmt.el:441 — `(make-obsolete 'rustic-format-on-save 'rustic-format-trigger "Rustic 0.19")` confirmed at exact line cited

### HIGH · gap · effort M — DAP setup registers only a GDB template; no LLDB/codelldb template exists (macOS host)

_status: adjusted · deliverable: issue_

The layer requires `dap-cpptools`, `dap-lldb`, and `dap-gdb-lldb` in funcs.el but registers no template for any of them — only for GDB. On macOS, `rust-gdb` is non-functional. Add a second `dap-register-debug-template` call in `spacemacs//rust-setup-lsp-dap` for a codelldb configuration, and expose a layer variable `rust-dap-adapter` defaulting to `'codelldb` on darwin and `'gdb` elsewhere.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/rust/funcs.el:52-63 — `require` calls for `dap-cpptools`, `dap-lldb`, `dap-gdb-lldb` and a single `dap-register-debug-template` with `:type "gdb"` and `:gdbpath "rust-gdb"`
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/dap-mode-20260523.830/dap-codelldb.el — `dap-codelldb-setup` exists; no Rust template is pre-registered in the rust layer
- Platform: darwin (macOS) — GDB is non-functional on Apple Silicon; LLDB/codelldb is the correct debugger

### MEDIUM · gap · effort S — Five rustic test commands exist but only two are bound (`ta` and `tt`)

_status: adjusted · deliverable: issue_

The `mt` prefix group is declared but barely populated. Four additional interactive test commands exist in rustic: `rustic-cargo-test` (with prompt), `rustic-cargo-test-rerun`, `rustic-cargo-test-rerun-current`, and `rustic-cargo-test-dwim`. Add bindings: `"td"` → `rustic-cargo-test-dwim`, `"tr"` → `rustic-cargo-test-rerun`, `"ts"` → `rustic-cargo-test` (interactive prompt), `"tR"` → `rustic-cargo-test-rerun-current`. Also expose `rustic-cargo-test-runner` as a layer variable so users can switch to nextest. Update README accordingly.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/rust/packages.el:76-77 — only `rustic-cargo-test-run` (ta) and `rustic-cargo-current-test` (tt) are bound
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/rustic-20260407.1712/rustic-cargo.el — `rustic-cargo-test` (interactive, line 216), `rustic-cargo-test-rerun` (line 242), `rustic-cargo-test-rerun-current` (line 252), `rustic-cargo-test-dwim` (line 294) are all autoloaded and interactive

### MEDIUM · bug · effort S — `spacemacs/rust-quick-run` is defined but has no keybinding and contains a dead function parameter

_status: confirmed · deliverable: issue_

The function `spacemacs/rust-quick-run` is a dead code path: it is never called from any keybinding, and the helper it delegates to ignores its own `input-file-name` argument (uses `(buffer-file-name)` twice instead). Fix both issues: (1) correct `spacemacs//rust-quick-run-generate-tmp-file-name` to use the `input-file-name` argument, and (2) add `"cq" 'spacemacs/rust-quick-run` to the cargo prefix group in `rust/init-rustic`. Add a matching README row.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/rust/funcs.el:78-82 — `spacemacs//rust-quick-run-generate-tmp-file-name` accepts `input-file-name` but uses `(buffer-file-name)` directly twice, ignoring the parameter
- /Users/jlipworth/.emacs.d/layers/+lang/rust/packages.el — grep for 'quick-run' or 'cq' or '"q"' returns nothing; no binding registered
- git show 6d054e8a confirms the original commit bound it to `"q"` in the old `rust-mode` layer; the rustic migration dropped the binding

### MEDIUM · gap · effort M — No ERT tests for the rust layer

_status: confirmed · deliverable: issue_

No test directory exists under `tests/layers/+lang/rust/`. Create a test suite mirroring the python structure: `tests/layers/+lang/rust/init.el`, `layers-ftest.el`, and `Makefile`. Cover at minimum: (1) backend selection logic in `spacemacs//rust-setup-backend`, (2) the DAP template registration in `spacemacs//rust-setup-lsp-dap`, and (3) the quick-run compilation finish function.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*rust*' returns empty — no rust test directory exists
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ contains init.el, layers-ftest.el, and Makefile as the reference structure
- /Users/jlipworth/.emacs.d/layers/+lang/rust/funcs.el:84-91 — `spacemacs//rust-quick-run-compilation-finish-function` contains testable logic

### LOW · gap · effort S — rustic-babel org-babel integration is not registered in the layer

_status: confirmed · deliverable: issue_

Rustic ships `rustic-babel.el` which allows Rust code blocks in org-mode to be executed inline (`#+begin_src rustic`). The layer does not wire this up. Add a `(org :location built-in)` entry to `rust-packages` with a `rust/post-init-org` function that calls `(require 'rustic-babel)` inside `with-eval-after-load 'ob`. Also expose `rustic-babel-auto-wrap-main` as a recommended `:variables` option in the README.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/rustic-20260407.1712/rustic-babel.el — provides `org-babel-execute:rustic`, aliases to `org-babel-execute:rust`, registers `rustic` in `org-babel-tangle-lang-exts`, exposes `rustic-babel-auto-wrap-main` defcustom
- /Users/jlipworth/.emacs.d/layers/+lang/rust/packages.el — no `rustic-babel` require, no org layer interaction, `rust-packages` defconst has no org entry
- /Users/jlipworth/GNU_files/.spacemacs:86-91 — user has org layer active

### LOW · cleanup · effort S — config.el, packages.el, and funcs.el have `lexical-binding: nil` while layers.el correctly uses `t`

_status: confirmed · deliverable: issue_

Three of four layer files opt out of lexical binding. Flip the cookie to `t` in config.el, packages.el, and funcs.el. Review `funcs.el` for dynamic-binding reliance: the `spacemacs//rust-quick-run-tmp-file` defvar and the compilation-finish closure at lines 84-91 should be reviewed and converted to `let`-bound closures if needed.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/rust/config.el:1 — `-*- lexical-binding: nil; -*-` confirmed
- /Users/jlipworth/.emacs.d/layers/+lang/rust/packages.el:1 — `-*- lexical-binding: nil; -*-` confirmed
- /Users/jlipworth/.emacs.d/layers/+lang/rust/funcs.el:1 — `-*- lexical-binding: nil; -*-` confirmed
- /Users/jlipworth/.emacs.d/layers/+lang/rust/layers.el:1 — `-*- lexical-binding: t; -*-` confirmed
- git show c35a6712 confirms commit 'Enable lexical-binding in all layers.el files' updated only layers.el, not the other three files

### LOW · enhancement · effort S — No layer variable for `rustic-cargo-test-runner` (nextest) — user has no documented path to switch

_status: confirmed · deliverable: issue_

Add `(defvar rust-test-runner 'cargo ...)` to config.el and wire it in `spacemacs//rust-setup-backend` (or a new hook) via `(setq rustic-cargo-test-runner rust-test-runner)`. Document in README that `:variables rust-test-runner 'nextest` after `cargo install cargo-nextest` enables the faster parallel test runner. This mirrors how the python layer exposes `python-test-runner`.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/rustic-20260407.1712/rustic-cargo.el:32-40 — `rustic-cargo-test-runner` defcustom accepts `'cargo` or `'nextest`; `rustic-cargo-nextest-exec-command` configures the command
- /Users/jlipworth/.emacs.d/layers/+lang/rust/config.el — no defvar for a test-runner layer variable
- /Users/jlipworth/.emacs.d/layers/+lang/rust/README.org — nextest not mentioned anywhere in the file

## Additional gaps caught in verification

- **(medium/bug)** README keybinding table documents `SPC m s s` for switch-server but the actual binding is `SPC m b S` — The README key bindings table at line 135 shows `SPC m s s` for 'switch to other LSP server backend', but the actual binding registered in packages.el is `"bS"` → `SPC m b S`. The `ms` prefix is declared for the workspace-reload group in funcs.el, but `lsp-rust-switch-server` is placed under `mb`. Fix: correct README line 135 to show `SPC m b S`.
- **(medium/gap)** README keybinding table is missing ten real LSP-mode bindings that are registered in packages.el — The README key bindings table documents only a subset of the bindings actually registered. The following LSP-mode bindings are registered in packages.el but entirely absent from the README: `SPC m = j` (join lines), `SPC m T i` (toggle inlay hints), `SPC m b D` (rust-analyzer status), `SPC m g p` (find parent module), `SPC m h m` (expand macro), `SPC m h s` (syntax tree), `SPC m v` (extend selection), `SPC m ,` (rerun), `SPC m .` (run). Add all of these to the README table, annotated as LSP-only.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

