# Layer audit: `terraform`  (`terraform`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

The capability picture in the audit is accurate: the layer is thin (terraform-mode font-lock + fmt + format-on-save, gated company completion, an lsp toggle) with no tree-sitter, no lint/validate checker, no SPC m operational commands, and a README that still points at the abandoned terraform-lsp. All of this is inherited from an already-minimal upstream. HOWEVER, the audit's headline FORK-SPECIFIC finding — a duplicated spacemacs//terraform-setup-backend defun — is FALSE: funcs.el (40 lines) defines that function exactly once (lines 36-39); the other function is the distinct setup-company dispatcher (lines 24-34). With that defect removed, the fork is at parity with upstream (no fork-introduced bug), and the layer is underbuilt purely by inheritance, not by a botched cherry-pick. Rating remains 'underbuilt' on capability grounds, but the maturity narrative must drop the 'accidental defect' framing.

## Findings

### MEDIUM · modernization · effort S — README and default backend reference abandoned terraform-lsp instead of terraform-ls

_status: confirmed · deliverable: issue_

Confirmed. README.org explicitly instructs installing the abandoned terraform-lsp at line 40 and references it again at line 21. Recommend updating to terraform-ls (HashiCorp's maintained server), documenting lsp-mode's client selection (lsp-disabled-clients) and the lsp-terraform-ls-* config vars. Note this is inherited from upstream verbatim, so it is stale upstream guidance rather than a fork regression; severity medium is fair for a tool layer.

**Evidence:**
- README.org:39-45 LSP section says 'install terraform-lsp' and links https://github.com/juliosueiras/terraform-lsp
- README.org:21 feature line: 'LSP support for terraform-lsp via terraform-backend'
- juliosueiras/terraform-lsp is archived/unmaintained; HashiCorp's terraform-ls is the maintained server now recommended by lsp-mode

### MEDIUM · gap · effort M — No terraform-ls validate/init/version commands surfaced under SPC m

_status: confirmed · deliverable: issue_

Confirmed with an effort caveat. The layer surfaces no SPC m bindings at all. Adding lsp-terraform-ls-validate/init/version under the major-mode menu (gated on terraform-backend = 'lsp) would convert passive completion into an actionable workflow. Effort M is reasonable. Note the auditor's claim these commands 'would be live' depends on the user's .spacemacs enabling the lsp layer, which I could not re-verify here; the in-layer evidence (no bindings) is solid regardless.

**Evidence:**
- packages.el:38-45 init-terraform-mode only adds the setup-backend hook and (conditionally) terraform-format-on-save-mode; no spacemacs/set-leader-keys-for-major-mode bindings anywhere in the layer
- No SPC m menu entries exist in any layer file; the only major-mode interaction comes from terraform-mode itself
- User's config defaults terraform to the lsp backend (config.el:29 picks 'lsp when lsp layer used), so lsp-terraform-ls-* commands would be applicable

### MEDIUM · modernization · effort M — No tree-sitter support (terraform-ts-mode / treesit)

_status: confirmed · deliverable: md_

Confirmed. No tree-sitter path exists. An optional terraform-enable-treesit variable with grammar registration would improve highlighting/indentation/structural navigation while keeping LSP as the intelligence source. Effort M and severity medium are appropriate. Deliverable md (design note) is sensible given grammar packaging is non-trivial.

**Evidence:**
- packages.el:24-29 lists only company, company-terraform, terraform-mode; no treesit references in any layer file
- No terraform-ts-mode / major-mode-remap / treesit-language-source-alist usage anywhere in the layer
- terraform-mode is font-lock only; core Emacs ships no HCL *-ts-mode

### MEDIUM · gap · effort M — No linting integration (tflint or terraform validate as a checker)

_status: confirmed · deliverable: issue_

Confirmed. The layer contributes no checker. For LSP users, enabling lsp-terraform-ls-validate-on-save routes diagnostics into flycheck/lsp-ui with no extra config. For non-LSP users, a flycheck checker shelling to tflint or 'terraform validate' would add value. Effort M, severity medium fair. The claim about the user already running syntax-checking could not be re-verified (bash unavailable) but is not required for the gap.

**Evidence:**
- packages.el:24-29 declares no flycheck/flymake checker package
- No checker wiring anywhere in the layer; no SPC m c prefix
- For the LSP backend, diagnostics could flow via terraform-ls validate (lsp-terraform-ls-validate-on-save); for non-LSP, an external tflint/terraform validate checker would be needed

### LOW · cleanup · effort S — company-terraform is stale and stacks on top of LSP completion

_status: adjusted · deliverable: issue_

Adjusted. The substance is right (company-terraform is legacy and superseded by terraform-ls capf completion) but the title is slightly misleading: it does NOT stack on LSP. The gating in setup-company (funcs.el:26-34) correctly limits company-terraform to the non-LSP branch, which the audit's own detail acknowledges. This is purely a doc/cleanup item: note company-terraform as a legacy fallback in the README. No code change required.

**Evidence:**
- packages.el:26-27/34-36 declare company-terraform (:requires company); funcs.el:31-34 adds it as a backend ONLY in the 'company-terraform pcase branch of setup-company
- funcs.el:26-30 lsp branch adds company-capf only, so company-terraform does NOT stack on LSP
- config.el:29 defaults backend to 'lsp when lsp layer is used, so company-terraform stays inactive for those users

### LOW · gap · effort M — No tests; structurally minimal versus python gold standard

_status: adjusted · deliverable: md_

Adjusted. The 'no tests' observation is correct, but its justification leans on the now-rejected duplicate-defun claim ('exactly the kind of regression a smoke-test would catch'). That rationale is void since no duplicate exists. A minimal load/byte-compile smoke test plus backend-dispatch check is still reasonable but low priority for a config-only tool layer, and should follow the capability work. Keep severity low.

**Evidence:**
- Layer dir holds config.el, funcs.el, layers.el, packages.el, README.org, img/ — no tests subtree
- CLAUDE.md cites layers/+lang/python as having a tests/ tree; terraform has none

## Additional gaps caught in verification

- **(low/enhancement)** setup-company is run via post-init-company but never re-run if backend changes; lsp company-capf relies on lsp layer ordering — Minor: the company backend wiring is computed once at init from terraform-backend, which is itself fixed at config load. This is acceptable for normal use but means switching terraform-backend interactively has no effect without a restart. Low priority; documenting the load-time nature in the README would suffice.
- **(low/enhancement)** layers.el dependency declaration is guarded but config.el default can mismatch declaration timing — Edge case: the layers.el guard requires terraform-backend to be bound at declaration time. The config.el auto-default ('lsp when lsp layer present) is what makes lsp the implicit backend, but the explicit declare-layer-dependencies path only fires for users who set the variable themselves. In practice users who want LSP already enable the lsp layer, so this is benign, but it is a real ordering subtlety worth a code comment. Low priority.

## Rejected by verifier (false positives)

- ~~Duplicated defun spacemacs//terraform-setup-backend in funcs.el (fork-only defect)~~ — Read the entire 40-line funcs.el directly. setup-backend appears once (lines 36-39). No byte-identical duplicate exists. The cited line ranges (32-35, 37-40) span two unrelated functions. This is a false positive and the most important correction since it was the audit's central fork-specific finding and the basis for the 'accidental defect' framing in the maturity summary and the upstream_delta.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

