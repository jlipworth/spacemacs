# OCaml Layer Roadmap

These ideas capture the biggest gaps observed while reviewing `layers/+lang/ocaml/` and can guide future improvements.

## 1. Language Server Integration
- Offer optional `ocamllsp` support (via `lsp-mode` or `eglot`) so users can access workspace rename, code actions, inlay hints, and semantic tokens.
- Provide a layer variable to toggle between the current Merlin workflow and LSP; document how to install `ocaml-lsp-server` with opam.

## 2. Debugging Experience
- Add key bindings that drive `ocamldebug` (start/continue, step, breakpoints) and make it easy to launch from a Dune target.
- Document a minimal debug workflow in the layer README.

## 3. Dune Workflow Enhancements
- Extend leader keys to cover common tasks such as `dune build`, `dune exec`, `dune fmt`, and `dune runtest --watch`.
- Surface build/test errors through a dedicated compilation buffer with quick navigation back to source.

## 4. Merlin Ergonomics
- Expose Merlin refactors (hole filling, rename, occurrences) under consistent prefixes.
- Add discoverable keybindings for frequently used commands still missing from the TODO list in `README.org`.

## 5. Formatting & Linting
- Detect project-level `.ocamlformat` configuration and surface a toggle for dune’s formatting (`dune fmt`).
- Consider hooking `opam lint` or `dune fmt --check` into `spacemacs/compile` helpers.

## 6. Testing & REPL Quality of Life
- Introduce buffer-local commands to run the nearest test or module with `dune runtest`.
- Capture UTop output in a transient buffer so results are easy to re-open.

## 7. Modern Syntax Support
- Register Emacs 29 tree-sitter grammar for OCaml and agree on a fallback strategy when the grammar is missing.
- Evaluate using tree-sitter queries to improve highlighting for interface/implementation files.

## 8. Environment Management
- Detect `opam switch` files per project, prompting users to switch automatically.
- Provide a helper command to regenerate `~/.spacemacs.env` after updates to OPAM environments.

## 9. CI/Testing Notes (for Woodpecker migration)

Spacemacs uses GitHub Actions for testing. Key details:

**Main workflow:** `.github/workflows/elisp_test.yml`
- Matrix: Ubuntu/macOS/Windows × Emacs 29.3/30.1
- Runs 3 phases per target: `installation`, `unit_tests`, `func_tests`

**Test targets:**
- `tests/core/`
- `tests/layers/+distribution/spacemacs-base/`
- `tests/layers/+distribution/spacemacs/`
- `tests/layers/+lang/python/`

**Test framework:** ERT (Emacs Lisp Regression Testing)
- `*-utest.el` = unit tests
- `*-ftest.el` = functional tests

**Key files:**
- `.github/workflows/scripts/test` - test runner script
- `.github/workflows/scripts/dot_lock.el` - package archive config
- `spacemacs.mk` - master Makefile with test targets

**Local testing:**
```bash
cd tests/core && make
```

**Dependencies:**
- `JAremko/testelpa-develop` repo for reproducible package installs
- `purcell/setup-emacs` action for Emacs installation

**To add OCaml layer tests:**
1. Create `tests/layers/+lang/ocaml/`
2. Add minimal `init.el` enabling the ocaml layer
3. Write `*-utest.el` and `*-ftest.el` files
4. Create `Makefile` including `spacemacs.mk`
5. Add to workflow matrix in `elisp_test.yml`
