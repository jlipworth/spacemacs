# Layer audit: `sql`  (`+lang/sql`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirmed all nine original findings. The layer covers the REPL/send workflow and keyword capitalization, but is materially thin: flycheck/sqlint is advertised but never wired; lsp-sqls commands are fully implemented in lsp-mode but none are exposed as keybindings; the goto prefix is a dead stub; the formatter points to a stale 2019 binary; lexical-binding is disabled in three of four files; and there are no tests. One factual error was found (sqls IS installed on this machine), and two missed findings were identified: a README vs code keybinding mismatch for the capitalize command, and the lsp-sqls-connections variable is never exposed as a layer variable. Rating stays underbuilt.

## Findings

### HIGH · gap · effort S — Flycheck sql-sqlint checker never activated

_status: confirmed · deliverable: issue_

sql-mode inherits from prog-mode (confirmed in /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/progmodes/sql.el:4112). The syntax-checking layer sets flycheck-global-modes to nil and relies on per-layer calls to spacemacs/enable-flycheck to opt modes in. The SQL layer never calls spacemacs/enable-flycheck, so sql-mode is never added to flycheck-global-modes, and flycheck is silently disabled for SQL buffers. Fix: add flycheck to sql-packages, add sql/post-init-flycheck calling (spacemacs/enable-flycheck 'sql-mode). Flycheck's built-in sql-sqlint checker will then be auto-selected when sqlint is on PATH.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/sql/packages.el:24-32: flycheck is absent from sql-packages list entirely
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/flycheck-20260320.1715/flycheck.el:12265: flycheck-define-checker sql-sqlint exists and targets sql-mode
- /Users/jlipworth/.emacs.d/layers/+checkers/syntax-checking/funcs.el:24-29: spacemacs/enable-flycheck adds a mode to flycheck-global-modes; nil is a valid list so the guard (listp flycheck-global-modes) passes even from the initial nil value set in packages.el:45
- /Users/jlipworth/GNU_files/.spacemacs:68: user has syntax-checking layer enabled
- /Users/jlipworth/.emacs.d/layers/+lang/sql/README.org:42: claims 'Syntax-checking via sqlint' but nothing in packages.el or funcs.el activates it — no flycheck post-init hook, no call to spacemacs/enable-flycheck

### HIGH · gap · effort M — LSP backend hardcoded to sqls only; postgres-language-server (lsp-postgres) completely ignored

_status: confirmed · deliverable: issue_

Three LSP clients now ship with lsp-mode for sql-mode: sqls (priority -2), lsp-sql/sql-language-server (priority -1), and lsp-postgres (priority -2). lsp-mode auto-selects the highest-priority client whose binary is present. On this machine, sqls is installed but sql-ls and postgres-ls are not, so sqls wins by default. However, a user who installs sql-ls would silently get a different server than expected because sql-ls has higher priority (-1 > -2). The layer should expose a sql-lsp-server variable (values: sqls, sql-ls, postgres-ls) and use it to filter lsp-mode client selection, similar to python-lsp-server. The existing sql-lsp-sqls-workspace-config-path forwarding in packages.el:91-96 is sqls-specific and needs a parallel branch for other servers.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/sql/config.el:38-46: only two backend values documented: lsp and company-sql; no postgres-ls option
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-postgres.el:81-89: lsp-postgres client (supabase-community/postgres-language-server) registered for sql-mode at priority -2
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-sql.el:54-62: lsp-sql (sql-language-server, Node.js) registered for sql-mode at priority -1 — HIGHER than sqls at -2
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-mode.el:9114: lsp-mode selects the client with the highest priority (--max-by >) among those whose binaries are present

### MEDIUM · gap · effort S — Rich lsp-sqls commands unexposed: execute-query, show-databases, switch-connection, switch-database never bound

_status: confirmed · deliverable: issue_

When sql-backend is lsp, the sqls server exposes execute-query, show-databases, show-schemas, show-connections, show-tables, switch-database, and switch-connection commands. None are bound to keys. Add a conditional (when (eq sql-backend 'lsp)) block registering these under e.g. SPC m x q (execute-query), SPC m x d (show-databases), SPC m x c (switch-connection), and populate the dead SPC m g prefix with lsp-find-definition-based bindings. The lsp-sqls-connections variable (line 62) should also be documented in README and exposed as an optional sql-lsp-sqls-connections layer variable alongside the existing sql-lsp-sqls-workspace-config-path.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-sqls.el:90-177: lsp-sql-execute-query, lsp-sql-execute-paragraph, lsp-sql-show-databases, lsp-sql-show-schemas, lsp-sql-show-connections, lsp-sql-show-tables, lsp-sql-switch-database, lsp-sql-switch-connection are all defined
- /Users/jlipworth/.emacs.d/layers/+lang/sql/packages.el:51-80: SPC m s keybindings bound only to generic sql-send-* forms; no lsp-sqls-specific commands
- /Users/jlipworth/.emacs.d/layers/+lang/sql/packages.el:47: SPC m g prefix declared with no bindings
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-sqls.el:62-67: lsp-sqls-connections variable exists for programmatic DB connection config but is never surfaced as a layer variable

### MEDIUM · modernization · effort M — sqlfmt formatter references stale Go binary (mjibson/sqlfmt v0.4.0); no sqlformat/pgformatter/sqlfluff option

_status: confirmed · deliverable: issue_

The local sqlfmt.el wraps a 2019 Go binary. The modern approach is to add the sqlformat MELPA package (purcell/sqlformat) which wraps pgformatter, python-sqlformat, and sqlfmt under a unified interface. Expose a sql-formatter layer variable (values: sqlfmt, pgformatter, sqlformat, sqlfluff) mirroring python-formatter in the python layer, and set sqlformat-command accordingly. Update README to replace the Linux-only wget with brew install pgformatter for macOS users.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/sql/README.org:64-65: install instructions hard-code sqlfmt_0.4.0_linux_amd64 wget — Linux-only, 2019-vintage binary
- /Users/jlipworth/.emacs.d/layers/+lang/sql/local/sqlfmt/sqlfmt.el:1-55: thin custom wrapper calling a sqlfmt-executable binary; no formatter selection
- /Users/jlipworth/.emacs.d/layers/+lang/sql/README.org:43: links to https://github.com/mjibson/sqlfmt which has had no releases since 2019

### LOW · bug · effort S — User has lsp enabled but sqls is on PATH and working — 'sqls not found' evidence claim is false

_status: adjusted · deliverable: issue_

The finding's primary evidence claim ('sqls not found on this machine') is factually wrong: sqls 0.2.28 is installed at /Users/jlipworth/go/bin/sqls. However the underlying gap (no validation/warning when sqls is absent) is real and affects any user who enables the lsp backend without installing sqls. The fix described — add a spacemacs//sql-check-backend function emitting a buffer warning when the expected binary is missing — is still worthwhile. Severity is downgraded to low because the specific user this audit is for is not affected.

**Evidence:**
- which sqls returns /Users/jlipworth/go/bin/sqls (sqls version 0.2.28)
- /Users/jlipworth/GNU_files/.spacemacs:152-155: sql layer configured with sql-capitalize-keywords t only; sql-backend absent so defaults to lsp via config.el:38
- /Users/jlipworth/.emacs.d/layers/+lang/sql/layers.el:24-26: lsp layer declared as dependency when sql-backend is lsp — correctly wired
- The core concern — no startup warning when sqls is missing — remains valid as a general robustness issue for other users

### LOW · bug · effort S — Dead SPC m g (goto) prefix: declared but entirely empty

_status: confirmed · deliverable: issue_

config.el declares jump handlers for sql-mode but packages.el and funcs.el never push any handler to spacemacs-jump-handlers-sql-mode. The SPC m g which-key popup is empty. Fix by either removing the declaration until content exists, or adding SPC m g g -> lsp-find-definitions gated on (eq sql-backend 'lsp).

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/sql/packages.el:47: (spacemacs/declare-prefix-for-mode 'sql-mode "mg" "goto") with no subsequent bindings under mg
- /Users/jlipworth/.emacs.d/layers/+lang/sql/config.el:24: (spacemacs|define-jump-handlers sql-mode) creates spacemacs-jump-handlers-sql-mode list but it is never populated
- /Users/jlipworth/.emacs.d/layers/+lang/sql/README.org: no SPC m g bindings anywhere in the key bindings table

### LOW · cleanup · effort S — lexical-binding disabled in config.el, packages.el, and funcs.el

_status: confirmed · deliverable: issue_

Three of four layer files opt out of lexical binding. Enable lexical-binding: t in config.el, packages.el, and funcs.el. The code uses no dynamic-binding closures that would break under lexical scope.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/sql/config.el:1: -*- lexical-binding: nil; -*-
- /Users/jlipworth/.emacs.d/layers/+lang/sql/packages.el:1: -*- lexical-binding: nil; -*-
- /Users/jlipworth/.emacs.d/layers/+lang/sql/funcs.el:1: -*- lexical-binding: nil; -*-
- /Users/jlipworth/.emacs.d/layers/+lang/sql/layers.el:1: -*- lexical-binding: t; -*- (already correct)

### LOW · gap · effort M — No layer tests at all

_status: confirmed · deliverable: issue_

No test directory under tests/layers/+lang/sql/. Scaffold following the python layer test harness pattern.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*sql*' returns nothing
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/: has init.el, layers-ftest.el, Makefile

### LOW · modernization · effort S — README install instructions outdated: sqlint is a dead Ruby gem, sqlfmt points to 2019 binary

_status: confirmed · deliverable: issue_

Replace sqlint recommendation with sqlfluff (pip install sqlfluff) as primary linter. Replace Linux-only sqlfmt wget with brew install pgformatter for macOS and pip install sqlfmt for dbt projects.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+lang/sql/README.org:56-59: recommends gem install sqlint (unmaintained since 2018)
- /Users/jlipworth/.emacs.d/layers/+lang/sql/README.org:64-65: wget of sqlfmt_0.4.0_linux_amd64.tar.gz — Linux-only, 2019 binary

## Additional gaps caught in verification

- **(medium/bug)** README documents SPC m = c for capitalize but code binds SPC m c — The README key bindings table places capitalize under the Code Formatting section and documents it as SPC m = c, but packages.el binds sqlup-capitalize-keywords-in-region to top-level 'c' (SPC m c) outside the formatting prefix. This means pressing SPC m = c does nothing (empty binding) while SPC m c works. Fix: either move the binding to '=c' inside init-sqlfmt (or a shared location), or correct the README to show SPC m c. Moving to =c is semantically cleaner since capitalization is a text transformation like formatting.
- **(low/gap)** lsp-sqls-connections variable never exposed as a layer variable — lsp-sqls supports two ways to configure DB connections: (1) a JSON config file located by lsp-sqls-workspace-config-path (already exposed as sql-lsp-sqls-workspace-config-path) and (2) the lsp-sqls-connections Emacs Lisp variable set directly. Users who want to configure connections without a JSON file (e.g., storing credentials in .spacemacs or an auth-source lookup) need to know about lsp-sqls internals. Add sql-lsp-sqls-connections as a layer variable in config.el and forward it via (setq lsp-sqls-connections sql-lsp-sqls-connections) in the post-init hook, alongside the existing workspace-path forwarding.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

