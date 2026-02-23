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

## Useful docs

- `doc/CODEBASE_MAP.org`
- `doc/FORK_WORKFLOW.org`
- `layers/+lang/ocaml/ROADMAP.md`

## Quick Commands

```sh
make -C tests/core test           # Run core tests
make -C tests/layers/+lang/python test  # Run layer tests
```
