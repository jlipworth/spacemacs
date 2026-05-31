# Layer audit: `docker`  (`+tools/docker`)

**Maturity:** `underbuilt`  
**Upstream delta:** n/a

Verification confirms the underbuilt rating. All seven original findings are real. Findings 1 and 2 have their mechanism/severity adjusted: the stale docker-machine binding is a deferred hook entry that silently waits forever (not a map creation), and the missing docker-context 'q' binding deserves medium not high severity. Finding 3 (dockerfile-ts-mode) is confirmed and deepened: bind-map's activation logic uses exact major-mode equality, not derived-mode-add-parents, so SPC m keybindings are also absent from dockerfile-ts-mode buffers, not just the LSP hook. Two missed findings were identified: the SPC m b/B key mismatch in the README (keys change to SPC m c b/B when lsp backend is enabled, but the undeclared 'c' prefix is never documented), and the stale docker-tramp README section (the package is excluded on Emacs 29+ but the README still instructs users to rely on it, while Emacs 29+ ships tramp-container.el with built-in /docker: support).

## Findings

### HIGH · gap · effort M — No dockerfile-ts-mode support on Emacs 29+

_status: confirmed · deliverable: issue_

On Emacs 29+, dockerfile-ts-mode activates for Dockerfile buffers when the tree-sitter grammar is installed. It derives from prog-mode and uses derived-mode-add-parents to add dockerfile-mode as a pseudo-parent. bind-map (which powers SPC m) checks exact major-mode equality, so spacemacs-dockerfile-mode-map is not activated in dockerfile-ts-mode buffers. The LSP hook only fires for dockerfile-mode-local-vars-hook. Fix requires: (1) add-hook dockerfile-ts-mode-local-vars-hook #'spacemacs//docker-dockerfile-setup-backend guarded by (version<= "29" emacs-version); (2) replicate SPC m keybindings for 'dockerfile-ts-mode; (3) (spacemacs|define-jump-handlers dockerfile-ts-mode) in config.el; (4) (spacemacs/enable-flycheck 'dockerfile-ts-mode) in post-init-flycheck; (5) add treesit-install-language-grammar instruction to README. This directly affects this user who has docker-dockerfile-backend set to 'lsp at .spacemacs:201.

**Evidence:**
- /opt/homebrew/Cellar/emacs-plus@30/30.2/share/emacs/30.2/lisp/progmodes/dockerfile-ts-mode.el exists as a built-in
- dockerfile-ts-mode.el:130: (define-derived-mode dockerfile-ts-mode prog-mode ...) — derives from prog-mode, not dockerfile-mode
- dockerfile-ts-mode.el:168: (derived-mode-add-parents 'dockerfile-ts-mode '(dockerfile-mode)) — pseudo-parent, not actual derivation
- bind-map-20251119.201/bind-map.el:188: (memq major-mode expanded) — activation uses exact mode name match; derived-mode-add-parents is NOT consulted
- layers/+tools/docker/packages.el:50: add-hook to dockerfile-mode-local-vars-hook only — dockerfile-ts-mode-local-vars-hook never set up
- spacemacs-defaults/funcs.el:26: (run-hooks (intern (format "%S-local-vars-hook" major-mode))) — hook name is mode-specific, so dockerfile-ts-mode runs dockerfile-ts-mode-local-vars-hook, not dockerfile-mode-local-vars-hook
- lsp-mode.el:975: (dockerfile-ts-mode . "dockerfile") — LSP language ID is mapped, so LSP would activate if the hook were present
- /Users/jlipworth/GNU_files/.spacemacs:200-202: user has docker-dockerfile-backend set to 'lsp, so this gap directly affects them

### MEDIUM · bug · effort S — docker-machine-mode-map binding is a stale deferred hook that never fires

_status: adjusted · deliverable: issue_

The layer registers an evil 'q' binding on docker-machine-mode-map, which does not exist in the installed docker.el (machine support was removed in commit 916686b). The evil-define-key macro uses evil-with-delay, which adds a hook entry to after-load-functions waiting for the condition (boundp 'docker-machine-mode-map) to become true. It never does, so the hook accumulates silently. The auditor's description that it 'silently creates a sparse keymap' is mechanically wrong — no map is created — but the conclusion (dead code, permanent deferred hook) is correct. Remove line 41 from packages.el. See Finding 2 for the correct replacement.

**Evidence:**
- layers/+tools/docker/packages.el:41: (evil-define-key 'normal docker-machine-mode-map (kbd "q") 'quit-window)
- ls /Users/jlipworth/.emacs.d/elpa/30.2/develop/docker-20260126.1212/ shows no docker-machine.el — the file does not exist in package revision 916686b
- grep -rn 'machine' /Users/jlipworth/.emacs.d/elpa/30.2/develop/docker-20260126.1212/ --include='*.el' returns zero results
- evil-core.el:986-993: evil-define-key expands to (evil-with-delay (and (boundp 'docker-machine-mode-map) (keymapp docker-machine-mode-map)) (after-load-functions ...) ...) — condition never becomes true so a function is permanently registered in after-load-functions

### MEDIUM · bug · effort S — docker-context-mode-map missing evil 'q' quit binding

_status: adjusted · deliverable: issue_

tablist-minor-mode-map does bind 'q' to tablist-quit, but in evil normal state evil-record-macro shadows it, so evil users opening the Contexts buffer via the docker transient cannot press 'q' to quit. This matches the exact same problem the layer already solves for docker-image-mode-map, container, volume, and network. Add (evil-define-key 'normal docker-context-mode-map (kbd "q") 'quit-window) to docker/init-docker in packages.el alongside the other bindings. Severity is medium (not high) because :q and C-x k remain functional — this is an ergonomic inconsistency, not a broken feature.

**Evidence:**
- docker-context.el:158: (defvar docker-context-mode-map ...) confirms the map exists
- docker-context.el:175: (define-derived-mode docker-context-mode tabulated-list-mode ...) with (tablist-minor-mode) call
- tablist-20231019.1126/tablist.el:184: tablist-minor-mode-map has (define-key kmap "q" #'tablist-quit) — but in evil normal state, 'q' is shadowed by evil-record-macro
- layers/+tools/docker/packages.el:37-41: docker-image-mode-map, docker-container-mode-map, docker-volume-mode-map, docker-network-mode-map all get evil 'q' bindings; docker-context-mode-map is absent

### MEDIUM · gap · effort M — docker-compose commands advertised but not bound under SPC m

_status: confirmed · deliverable: issue_

The README claim of compose integration is technically satisfied via the docker.el transient (SPC a t d -> C), but the layer adds zero dedicated SPC m shortcuts. For users working in Dockerfile or docker-compose.yml files, there are no mode-local bindings for common compose workflows. Approach: add a SPC m C prefix in docker/init-dockerfile-mode with direct calls to docker-compose-up, docker-compose-down, docker-compose-logs (via wrapper functions calling the transient or directly) for dockerfile-mode (and dockerfile-ts-mode when that gap is fixed). Declare the 'C' prefix with spacemacs/declare-prefix-for-mode. Update README.org to document the new bindings.

**Evidence:**
- README.org:26: 'docker-compose integration via docker.el' listed as a feature
- layers/+tools/docker/packages.el: zero references to compose or docker-compose
- docker-core.el:166: ("C" "Compose" docker-compose) — compose is in the main docker transient at SPC a t d then C
- docker-compose.el:302-335: docker-compose transient defines build, down, up, logs, exec, pull, push, rm, restart, start, stop, create, pause, unpause subcommands
- docker-compose.el has no interactive commands that bypass the transient — all access is via the transient hierarchy

### LOW · modernization · effort S — lexical-binding disabled in config.el, funcs.el, packages.el

_status: confirmed · deliverable: issue_

The docker layer's funcs.el, config.el, and packages.el disable lexical binding. The code is simple with no dynamic binding requirements. Enabling lexical-binding: t is a one-line change per file and follows modern Emacs Lisp best practice. Change the first-line cookie in packages.el, config.el, and funcs.el from nil to t. No code changes needed, only the cookie.

**Evidence:**
- layers/+tools/docker/packages.el:1: -*- lexical-binding: nil; -*-
- layers/+tools/docker/config.el:1: -*- lexical-binding: nil; -*-
- layers/+tools/docker/funcs.el:1: -*- lexical-binding: nil; -*-
- layers/+tools/docker/layers.el:1: -*- lexical-binding: t; -*- (already correct)
- funcs.el contains only one function (spacemacs//docker-dockerfile-setup-backend) with no dynamic binding dependencies

### LOW · gap · effort M — No layer functional tests

_status: confirmed · deliverable: issue_

No functional tests exist for this layer. Given that the layer contains a stale docker-machine binding (finding 1) and a missing docker-context binding (finding 2) that would both be caught by a smoke test, this gap has demonstrated its cost. Create tests/layers/+tools/docker/ with init.el, Makefile, and layers-ftest.el following the python template. At minimum test: layer loads without error, docker-dockerfile-backend defaults to nil, SPC m bindings are present in dockerfile-mode, docker-context-mode-map has evil 'q' binding.

**Evidence:**
- find /Users/jlipworth/.emacs.d/tests -name '*docker*' returns nothing
- ls /Users/jlipworth/.emacs.d/tests/layers/ shows only +distribution and +lang — no +tools directory
- tests/layers/+lang/python/ contains init.el, layers-ftest.el, Makefile as the established template

### LOW · cleanup · effort S — README install instructions have multiple inaccuracies

_status: adjusted · deliverable: issue_

The README's LSP section should: (1) note that the binary installed by the npm package is docker-langserver (not dockerfile-language-server-nodejs) to aid PATH troubleshooting; (2) add a tree-sitter section noting that on Emacs 29+ users should run (treesit-install-language-grammar 'dockerfile) to enable dockerfile-ts-mode; (3) add 'brew install hadolint' as the primary macOS install method. The npm package name itself (dockerfile-language-server-nodejs) is correct — the auditor's claim that the package name is wrong is not accurate; only the missing binary name mention is a real issue.

**Evidence:**
- README.org:61: 'npm i -g dockerfile-language-server-nodejs' — npm package name is correct but binary name docker-langserver is never mentioned
- lsp-dockerfile.el:38-39: lsp-dockerfile-language-server-command defaults to '("docker-langserver" "--stdio") — users need to know the binary name for PATH troubleshooting
- README.org has no mention of dockerfile-ts-mode or treesit-install-language-grammar
- README.org:42-44: 'stack install hadolint' is listed as the only install method; brew install hadolint is the standard macOS approach

## Additional gaps caught in verification

- **(medium/bug)** README documents SPC m b/B but actual keys when using LSP backend are SPC m c b/B, with undeclared 'c' prefix — When docker-dockerfile-backend is set to 'lsp (the most common production configuration), build keybindings move to SPC m c b and SPC m c B. The README only documents SPC m b / SPC m B, making it incorrect for LSP users. Additionally, the 'c' prefix is never declared via spacemacs/declare-prefix-for-mode 'dockerfile-mode "mc" "compile" (or similar), so which-key displays no description for the c subgroup. Fix: (1) update the README to show both variants or document that when lsp backend is active, bindings are under SPC m c; (2) add (spacemacs/declare-prefix-for-mode 'dockerfile-mode "mc" "compile") in docker/init-dockerfile-mode. This is a documentation+UX bug that affects the repo owner directly.
- **(low/cleanup)** README still documents docker-tramp for users on Emacs 29+ where it is excluded and built-in support exists — The README instructs all users to use docker-tramp for container TRAMP access, but the package is silently excluded on Emacs 29+. Users on Emacs 29+ already have the built-in tramp-container.el which provides /docker: access without any extra package. The README should note the Emacs version split: (a) for Emacs 28 and earlier, docker-tramp is used automatically; (b) for Emacs 29+, the built-in /docker: TRAMP method is available and no additional setup is needed. This directly misleads the repo owner who is on Emacs 30.2 and has docker-tramp excluded.


---
_Generated by the layer-audit workflow (2026-05-31). Line numbers reflect the tree at audit time._

