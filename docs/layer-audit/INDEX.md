# Spacemacs Layer Audit — Master Hitlist

_Generated 2026-05-31 by the `layer-audit` workflow (`.claude/workflows/layer-audit.js`)._
_39 enabled layers audited (2-phase: AI auditor → adversarial verifier). `claude-code` and `whisper` are enabled but external wrapper layers, not audited here._

## How to read this

- **Maturity** = capability coverage vs the in-repo gold standard (`python`) and the modern ecosystem, *not* line count.
- Findings were produced by a Sonnet auditor, then re-checked by a skeptic verifier that **rejected 6 false positives** and adjusted severities. Spot-checks confirm the surviving findings are real, but the auditor **runs ~1 severity notch hot** — treat `high` as "clearly worth doing," `medium` as "nice win."
- Every row links to a per-layer deep-dive with full evidence (file:line) and handoff-ready fix approaches.

## Summary

| | |
|---|---|
| Layers audited | 39 |
| Maturity | 1 mature · 15 adequate · 23 underbuilt · 0 broken |
| Findings kept | 290 (45 high · 60 bugs) |
| False positives caught by verifier | 6 |

### Recurring themes (fix once, apply across many layers)

1. **No tree-sitter (`*-ts-mode`)** — python, yaml, toml, c-c++, javascript, typescript, html, docker, rust, react and more bind the legacy major mode only. A shared pattern (remap + rebind hooks onto the `*-base-mode` parent) would lift most at once.
2. **Missing/!partial LSP backends** — markdown (marksman), toml (taplo), ansible (lsp-ansible), nginx, windows-scripts (lsp-pwsh), sql (postgres-language-server) all have upstream lsp-mode plumbing that the layer never wires.
3. **README ↔ code drift** — many layers document keybindings/variables that aren't bound or don't exist (rust `SPC m h h`, lsp `SPC m g p`, several "ghost" bindings). Low effort, high polish.
4. **Stale package references** — terraform→`terraform-lsp`, html LSP npm pkgs, vimscript phantom `company-vimscript`, rust `rustic-format-on-save`.

## Hitlist (ranked: underbuilt + most high-severity first)

| Layer | Maturity | Findings | High | Bugs | Top finding | |
|---|---|---:|---:|---:|---|---|
| `rust` | underbuilt | 9 | 3 | 3 | README documents `SPC m h h` (describe symbol) that is never bound | [details](./rust.md) |
| `ibuffer` | underbuilt | 8 | 2 | 1 | Missing ibuffer-vc grouping backend as a third ibuffer-group-buffers-by option | [details](./ibuffer.md) |
| `dap` | underbuilt | 9 | 2 | 4 | Duplicate `det` key clobbers dap-eval-thing-at-point | [details](./dap.md) |
| `markdown` | underbuilt | 7 | 2 | 1 | No LSP backend (marksman) — lsp-mode support exists but is unwired | [details](./markdown.md) |
| `yaml` | underbuilt | 7 | 2 | 0 | No yaml-ts-mode support despite Emacs 30.2 being in use | [details](./yaml.md) |
| `toml` | underbuilt | 7 | 2 | 0 | Add LSP backend support (taplo / tombi) via toml-enable-lsp variable | [details](./toml.md) |
| `pdf` | underbuilt | 8 | 2 | 3 | Shadowed 'SPC m at' keybinding silently loses pdf-annot-attachment-dired | [details](./pdf.md) |
| `sql` | underbuilt | 9 | 2 | 2 | Flycheck sql-sqlint checker never activated | [details](./sql.md) |
| `ess` | underbuilt | 8 | 2 | 0 | No formatter backend: styler, Air, and format-on-save are entirely absent | [details](./ess.md) |
| `javascript` | underbuilt | 9 | 2 | 2 | No tree-sitter (js-ts-mode) support: layer is fully js2-mode-only | [details](./javascript.md) |
| `typescript` | underbuilt | 8 | 2 | 2 | No tree-sitter mode support: typescript-ts-mode and tsx-ts-mode are ignored | [details](./typescript.md) |
| `html` | underbuilt | 9 | 2 | 3 | README documents deprecated LSP server npm packages | [details](./html.md) |
| `nginx` | underbuilt | 8 | 2 | 0 | No LSP integration despite mature server support | [details](./nginx.md) |
| `windows-scripts` | underbuilt | 9 | 2 | 2 | No LSP/eglot backend for PowerShell despite lsp-pwsh shipping full plumbing | [details](./windows-scripts.md) |
| `ocaml` | underbuilt | 7 | 1 | 0 | No LSP (ocaml-lsp-server) backend — layer is Merlin-only despite user's all-LSP workflow | [details](./ocaml.md) |
| `ranger` | underbuilt | 8 | 1 | 2 | No layer-level integration for any dirvish extension module | [details](./ranger.md) |
| `vimscript` | underbuilt | 8 | 1 | 1 | company-vimscript backend is a phantom — no such package exists | [details](./vimscript.md) |
| `ansible` | underbuilt | 7 | 1 | 1 | No LSP backend variable or lsp-ansible wiring despite lsp-mode having full ansible-ls support | [details](./ansible.md) |
| `docker` | underbuilt | 7 | 1 | 2 | No dockerfile-ts-mode support on Emacs 29+ | [details](./docker.md) |
| `kubernetes` | underbuilt | 6 | 1 | 0 | No layer variables — zero user-customisable behaviour | [details](./kubernetes.md) |
| `terraform` | underbuilt | 6 | 0 | 0 | README and default backend reference abandoned terraform-lsp instead of terraform-ls | [details](./terraform.md) |
| `csv` | underbuilt | 7 | 0 | 1 | Layer header docstring incorrectly says 'csharp Layer' | [details](./csv.md) |
| `shell-scripts` | underbuilt | 8 | 0 | 2 | zsh dialect not set for standard zsh dotfiles | [details](./shell-scripts.md) |
| `org` | adequate | 8 | 2 | 3 | Keybinding collision: SPC m r f and SPC m r u bound by both org-roam/org-roam-ui and verb in org-mode | [details](./org.md) |
| `latex` | adequate | 8 | 2 | 0 | lsp-latex commands loaded but none are bound to SPC m | [details](./latex.md) |
| `react` | adequate | 5 | 1 | 1 | Layer is built on rjsx-mode; no tree-sitter (tsx-ts-mode / typescript-ts-mode) path and no TSX support | [details](./react.md) |
| `spacemacs-layouts` | adequate | 5 | 1 | 1 | layouts-ts-kill-other hardcodes helm, breaks for ivy and compleseus | [details](./spacemacs-layouts.md) |
| `git` | adequate | 8 | 1 | 2 | spacemacs/magit-toggle-whitespace uses removed Magit 3/4 API | [details](./git.md) |
| `lsp` | adequate | 10 | 1 | 5 | Three code-action bindings are permanent placeholder stubs | [details](./lsp.md) |
| `shell` | adequate | 6 | 1 | 1 | Dead advice silently drops eshell history persistence after shell-pop rewrite | [details](./shell.md) |
| `c-c++` | adequate | 6 | 1 | 1 | No tree-sitter mode support: c-ts-mode and c++-ts-mode are completely absent | [details](./c-c++.md) |
| `helm` | adequate | 7 | 0 | 3 | helm-swoop and helm-ag carry unresolved FIXME-remove markers pointing to a MELPA deprecation PR | [details](./helm.md) |
| `treemacs` | adequate | 6 | 0 | 2 | User has treemacs-persp loaded but scope silently stays 'Frames | [details](./treemacs.md) |
| `multiple-cursors` | adequate | 6 | 0 | 2 | mc/cmds-to-run-once documented as a layer variable but the pattern silently fails | [details](./multiple-cursors.md) |
| `spell-checking` | adequate | 8 | 0 | 0 | flyspell-correct-region not exposed — interactive batch correction unavailable | [details](./spell-checking.md) |
| `auto-completion` | adequate | 7 | 0 | 1 | company-box icon table hardcodes all-the-icons API with no feature guard | [details](./auto-completion.md) |
| `syntax-checking` | adequate | 7 | 0 | 2 | README code example for window-position is syntactically broken | [details](./syntax-checking.md) |
| `emacs-lisp` | adequate | 7 | 0 | 3 | emacs-lisp-format-on-save defaults to t but is undocumented and has no toggle | [details](./emacs-lisp.md) |
| `python` | mature | 7 | 0 | 1 | Free variable `msg` in spacemacs/python-shell-send-block fallback path | [details](./python.md) |

## Per-layer dotfile findings (things specific to *your* `.spacemacs`)

These are the highest-signal items because they affect your actual config today:

- **[`ansible`]** (high/gap) No LSP backend variable or lsp-ansible wiring despite lsp-mode having full ansible-ls support
- **[`ansible`]** (low/cleanup) company-ansible/LSP interaction is silently suppressed with no README documentation
- **[`auto-completion`]** (low/bug) company-box icon table hardcodes all-the-icons API with no feature guard
- **[`auto-completion`]** (medium/gap) User's dotfile omits LSP-recommended idle-delay and prefix-length tuning
- **[`auto-completion`]** (medium/modernization) spacemacs-default-company-backends includes stale pre-LSP backends
- **[`c-c++`]** (medium/bug) clangd switchSourceHeader extension defined but never key-bound, and the custom extension wrapper is also wrong
- **[`c-c++`]** (medium/gap) C++20 module file extensions (.cppm, .ixx) not registered in the layer
- **[`csv`]** (low/gap) No layer variables for optional column-highlighting (rainbow-csv)
- **[`dap`]** (low/cleanup) config.el ptvsd override comment is stale and misleading
- **[`dap`]** (medium/gap) No DAP integration in the OCaml layer despite dap-ocaml shipping in dap-mode
- **[`docker`]** (high/gap) No dockerfile-ts-mode support on Emacs 29+
- **[`emacs-lisp`]** (medium/bug) emacs-lisp-format-on-save defaults to t but is undocumented and has no toggle
- **[`ess`]** (medium/gap) ess-eval-visibly and other raw ESS package variables set via :variables without layer documentation
- **[`ess`]** (medium/gap) No ess-r-lsp-server selector variable or safe-local-variable property on ess-r-backend
- **[`git`]** (medium/bug) git-enable-magit-forge-plugin is an undefined zombie variable in user config
- **[`helm`]** (low/gap) User's sole helm customization (helm-swoop-pre-input-function) is not documented as a supported layer variable in README
- **[`helm`]** (medium/gap) No icon support (helm-icons / helm-ff-icon-mode) while peer layers ivy and compleseus both have opt-in icon toggles
- **[`html`]** (medium/gap) No `html-fmt-on-save` variable — user silently defaults to web-beautify with no auto-format
- **[`ibuffer`]** (medium/gap) No all-the-icons-ibuffer (or nerd-icons-ibuffer) icon integration despite user using all-the-icons
- **[`javascript`]** (medium/gap) Default formatter is web-beautify; no 'lsp value for javascript-fmt-tool
- **[`javascript`]** (medium/gap) javascript-repl not set in user's dotfile: user silently gets skewer (browser-based) not nodejs
- **[`kubernetes`]** (high/gap) No layer variables — zero user-customisable behaviour
- **[`kubernetes`]** (low/gap) No YAML/Helm-chart LSP integration wired from this layer
- **[`latex`]** (high/gap) lsp-latex commands loaded but none are bound to SPC m
- **[`latex`]** (low/gap) latex-build-command "LaTeX" suppresses auctex-latexmk despite latexmk on PATH — silent LSP pipeline divergence undocumented
- **[`lsp`]** (medium/bug) lsp-origami unconditionally enables origami-mode, overriding the user's configured fold method
- **[`markdown`]** (high/gap) grip-mode manually wired in user dotfile instead of being a layer-managed package
- **[`markdown`]** (high/gap) No LSP backend (marksman) — lsp-mode support exists but is unwired
- **[`markdown`]** (medium/gap) No flycheck/lint integration despite flycheck supporting markdownlint natively
- **[`markdown`]** (medium/gap) No formatter integration (prettier is installed and supports Markdown)
- **[`multiple-cursors`]** (low/gap) User uses bare multiple-cursors symbol — evil-mc-enable-bar-cursor silently disabled on macOS
- **[`nginx`]** (high/gap) No LSP integration despite mature server support
- **[`nginx`]** (medium/gap) Missing config.el — no layer variables defined
- **[`nginx`]** (medium/gap) No completion backend (company-nginx or LSP capf)
- **[`org`]** (high/gap) No org-cite / citar integration: built-in citation system is completely absent
- **[`org`]** (low/gap) org-appear-autoentities not set in init-org-appear: entity auto-reveal disabled
- **[`org`]** (low/gap) User config is sparse relative to available layer features: roam, modern, appear, capture templates all absent
- **[`org`]** (medium/bug) valign and org-modern-table conflict not detected or mitigated in code
- **[`pdf`]** (high/bug) :custom override silently discards the user's pdf-view-use-scaling layer variable
- **[`pdf`]** (low/enhancement) No org-noter integration hint or optional package
- **[`ranger`]** (high/gap) No layer-level integration for any dirvish extension module
- **[`ranger`]** (medium/bug) ranger-show-preview / ranger-show-hidden are silently ignored in dirvish mode
- **[`react`]** (high/modernization) Layer is built on rjsx-mode; no tree-sitter (tsx-ts-mode / typescript-ts-mode) path and no TSX support
- **[`react`]** (medium/bug) react-backend variable set by the user is ignored; backend dispatch keys off javascript-backend
- **[`rust`]** (high/bug) User dotfile and README both use obsolete `rustic-format-on-save`; the replacement is `rustic-format-trigger`
- **[`rust`]** (low/gap) rustic-babel org-babel integration is not registered in the layer
- **[`shell-scripts`]** (low/bug) flycheck-bashate configured unconditionally but bashate is not installed
- **[`shell-scripts`]** (low/gap) User has shfmt installed but format-on-save is not enabled and no shfmt-args configured
- **[`shell`]** (medium/gap) vterm M-r history search has no consult handler; user's helm setup is also inert because spacemacs-vterm-history-file-location is unset
- **[`spacemacs-layouts`]** (low/enhancement) User has auto-resume and autosave both disabled with no explicit intent signalled
- **[`spell-checking`]** (low/cleanup) enable-flyspell-auto-completion breaks layer naming convention
- **[`spell-checking`]** (medium/gap) flyspell-correct-region not exposed — interactive batch correction unavailable
- **[`sql`]** (high/gap) Flycheck sql-sqlint checker never activated
- **[`sql`]** (low/bug) User has lsp enabled but sqls is on PATH and working — 'sqls not found' evidence claim is false
- **[`syntax-checking`]** (low/gap) No helm-flycheck integration despite user using helm as completion framework
- **[`syntax-checking`]** (medium/gap) No variable to hand diagnostic responsibility to lsp-mode's native provider
- **[`toml`]** (high/gap) Add LSP backend support (taplo / tombi) via toml-enable-lsp variable
- **[`toml`]** (low/cleanup) README.org is a stub with no key bindings, no configuration variables, and no feature description
- **[`toml`]** (medium/gap) Add flycheck/flymake integration for TOML syntax validation
- **[`treemacs`]** (low/gap) lsp-treemacs-sync-mode never enabled despite lsp + treemacs both being active
- **[`treemacs`]** (medium/bug) User has treemacs-persp loaded but scope silently stays 'Frames
- **[`treemacs`]** (medium/gap) git-mode defaults to nil — file status decorations silently disabled
- **[`treemacs`]** (medium/gap) treemacs-nerd-icons not supported as an icon theme option
- **[`typescript`]** (high/gap) DAP debugging entirely absent despite user enabling the dap layer
- **[`typescript`]** (low/bug) Self-acknowledged bug in typescript/set-lsp-linter — tslint path is incomplete
- **[`vimscript`]** (medium/gap) No formatter wired in; user has noted the gap explicitly
- **[`windows-scripts`]** (high/gap) No LSP/eglot backend for PowerShell despite lsp-pwsh shipping full plumbing
- **[`yaml`]** (high/gap) No yaml-ts-mode support despite Emacs 30.2 being in use

## Suggested new layers (you don't enable these yet)

Scouted across 3 domains; deduped, ranked by value then number of independent mentions. `builtin-layer` = already in this fork, just add to `dotspacemacs-configuration-layers`.

> Notes: `restclient` and `verb` overlap (both HTTP clients — pick one; `verb` is org-native, `restclient` is plain-`.http`). The `tree-sitter` layer here is the older `tree-sitter-hl` package; prefer the per-layer built-in `*-ts-mode` approach from recurring-theme #1 above on Emacs 29+.

| Layer/pkg | Value | Mentions | Availability | What it provides |
|---|---|---|---|---|
| `restclient` | high | 3× | builtin-layer | restclient-mode for .http files: execute HTTP requests from a plain-text buffer, pretty-print responses, ob-restclient for org-bab |
| `version-control` | high | 3× | builtin-layer | diff-hl or git-gutter fringe/margin hunk indicators in every buffer, SPC g. version-control transient-state (navigate/stage/revert |
| `json` | high | 2× | builtin-layer | json-mode with syntax highlighting, json-snatcher (SPC m g p — get path to value under point), json-navigator (navigable hierarchy |
| `dtrt-indent` | high | 1× | builtin-layer | Auto-detects the indentation style (tabs vs spaces, width) of any file on open and silently adjusts Emacs settings to match, preve |
| `evil-better-jumper` | high | 1× | builtin-layer | Replaces evil's built-in jump list with a configurable, per-window or per-buffer jump history. C-o / C-i navigate the list correct |
| `evil-snipe` | high | 1× | builtin-layer | 2-character forward/backward search bound to s/S in normal mode, replacing the slower f/t single-char motions. Works across the wh |
| `go` | high | 1× | builtin-layer | Full Go IDE: gopls LSP backend (completion, go-to-def, rename, type info), gofmt/goimports on save, golangci-lint, DAP debugger vi |
| `helpful` | high | 1× | builtin-layer | Drops in as a transparent replacement for C-h f/v/k, showing inline source code, caller/callee references, and edebug toggle — all |
| `llm-client` | high | 1× | builtin-layer | Installs and configures gptel (a fast, async LLM chat client) and optionally Ellama. gptel streams responses, works in any buffer, |
| `copy-as-format` | medium | 2× | builtin-layer | Single-command copying of any code region as pre-formatted markup for GitHub, GitLab, Slack, JIRA, Bitbucket, Org, Markdown, HTML, |
| `graphql` | medium | 2× | builtin-layer | graphql-mode syntax highlighting, graphql-send-query (SPC m s), endpoint selection (SPC m e), header editing (SPC m h), prettier f |
| `prodigy` | medium | 2× | builtin-layer | A Magit-style buffer for declaring, starting, stopping, and tailing output of named external services (local dev servers, backgrou |
| `protobuf` | medium | 2× | builtin-layer | protobuf-mode with syntax highlighting, correct indentation, flycheck integration against the protoc compiler, imenu buffer naviga |
| `denote` | medium | 1× | builtin-layer | File-naming-scheme-based note system (timestamp + keywords + title in filename) with Org and plain-text support, backlinks, dynami |
| `imenu-list` | medium | 1× | builtin-layer | Persistent sidebar showing the current buffer's symbol/heading outline (functions, classes, sections) via imenu, auto-updating on  |
| `mermaid` | medium | 1× | builtin-layer | mermaid-mode for .mmd files, compile-to-image bindings (SPC m c c/f/b/r), browser preview, org-babel mermaid blocks when org-enabl |
| `nav-flash` | medium | 1× | builtin-layer | Briefly highlights the current line after any large navigation event (imenu jump, LSP definition jump, buffer switch, window chang |
| `pandoc` | medium | 1× | builtin-layer | pandoc-mode (interactive conversion menu) and ox-pandoc (Org export backend) — adds Org -> DOCX, Org -> GitHub-Flavored Markdown,  |
| `systemd` | medium | 1× | builtin-layer | Syntax highlighting, autocompletion, and systemd-analyze-based syntax checking for .service/.timer/.socket unit files. Also instal |
| `tree-sitter` | medium | 1× | builtin-layer | tree-sitter-hl-mode replaces regex font-lock with AST-driven syntax highlighting for all major languages; optional ts-fold for str |
| `verb (external package, no layer yet)` | medium | 1× | custom-needed | A modern org-mode-native HTTP client. Requests live inside org headings as a tree; child headings inherit headers and base URLs fr |
| `ipython-notebook` | low | 1× | builtin-layer | EIN (emacs-ipython-notebook) layer: connect to a running Jupyter server, open/edit/execute notebooks in Emacs with a transient-sta |

## Re-running

```sh
# all enabled layers + scout, on sonnet:
Workflow layer-audit  (args: {"model":"sonnet"})
# subset:
Workflow layer-audit  (args: {"layers":["rust","dap"],"model":"opus"})
```

The workflow only reads and returns data; it never edits files or opens issues. Deliverables (this dir) and GitHub issues are produced in a separate, reviewed step.
