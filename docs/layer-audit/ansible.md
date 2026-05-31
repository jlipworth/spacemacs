# Layer audit: `ansible`  (`+tools/ansible`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification holds the original maturity rating. The layer is frozen in 2016-era Ansible workflow. All five files are byte-for-byte identical to syl20bnr/develop. LSP activation happens incidentally through the yaml→ansible-mode chain (because yaml-enable-lsp=t triggers lsp in yaml-mode-hook, then lsp-ansible activates when ansible-mode minor mode is present), but the ansible layer has zero explicit LSP code, zero lsp-ansible keybindings, no yaml-ts-mode hooks, and no tests. The finding adjustments below are scope corrections, not severity reversals.

## Findings

### HIGH · gap · effort M — No LSP backend variable or lsp-ansible wiring despite lsp-mode having full ansible-ls support

_status: confirmed · deliverable: issue_

Add an `ansible-backend` layer variable (values: nil or lsp) in config.el mirroring yaml-enable-lsp. In packages.el, add `(lsp-mode :requires lsp)` to the package list with `:toggle (eq ansible-backend 'lsp)`, and in the init function call `(add-hook 'ansible-mode-hook #'lsp)`. Change the existing `unless yaml-enable-lsp` guard to `unless (or yaml-enable-lsp (eq ansible-backend 'lsp))`. Add SPC m l keybindings for lsp-ansible-resync-inventory and lsp-ansible-show-server-metadata. Add `(defvar ansible-backend nil)` with a `put ... 'safe-local-variable #'symbolp` call. Update README.org with a Variables table and an LSP section. Note: even without this change, ansible-ls already activates for users with yaml-enable-lsp=t — the gap is that nothing is documented, gated, or keymapped.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/config.el: no ansible-backend or ansible-enable-lsp defvar exists; only ansible-auto-encrypt-decrypt is defined
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:73: `unless yaml-enable-lsp` suppresses company-ansible hook — the only LSP-aware line in the entire layer, and it references the yaml layer's variable, not an ansible-layer variable
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el: grep for 'lsp' returns only line 73 — no (lsp-mode :requires lsp) package entry, no (add-hook ... #'lsp), no lsp-ansible require
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-ansible.el:210-215: lsp-ansible-check-ansible-minor-mode checks (derived-mode-p 'yaml-mode OR 'yaml-ts-mode) AND (bound-and-true-p ansible-mode) — the server activates incidentally when yaml-enable-lsp=t causes lsp to run in yaml-mode-hook, then ansible-mode activates via spacemacs/ansible-maybe-enable
- /Users/jlipworth/GNU_files/.spacemacs:70-76 and 104-106: user has lsp layer with lsp-enable-snippet t and yaml-enable-lsp t — ansible-ls is running for this user but is entirely opaque
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-ansible.el:219-235: lsp-ansible-resync-inventory and lsp-ansible-show-server-metadata are interactive commands with no ansible-layer keybindings

### MEDIUM · modernization · effort S — ansible-doc.el is a dead package (last commit 2016) — no replacement offered

_status: adjusted · deliverable: issue_

Gate ansible-doc behind `(unless (eq ansible-backend 'lsp))` (once finding #1 is implemented) or `(unless yaml-enable-lsp)` as an immediate fix. When ansible-ls is active, hover already provides module docs and ansible-doc adds startup cost (it runs `ansible-doc --list` on first completion). For non-LSP users, keep ansible-doc but add a README note that it is unmaintained. The emacsorphanage attribution in the original audit may be inaccurate (the pkg file lists lunaryorn), but the 2016 staleness is confirmed.

**Evidence:**
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/ansible-doc-20160924.824/ansible-doc-pkg.el: Package-Version 20160924.824, commit bc8128a85a79 — no changes in nearly a decade
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/ansible-doc-20160924.824/ansible-doc.el: URL listed as https://github.com/lunaryorn/ansible-doc.el (pkg metadata); actual current MELPA recipe points to emacsorphanage — the auditor's specific emacsorphanage claim is unverifiable from local files alone but the staleness is proven by the 2016 Package-Version
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:50-58: layer unconditionally installs ansible-doc and enables ansible-doc-mode for all matching YAML files
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-ansible.el:68-87: ansible-ls provides hover docs, FQCN completion with full option enumeration, superseding ansible-doc for LSP users

### MEDIUM · bug · effort S — Filename detection regex does not cover the modern Ansible Collections layout or molecule paths

_status: adjusted · deliverable: issue_

The finding is real but the specific example in the original audit was wrong: paths inside collections that use roles/, tasks/, etc. subdirectories DO match the existing regex. The real gaps are: (1) `playbooks/` directory (flat playbook repos and collection playbooks without tasks/ subdirs), (2) `molecule/` directory for molecule test scenarios, and (3) collection-root-level paths like `plugins/modules/`. Extend the alternation to add `playbooks` alongside `roles`. Add `molecule` for molecule test scenarios. Update the comment URL. Do not add `ansible_collections` as a path prefix since it already works via the existing alternation when standard Ansible directory names are present.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/config.el:33-34: regex is `/(main|site|encrypted|((roles|tasks|handlers|vars|defaults|meta|group_vars|host_vars)/.+))\.ya?ml$`
- Direct regex test confirms: `/project/ansible_collections/ns/col/roles/foo/tasks/main.yml` DOES match (contains tasks/), contradicting the auditor's specific example
- Direct regex test confirms these paths DO NOT match: `/project/playbooks/install.yml` (playbooks/ not in alternation), `/molecule/default/converge.yml` (molecule not in alternation), `/ansible_collections/ns/col/plugins/modules/foo.yml` (plugins/ not in alternation)
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/config.el:32: comment still links to deprecated docs URL http://docs.ansible.com/playbooks_best_practices.html
- Ansible 2.9+ collections structure introduces playbooks/ as a standard directory name at collection root that is not in the alternation

### MEDIUM · gap · effort S — No tree-sitter / yaml-ts-mode support in the ansible activation chain

_status: adjusted · deliverable: issue_

The gap is confirmed and broader than the original audit stated — it also affects the vault auto-decrypt-encrypt hook (yaml-mode-local-vars-hook, line 41-44) and the auto-mode-alist entry (line 89-90). Add yaml-ts-mode-hook variants for all four yaml-mode-hook registrations, add yaml-ts-mode-local-vars-hook for the vault hook, and add a post-init-yaml-ts-mode function mirroring post-init-yaml-mode. The yaml layer itself has the same gap (also noted in evidence), so a coordinated fix is preferable. Note that yaml-ts-mode-local-vars-hook is a synthetic Spacemacs hook generated by the spacemacs//run-local-vars-mode-hook infrastructure (confirmed in spacemacs-defaults/funcs.el line 26) so no new infrastructure is needed.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:36: add-hook targets yaml-mode-hook only, not yaml-ts-mode-hook
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:41-44: yaml-mode-local-vars-hook is used for auto-decrypt-encrypt; no yaml-ts-mode-local-vars-hook variant exists
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:54: ansible-doc hook targets yaml-mode-hook only
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:76: company-ansible hook targets yaml-mode-hook only
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:87-90: spacemacs/declare-prefix-for-mode and auto-mode-alist entry target yaml-mode not yaml-ts-mode
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-ansible.el:213-214: lsp-ansible itself already checks `(derived-mode-p 'yaml-ts-mode)` — so LSP is ahead of the layer here
- grep -rn 'yaml-ts-mode' /Users/jlipworth/.emacs.d/layers/ returns nothing — the yaml layer itself also does not handle yaml-ts-mode

### LOW · modernization · effort S — All three .el files have lexical-binding: nil — should be converted to t

_status: confirmed · deliverable: issue_

Change lexical-binding: nil to lexical-binding: t in config.el, funcs.el, and packages.el. The only dynamic-binding concern is `defvar ac-user-dictionary-files nil` in packages.el line 67, which uses defvar intentionally for a pre-existing ac-mode variable and is safe under lexical binding. No other dynamic binding patterns exist. Note: this affects 518+ files across the codebase — a bulk conversion PR would be more efficient than targeting ansible alone.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/config.el:1: lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/funcs.el:1: lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:1: lexical-binding: nil
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/layers.el:1: lexical-binding: t (already converted by commit c35a6712)
- git log in repo confirms commit c35a6712 'Enable lexical-binding in all layers.el files' is real and only touched layers.el files
- 518 other layer files across the codebase also have lexical-binding: nil — this is not ansible-specific

### LOW · gap · effort M — No layer-level tests exist for ansible

_status: confirmed · deliverable: issue_

Create tests/layers/+tools/ansible/ with test-ansible.el exercising spacemacs//ansible-should-enable? against a fixture table: paths that must match (roles/foo/tasks/main.yml, host_vars/myhost.yml, group_vars/all.yml, site.yml, main.yml) and paths that must not (plain.yml, inventory.ini, /tmp/test.yml). Add a Makefile following the pattern in tests/layers/+lang/python/Makefile. This is especially valuable if finding #3 (regex extension) is implemented.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*ansible*' returns nothing
- /Users/jlipworth/.emacs.d/tests/layers/ contains only +distribution/ and +lang/ subdirs — no +tools/ test directory exists at all
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/funcs.el:24-47: spacemacs//ansible-should-enable? and three ansible-*-maybe-enable functions have pure, testable logic against spacemacs--ansible-filename-re
- /Users/jlipworth/.emacs.d/tests/layers/+lang/python/ exists as the gold-standard test harness (init.el, layers-ftest.el, Makefile)

### LOW · cleanup · effort S — company-ansible/LSP interaction is silently suppressed with no README documentation

_status: confirmed · deliverable: issue_

Update README.org to add: (1) a Variables table documenting ansible-auto-encrypt-decrypt and the relationship to yaml-enable-lsp; (2) a Backends section explaining that when yaml-enable-lsp is t, company-ansible is suppressed and ansible-ls provides richer FQCN-aware completion; (3) note that lsp-ansible-add-on? being t means ansible-ls runs alongside yamlls (two LSP servers) for ansible files; (4) a first-use note that `M-x lsp-install-server RET ansible-ls RET` is required. This is a documentation-only change.

**Evidence:**
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/packages.el:73: `unless yaml-enable-lsp` suppresses company-ansible hook — uses the yaml layer's variable
- /Users/jlipworth/GNU_files/.spacemacs:104-106: user has yaml-enable-lsp t, so company-ansible is already suppressed silently
- /Users/jlipworth/.emacs.d/layers/+tools/ansible/README.org: grep for 'lsp', 'LSP', 'language server', 'backend' returns 0 matches
- README.org only documents one layer variable (ansible-auto-encrypt-decrypt) with no variables table
- /Users/jlipworth/.emacs.d/elpa/30.2/develop/lsp-mode-20260518.1214/lsp-ansible.el:37-44: lsp-ansible-add-on? defaults to t, meaning ansible-ls runs alongside yamlls as dual servers — this is also undocumented

## Additional gaps caught in verification

- **(low/cleanup)** spacemacs--ansible-filename-re set with bare setq instead of defvar — generates byte-compiler warning — Replace `(setq spacemacs--ansible-filename-re ...)` with `(defvar spacemacs--ansible-filename-re ...)` in config.el. Add a docstring. This eliminates the byte-compiler free-variable warning and follows the pattern used for ansible-auto-encrypt-decrypt in the same file.
- **(low/modernization)** ansible-mode minor mode has an obsolete function alias still referenced in use-package :commands — The `:modes ansible` in `spacemacs|add-company-backends` hooks into `ansible-hook` (the legacy name), not `ansible-mode-hook`. Currently this works because ansible.el still defines and runs ansible-hook alongside ansible-mode-hook. However, since the function alias was deprecated in 2024-11-28, the hook name may follow. Consider changing `:modes ansible` to use the hook explicitly via a direct `add-hook 'ansible-mode-hook` call, or verify that ansible-hook and ansible-mode-hook are kept in sync by the upstream package long-term.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

