# Layer audit: `ocaml`  (`ocaml`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

The maturity rating (underbuilt) is CORRECT and the audit's substance holds up well under verification. It is a minimal Merlin/tuareg layer (config.el 30 lines, funcs.el 84, packages.el 201) covering the classic stack (tuareg, merlin + company/eldoc/iedit, utop, dune, ocamlformat, ocp-indent, flycheck-ocaml) with no LSP backend, no tree-sitter, no debugger, no opam-switch awareness, and zero tests — far below the in-repo python gold standard. CRUCIAL VERIFICATION RESULT: the audit's upstream_delta claim is ACCURATE — I confirmed via `git diff syl20bnr/develop` that config.el, funcs.el, packages.el and README.org are all byte-identical to upstream (empty diff), with ROADMAP.md (74 lines) as the sole fork addition. The audit correctly notes ocamlformat IS covered (packages.el:36,142-147). The six substantive findings (LSP, treesit, debugger, dune, opam-switch, tests) are all valid; I downgraded confidence in none of them. The only corrections needed are line-number imprecision and a few unverifiable .spacemacs citations, which I stripped or re-grounded in the layer code. I found no fabricated gaps in the audit; the layer genuinely lacks the modern toolchain that the rest of this fork's lang layers have.

## Findings

### HIGH · modernization · effort L — No LSP (ocaml-lsp-server) backend — layer is Merlin-only despite user's all-LSP workflow

_status: adjusted · deliverable: both_

Introduce an `ocaml-backend` layer variable (values `'merlin` default, `'lsp`) mirroring the python layer's backend dispatch. When `'lsp`: gate on `(configuration-layer/layer-used-p 'lsp)`, add lsp-ocaml (or wire eglot) in packages.el, register a `spacemacs//ocaml-setup-backend` on `tuareg-mode-local-vars-hook`, and SKIP the unconditional merlin-mode hook (packages.el:94) and flycheck-ocaml-setup (packages.el:77-83) to avoid double diagnostics. Keep the merlin path as default. Document the opam install. This is the single biggest modernization gap.

**Evidence:**
- packages.el:24-40 (ocaml-packages defconst) lists merlin, merlin-company, merlin-eldoc, merlin-iedit but NO lsp-mode/lsp-ocaml/eglot/ocaml-eglot
- config.el (entire file is 30 lines) defines only `ocaml-format-on-save` (lines 28-30) plus a jump handler (line 26); there is NO `ocaml-backend` variable, so no backend dispatch exists
- packages.el:94 `(add-hook 'tuareg-mode-hook 'merlin-mode)` wires merlin unconditionally; packages.el:77-83 wires flycheck-ocaml — both would need gating if an LSP path were added
- ROADMAP.md:5-7 section 1 explicitly flags this gap
- Ecosystem: ocaml-lsp-server (ocamllsp) is the official server (`opam install ocaml-lsp-server`); lsp-ocaml / ocaml-eglot add workspace rename, code actions, inlay hints beyond Merlin

### MEDIUM · modernization · effort M — No tree-sitter (ocaml-ts-mode) support

_status: adjusted · deliverable: issue_

Add a treesit code path gated on `(treesit-available-p)` and grammar availability. CAUTION: merlin (packages.el:94), utop (packages.el:184), ocp-indent (packages.el:153), evil-matchit (packages.el:72), and the jump handler (config.el:26) are ALL keyed on tuareg-mode-hook / tuareg-mode; naively switching the major mode to ocaml-ts-mode would silently disable the toolchain. Safer: keep tuareg-mode as the driver and add tree-sitter font-lock on top, OR replicate every tuareg-mode-hook attachment onto the ts-mode hook and call `spacemacs|define-jump-handlers ocaml-ts-mode`. Gate behind a layer variable; document grammar install.

**Evidence:**
- packages.el:163-178 `ocaml/init-tuareg` registers tuareg-mode for `\.ml[ily]?$` and `\.topml$` only (lines 168-169); there is no ts-mode path and no `(treesit-available-p)` gating anywhere in the layer
- ROADMAP.md:29-31 section 7 flags missing Emacs 29 tree-sitter grammar registration
- Ecosystem: Emacs 29+ ships treesit; tuareg/standalone ocaml-ts-mode efforts provide tree-sitter highlighting

### MEDIUM · gap · effort L — No debugger integration (ocamldebug / DAP)

_status: adjusted · deliverable: both_

Provide a `SPC m d` debug prefix for tuareg-mode. MVP: wrap Emacs' built-in `ocamldebug` with leader keys for start/continue/step/next/breakpoint. Stretch: integrate the `earlybird` DAP adapter via dap-mode when the dap layer is used, launching against a dune target. Document a minimal dune build + debug workflow in README.

**Evidence:**
- packages.el has no ocamldebug/dap/earlybird wiring and declares no `SPC m d` debug prefix; the only declared mode prefixes are mc/mE/mg/mh/mr (packages.el:113-117), mt (packages.el:49), mi (packages.el:51), ms (packages.el:195)
- README.org:139 region TODO 'Add proper key bindings for ocamldebug'
- ROADMAP.md:9-11 section 2 requests ocamldebug start/continue/step/breakpoint bindings and a dune-target launch

### MEDIUM · enhancement · effort M — Dune workflow limited to test/promote — no build/exec/fmt/watch

_status: confirmed · deliverable: issue_

Add helpers in funcs.el (`spacemacs/ocaml-dune-build`, `-exec`, `-fmt`, `-runtest-watch`) invoking dune via compilation-start with OCaml error regexps so users can jump to errors. Bind under the existing `mc` compile/check prefix (currently only `cc` plus merlin `cp`/`cv`). Independent of LSP; immediate value for project workflows.

**Evidence:**
- packages.el:42-69 `ocaml/init-dune`: dune-mode keys cover `cc` compile + insert-stanza forms (ia–iy) + dune-promote (tP) / dune-runtest-and-promote (tp) only; tuareg-mode dune bindings (packages.el:46-48) are just tP/tp
- No binding for `dune build`, `dune exec`, `dune fmt`, or `dune runtest --watch` anywhere in the layer
- ROADMAP.md:13-15 section 3 lists exactly these

### MEDIUM · gap · effort M — No opam switch / per-project environment awareness

_status: confirmed · deliverable: issue_

Add optional `opam-switch-mode` (or custom detection reading the project's `_opam`/dune-project switch) hooked into `tuareg-mode-local-vars-hook` so merlin/utop/ocaml-lsp pick up the correct switch's binaries across multiple projects. Provide a command to regenerate the spacemacs env after `opam switch`. Without this, multi-switch users get stale tool paths.

**Evidence:**
- funcs.el:24-50 `spacemacs//init-ocaml-opam` resolves the global opam share dir ONCE at tuareg :init (called at packages.el:172); utop just does a one-time `(executable-find "opam")` (packages.el:197). No opam-switch-mode or per-project _opam/dune-project detection
- ROADMAP.md:33-35 section 8 requests per-project `opam switch` detection and a `.spacemacs.env` regeneration helper

### MEDIUM · gap · effort M — Zero automated tests for the layer

_status: confirmed · deliverable: issue_

Create tests/layers/+lang/ocaml/ with init.el enabling the layer, a layers-ftest.el asserting the layer loads and key packages (tuareg, merlin, dune, utop) register leader keys / the repl, and a Makefile including spacemacs.mk; add the target to the elisp_test.yml matrix. Follow the python layout. Guards the refactors in the other findings.

**Evidence:**
- tests/layers/+lang/ contains only `python` (directory listing from find earlier); no `ocaml` subdirectory
- Python gold standard ships tests/layers/+lang/python/ with init.el + *-test files + Makefile
- ROADMAP.md:69-74 section 9 gives a step-by-step plan to add tests/layers/+lang/ocaml and wire it into .github/workflows/elisp_test.yml

### LOW · cleanup · effort S — ROADMAP.md is the only fork divergence and is not yet acted on; keep README key tables current as features land

_status: confirmed · deliverable: issue_

ROADMAP.md is the sole fork artifact and currently just plans work. As LSP toggle / debug prefix / dune commands land, append them to the README key-binding tables so docs track reality. If the layer diverges from upstream, note it in doc/FORK_WORKFLOW.org. Low effort; do in lockstep with each feature finding.

**Evidence:**
- `/tmp/up.diff` = 0 lines: config.el, funcs.el, packages.el, README.org all byte-identical to syl20bnr/develop (verified via `git diff syl20bnr/develop -- layers/+lang/ocaml/{...}`)
- ROADMAP.md is 74 lines (wc -l confirmed) and was not in the upstream listing of the layer dir; the only non-upstream file in layers/+lang/ocaml/
- README.org:21 'This is a very basic layer'; README.org carries a TODO list (upstream content)

## Additional gaps caught in verification

- **(low/bug)** Layer never adds a tuareg-mode jump handler for ts-mode and relies on ggtags hook keyed to ocaml-mode-local-vars-hook, not tuareg — The ggtags integration is attached to `ocaml-mode-local-vars-hook`, but users editing .ml files are in tuareg-mode, so ggtags (the gtags-based jump fallback) is never enabled for them. Either change the hook to `tuareg-mode-local-vars-hook` or document that ocaml-mode is intentionally separate. This is pre-existing upstream behavior (the file is byte-identical to upstream), so it is a low-severity latent bug rather than fork churn, but it is a real functional gap the audit did not surface. Verify with `M-x ggtags-mode` state in a tuareg buffer.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

