# CLAUDE.md

Quick guidance for AI/code assistants working in this Spacemacs fork.

## Scope

This repo is primarily Emacs Lisp and organized around Spacemacs layers.

## Important paths

- `core/` – core startup/config infrastructure
- `layers/` – feature/language layers
- `doc/` – user/dev docs
- `tests/` – ERT unit and functional tests
- `.github/workflows/` – CI definitions

## Layer conventions

- Typical files: `packages.el`, `config.el`, `funcs.el`
- Naming:
  - `spacemacs/xxx` public
  - `spacemacs//xxx` private
  - `spacemacs|xxx` macro

## Making changes (fork discipline)

This is a fork that tracks upstream. Prefer the smallest change that matches how
upstream already solves the problem; avoid gratuitous divergence. Before changing
a layer's behavior, check how **sibling layers** handle the same situation and
follow that idiom rather than inventing a new approach — a one-off pattern is
harder to maintain and to upstream. When unsure whether a change is justified, it
usually isn't. Keep each fix to one atomic commit with an `Upstream: …#NNNNN` ref.

Worked example — lsp keybindings: the lsp layer reserves these major-mode
(`SPC m`) prefixes (see `layers/+tools/lsp/README.org`): `a` actions, `=` format,
`g`/`G` goto/peek, `F` folder, `h` help, `b` backend, `r` refactor, `T` toggle,
`x` text. When a language layer's `<lang>-backend` is `'lsp`, cede those keys to
lsp and relocate the layer's own commands to *free* keys (e.g. haskell moves
`F`→`S`, `hh`→`hg`, `gi`→`gl`). Binding under a reserved prefix — e.g. `"au"`
under lsp's `a` — is shadowed/unreachable while lsp-mode is active (was bug #16390).

## Useful docs

- `doc/CODEBASE_MAP.org`
- `doc/FORK_WORKFLOW.org`
- `layers/+lang/ocaml/ROADMAP.md`

## Quick Commands

```sh
make -C tests/core test           # Run core tests
make -C tests/layers/+lang/python test  # Run layer tests
```
