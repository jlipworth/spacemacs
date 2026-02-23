# Jupyter REPL Layer Runbook for Spacemacs

## Overview

This runbook documents the creation of a private Spacemacs layer (`jupyter-repl`) that provides a Jupyter kernel-backed REPL for Python development. This addresses the broken completion in `inferior-python-mode` on macOS by using `emacs-jupyter` for REPL interactions.

### Problem Statement

- `inferior-python-mode` completion is broken on macOS (readline issues with CPython)
- Standard Python REPL lacks rich output support (images, LaTeX, HTML)
- Need consistent completion behavior across platforms

### Solution

Use `emacs-jupyter` to provide:
- Full Jupyter kernel completion via ZMQ protocol
- Rich output rendering (images, LaTeX, markdown)
- Platform-consistent behavior
- Integration with existing conda/virtualenv workflows

---

## 1. Prerequisites

### System Requirements

#### Both macOS and Linux

```bash
# Python packages (in your active environment)
pip install jupyter ipykernel

# Verify jupyter is accessible
jupyter --version
jupyter kernelspec list
```

#### macOS-Specific

```bash
# Recommended: Install gnureadline to avoid readline issues
pip install gnureadline

# Ensure Emacs was built with module support (required for emacs-zmq)
emacs --version  # Should show 30.1 or later
# Verify modules: M-x describe-variable RET module-file-suffix RET
# Should return ".so" or ".dylib", not nil
```

#### Linux (Debian/Ubuntu)

```bash
# Build dependencies for emacs-zmq
sudo apt-get install libzmq3-dev autoconf automake libtool
```

### Emacs Requirements

- **Emacs 30.1+** built with `--with-modules` (required for emacs-zmq)
- **Spacemacs develop branch** (recommended for latest layer patterns)
- **python layer** enabled in `.spacemacs`

### Verify Module Support

```elisp
;; In *scratch* buffer, evaluate:
(featurep 'dynamic-modules)  ;; Should return t
module-file-suffix           ;; Should return ".so" or ".dylib"
```

---

## 2. Installation Steps

### Step 1: Create the Private Layer Directory

```bash
mkdir -p ~/.emacs.d/private/jupyter-repl
```

### Step 2: Create Layer Files

Create the following files in `~/.emacs.d/private/jupyter-repl/`:

- `packages.el` - Package declarations and initialization
- `funcs.el` - Helper functions
- `config.el` - Layer variables and configuration

(See Section 6 for complete file contents)

### Step 3: Enable the Layer

Add to `dotspacemacs-configuration-layers` in `.spacemacs`:

```elisp
dotspacemacs-configuration-layers
'(
  ;; ... other layers ...
  python
  jupyter-repl  ;; Add after python layer
  )
```

### Step 4: Restart Emacs

```
SPC q R  ;; Restart Emacs
```

On first load, `emacs-zmq` will compile (may take a minute).

---

## 3. Layer Configuration and Variables

### Layer Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `jupyter-repl-default-repl` | `'jupyter` | Default REPL backend: `'jupyter` or `'inferior-python` |
| `jupyter-repl-echo-eval-p` | `nil` | Show evaluated code in REPL buffer |
| `jupyter-repl-use-overlays` | `t` | Display short results inline as overlays |
| `jupyter-repl-maximum-size` | `10000` | Maximum REPL buffer lines before truncation |

### Configuration in .spacemacs

```elisp
(jupyter-repl :variables
              jupyter-repl-default-repl 'jupyter
              jupyter-repl-echo-eval-p nil
              jupyter-repl-use-overlays t)
```

---

## 4. Keybinding Reference

All keybindings follow Spacemacs REPL conventions under `SPC m s` (major mode, send).

### REPL Management

| Binding | Command | Description |
|---------|---------|-------------|
| `SPC m s j` | `spacemacs/jupyter-repl-start` | Start/switch to Jupyter REPL |
| `SPC m s i` | `spacemacs/python-start-or-switch-repl` | Start/switch to configured REPL |
| `SPC m '` | `spacemacs/python-start-or-switch-repl` | Quick REPL access |
| `SPC m s J` | `jupyter-repl-restart-kernel` | Restart current kernel |
| `SPC m s q` | `jupyter-repl-pop-to-buffer` | Pop to REPL buffer |

### Code Evaluation

| Binding | Command | Description |
|---------|---------|-------------|
| `SPC m s b` | `spacemacs/jupyter-send-buffer` | Send buffer (stay in source) |
| `SPC m s B` | `spacemacs/jupyter-send-buffer-switch` | Send buffer and switch to REPL |
| `SPC m s f` | `spacemacs/jupyter-send-defun` | Send current function |
| `SPC m s F` | `spacemacs/jupyter-send-defun-switch` | Send function and switch |
| `SPC m s r` | `spacemacs/jupyter-send-region` | Send region |
| `SPC m s R` | `spacemacs/jupyter-send-region-switch` | Send region and switch |
| `SPC m s l` | `spacemacs/jupyter-send-line` | Send current line |
| `SPC m s L` | `spacemacs/jupyter-send-line-switch` | Send line and switch |
| `SPC m s s` | `spacemacs/jupyter-send-line-or-region` | Send line or region (smart) |

### Inspection (in source buffer with associated REPL)

| Binding | Command | Description |
|---------|---------|-------------|
| `M-i` | `jupyter-inspect-at-point` | Inspect symbol at point |
| `C-c C-i` | `jupyter-repl-interrupt-kernel` | Interrupt kernel |
| `C-c C-r` | `jupyter-repl-restart-kernel` | Restart kernel |

### REPL Buffer Navigation

| Binding | Command | Description |
|---------|---------|-------------|
| `M-n` | History forward | Next history item |
| `M-p` | History backward | Previous history item |
| `C-s` | Search forward | Forward history search |
| `C-r` | Search backward | Backward history search |
| `C-l` | Clear REPL | Clear REPL output |

---

## 5. Switching Between REPL Backends

### Toggle REPL Backend

```elisp
;; Add to your dotspacemacs/user-config:

(defun spacemacs/toggle-jupyter-repl ()
  "Toggle between jupyter and inferior-python REPL."
  (interactive)
  (setq jupyter-repl-default-repl
        (if (eq jupyter-repl-default-repl 'jupyter)
            'inferior-python
          'jupyter))
  (message "REPL backend: %s" jupyter-repl-default-repl))

(spacemacs/set-leader-keys-for-major-mode 'python-mode
  "sT" 'spacemacs/toggle-jupyter-repl)
```

### Per-Project Configuration

Use `.dir-locals.el` in project root:

```elisp
;;; Directory Local Variables
((python-mode . ((jupyter-repl-default-repl . inferior-python))))
```

---

## 6. Conda/Virtualenv Integration

The jupyter-repl layer integrates with existing Python virtual environment tools.

### How It Works

1. Activate your environment using standard Spacemacs commands:
   - `SPC m v a` - Activate virtualenv
   - `SPC m v w` - Work on virtualenv
   - `SPC m v s` - Set pyenv version
   - `SPC m v p a` - Activate pipenv

2. Start Jupyter REPL with `SPC m s j`

3. The REPL uses the kernel matching your active environment

### Specifying Kernel Explicitly

```elisp
;; When calling jupyter-run-repl interactively, you can specify kernel:
;; M-x jupyter-run-repl RET python3 RET

;; Or configure default:
(setq jupyter-repl-default-kernel "python3")
```

### Ensuring Kernel Availability

```bash
# List available kernels
jupyter kernelspec list

# Install kernel for current environment
python -m ipykernel install --user --name myenv --display-name "Python (myenv)"
```

---

## 7. Draft Layer Structure

### File: ~/.emacs.d/private/jupyter-repl/packages.el

```elisp
;;; packages.el --- jupyter-repl Layer packages File for Spacemacs
;;
;; Copyright (c) 2012-2025 Sylvain Benner & Contributors
;;
;; Author: Your Name <your.email@example.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


(defconst jupyter-repl-packages
  '(
    jupyter
    company
    python
    ))

(defun jupyter-repl/init-jupyter ()
  (use-package jupyter
    :defer t
    :commands (jupyter-run-repl
               jupyter-connect-repl
               jupyter-repl-associate-buffer)
    :init
    ;; Global keybindings for starting REPL
    (spacemacs/declare-prefix "aj" "jupyter")
    (spacemacs/set-leader-keys
      "ajr" 'jupyter-run-repl
      "ajc" 'jupyter-connect-repl)

    :config
    ;; Configure jupyter settings
    (setq jupyter-repl-echo-eval-p jupyter-repl-echo-eval-p-config
          jupyter-eval-use-overlays jupyter-repl-use-overlays-config
          jupyter-repl-maximum-size jupyter-repl-maximum-size-config)

    ;; REPL buffer keybindings
    (with-eval-after-load 'jupyter-repl
      (spacemacs/set-leader-keys-for-major-mode 'jupyter-repl-mode
        "c" 'jupyter-repl-clear-cells
        "i" 'jupyter-repl-interrupt-kernel
        "r" 'jupyter-repl-restart-kernel
        "q" 'quit-window)

      ;; Vim-style history navigation
      (when (eq dotspacemacs-editing-style 'vim)
        (define-key jupyter-repl-mode-map (kbd "C-j") 'jupyter-repl-history-next)
        (define-key jupyter-repl-mode-map (kbd "C-k") 'jupyter-repl-history-previous)
        (define-key jupyter-repl-mode-map (kbd "C-l") 'jupyter-repl-clear-cells)))))

(defun jupyter-repl/post-init-company ()
  ;; Company completion in jupyter-repl-mode is built-in via completion-at-point
  ;; No additional configuration needed - jupyter uses capf
  (spacemacs|add-company-backends
    :backends company-capf
    :modes jupyter-repl-mode
    :append-hooks nil
    :call-hooks t))

(defun jupyter-repl/post-init-python ()
  ;; Add jupyter REPL keybindings to python-mode
  (spacemacs/declare-prefix-for-mode 'python-mode "msj" "jupyter")

  (spacemacs/set-leader-keys-for-major-mode 'python-mode
    ;; Start/manage REPL
    "sj" 'spacemacs/jupyter-repl-start
    "sJ" 'jupyter-repl-restart-kernel
    "sq" 'jupyter-repl-pop-to-buffer

    ;; Send code (when using jupyter backend)
    ;; These override default python bindings when jupyter is active
    )

  ;; Override standard REPL start if jupyter is default
  (when (eq jupyter-repl-default-repl 'jupyter)
    (spacemacs/set-leader-keys-for-major-mode 'python-mode
      "'" 'spacemacs/jupyter-repl-start
      "si" 'spacemacs/jupyter-repl-start))

  ;; Associate python buffers with jupyter REPL for completion
  (add-hook 'python-mode-hook
            (lambda ()
              (when (and (eq jupyter-repl-default-repl 'jupyter)
                         (featurep 'jupyter))
                ;; Enable jupyter-repl-interaction-mode when connected
                (add-hook 'jupyter-repl-interaction-mode-hook
                          #'spacemacs//jupyter-setup-bindings nil t)))))
```

### File: ~/.emacs.d/private/jupyter-repl/funcs.el

```elisp
;;; funcs.el --- jupyter-repl Layer functions File for Spacemacs
;;
;; Copyright (c) 2012-2025 Sylvain Benner & Contributors
;;
;; Author: Your Name <your.email@example.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.


(defun spacemacs/jupyter-repl-start ()
  "Start or switch to a Jupyter REPL for the current buffer."
  (interactive)
  (require 'jupyter)
  (if-let ((client (jupyter-repl-client)))
      (progn
        (pop-to-buffer (jupyter-repl-buffer client))
        (when (eq dotspacemacs-editing-style 'vim)
          (evil-insert-state)))
    ;; No client, start new REPL
    (call-interactively 'jupyter-run-repl)
    (when (eq dotspacemacs-editing-style 'vim)
      (evil-insert-state))))

(defun spacemacs/jupyter-send-buffer ()
  "Send buffer to Jupyter REPL."
  (interactive)
  (jupyter-eval-buffer))

(defun spacemacs/jupyter-send-buffer-switch ()
  "Send buffer to Jupyter REPL and switch to it."
  (interactive)
  (jupyter-eval-buffer)
  (jupyter-repl-pop-to-buffer)
  (when (eq dotspacemacs-editing-style 'vim)
    (evil-insert-state)))

(defun spacemacs/jupyter-send-defun ()
  "Send current function to Jupyter REPL."
  (interactive)
  (jupyter-eval-defun))

(defun spacemacs/jupyter-send-defun-switch ()
  "Send current function and switch to REPL."
  (interactive)
  (jupyter-eval-defun)
  (jupyter-repl-pop-to-buffer)
  (when (eq dotspacemacs-editing-style 'vim)
    (evil-insert-state)))

(defun spacemacs/jupyter-send-region (start end)
  "Send region to Jupyter REPL."
  (interactive "r")
  (jupyter-eval-region start end))

(defun spacemacs/jupyter-send-region-switch (start end)
  "Send region and switch to REPL."
  (interactive "r")
  (jupyter-eval-region start end)
  (jupyter-repl-pop-to-buffer)
  (when (eq dotspacemacs-editing-style 'vim)
    (evil-insert-state)))

(defun spacemacs/jupyter-send-line ()
  "Send current line to Jupyter REPL."
  (interactive)
  (jupyter-eval-line-or-region))

(defun spacemacs/jupyter-send-line-switch ()
  "Send current line and switch to REPL."
  (interactive)
  (jupyter-eval-line-or-region)
  (jupyter-repl-pop-to-buffer)
  (when (eq dotspacemacs-editing-style 'vim)
    (evil-insert-state)))

(defun spacemacs/jupyter-send-line-or-region ()
  "Send line or active region to Jupyter REPL."
  (interactive)
  (if (use-region-p)
      (jupyter-eval-region (region-beginning) (region-end))
    (jupyter-eval-line-or-region)))

(defun spacemacs//jupyter-setup-bindings ()
  "Setup keybindings for jupyter-repl-interaction-mode."
  ;; These are active when buffer is associated with a REPL
  (spacemacs/set-leader-keys-for-minor-mode 'jupyter-repl-interaction-mode
    "sb" 'spacemacs/jupyter-send-buffer
    "sB" 'spacemacs/jupyter-send-buffer-switch
    "sf" 'spacemacs/jupyter-send-defun
    "sF" 'spacemacs/jupyter-send-defun-switch
    "sr" 'spacemacs/jupyter-send-region
    "sR" 'spacemacs/jupyter-send-region-switch
    "sl" 'spacemacs/jupyter-send-line
    "sL" 'spacemacs/jupyter-send-line-switch
    "ss" 'spacemacs/jupyter-send-line-or-region))
```

### File: ~/.emacs.d/private/jupyter-repl/config.el

```elisp
;;; config.el --- jupyter-repl Layer configuration File for Spacemacs
;;
;; Copyright (c) 2012-2025 Sylvain Benner & Contributors
;;
;; Author: Your Name <your.email@example.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.


;; Layer variables (user-configurable)

(defvar jupyter-repl-default-repl 'jupyter
  "Default REPL backend for Python.
Possible values are `jupyter' (use emacs-jupyter) or
`inferior-python' (use standard python.el REPL).
Default is `jupyter'.")

(defvar jupyter-repl-echo-eval-p-config nil
  "If non-nil, show evaluated code in REPL buffer.
Maps to `jupyter-repl-echo-eval-p'.")

(defvar jupyter-repl-use-overlays-config t
  "If non-nil, display short results as overlays in source buffer.
Maps to `jupyter-eval-use-overlays'.")

(defvar jupyter-repl-maximum-size-config 10000
  "Maximum number of lines in REPL buffer before truncation.
Maps to `jupyter-repl-maximum-size'.")

(defvar jupyter-repl-default-kernel "python3"
  "Default kernel to use when starting a REPL.
Set to nil to prompt every time.")

;; Mark variables as safe for .dir-locals.el
(put 'jupyter-repl-default-repl 'safe-local-variable #'symbolp)
```

---

## 8. Troubleshooting

### emacs-zmq Fails to Compile

**Symptom**: Error during first startup about zmq module.

**Solution**:

```bash
# macOS
xcode-select --install  # Ensure command line tools

# Linux
sudo apt-get install libzmq3-dev autoconf automake libtool pkg-config
```

### Kernel Not Found

**Symptom**: "No kernel matching..." error.

**Solution**:

```bash
# Install kernel for your Python
python -m ipykernel install --user --name python3

# Verify
jupyter kernelspec list
```

### Completion Not Working

**Symptom**: No completions in Jupyter REPL.

**Check**:

1. Verify `company-mode` is active: `M-x company-mode`
2. Check completion backend: `M-x company-diag`
3. Verify kernel is running: Check `*jupyter-kernel-<name>*` buffer

### macOS Catalina+ Issues

**Symptom**: `process-live-p` errors or hangs.

**Potential fixes**:

1. Rebuild emacs-zmq:
   ```elisp
   (delete-file (locate-library "emacs-zmq"))
   ;; Restart Emacs, will recompile
   ```

2. Enable debug logging:
   ```elisp
   (setq jupyter--debug t)
   ```

3. Check `*Messages*` buffer for detailed errors.

### REPL Hangs on Startup

**Symptom**: "Starting kernel..." never completes.

**Check**:

```bash
# Test jupyter directly
jupyter console --kernel python3

# Check for port conflicts
lsof -i :8888
```

---

## 9. Open Questions / Needs Clarification

### Features - Need User Input

1. **Keybinding Override Strategy**: Should jupyter bindings completely override python-mode REPL bindings when `jupyter-repl-default-repl` is `'jupyter`, or should they coexist under different prefixes (e.g., `SPC m s j` for jupyter, `SPC m s p` for python)?

2. **Auto-Associate Behavior**: Should python buffers automatically associate with an existing jupyter REPL (via `jupyter-repl-associate-buffer`) when opened? This enables completion in source buffers but creates implicit state.

3. **Multiple Kernel Support**: Should the layer support starting multiple kernels (e.g., for different virtualenvs)? How should buffer-kernel associations be managed?

4. **Org-Babel Integration**: Should this layer configure `org-babel-load-languages` to include `(jupyter . t)` automatically, or leave that to user configuration?

### Potential Conflicts

1. **ipython-notebook Layer**: These layers should not be used together. Should we add explicit conflict detection?

2. **code-cells Package**: The python layer enables `code-cells-mode` when ipython-notebook is not used. Should jupyter-repl layer override the cell evaluation commands?

3. **LSP Completion**: When using python LSP backend, both LSP and jupyter provide completion. Need to determine priority or disable overlap.

### OS-Specific Concerns

1. **macOS Sequoia Compatibility**: Recent macOS versions have shown kernel startup issues. Need to document specific workarounds.

2. **Linux ARM64**: emacs-zmq compilation on ARM Linux (e.g., Raspberry Pi) is untested.

3. **Windows/WSL**: This runbook assumes macOS/Linux. WSL support needs investigation.

### Version Compatibility

1. **Minimum Jupyter Version**: What is the minimum jupyter/ipykernel version that works reliably with emacs-jupyter?

2. **Python 3.12+ Compatibility**: Has emacs-jupyter been tested with Python 3.12+?

3. **Emacs 29 vs 30**: This targets Emacs 30.1, but should we support Emacs 29?

### Future Expansion

1. **Other Languages**: emacs-jupyter supports any Jupyter kernel. Should this layer be generalized to support Julia, R, Clojure, etc.?

2. **Remote Kernels**: Should we document connecting to remote Jupyter servers (requires SSH key auth)?

3. **Kernel Management UI**: Should we add a hydra/transient for kernel management (list, start, stop, restart)?

---

## 10. Function Mapping: inferior-python → jupyter

### Core REPL Bindings

| Spacemacs Binding | Current Function | Jupyter Equivalent | Notes |
|-------------------|------------------|-------------------|-------|
| `, '` / `, s i` | `spacemacs/python-start-or-switch-repl` | `jupyter-run-repl` + `jupyter-repl-pop-to-buffer` | Needs wrapper |
| `, s b` | `spacemacs/python-shell-send-buffer` | `jupyter-eval-buffer` | Direct |
| `, s B` | `spacemacs/python-shell-send-buffer-switch` | `jupyter-eval-buffer` + `jupyter-repl-pop-to-buffer` | Needs wrapper |
| `, s f` | `spacemacs/python-shell-send-defun` | `jupyter-eval-defun` | Direct |
| `, s F` | `spacemacs/python-shell-send-defun-switch` | `jupyter-eval-defun` + pop | Needs wrapper |
| `, s r` | `spacemacs/python-shell-send-region` | `jupyter-eval-line-or-region` | Direct |
| `, s R` | `spacemacs/python-shell-send-region-switch` | + pop | Needs wrapper |
| `, s l` | `spacemacs/python-shell-send-line` | `jupyter-eval-line-or-region` | Direct |
| `, s L` | `spacemacs/python-shell-send-line-switch` | + pop | Needs wrapper |
| `, s s` | `spacemacs/python-shell-send-with-output` | `jupyter-eval-line-or-region` | Direct |
| `, s n` | `spacemacs/python-shell-restart` | `jupyter-repl-restart-kernel` | Direct |
| `, s e` | `spacemacs/python-shell-send-statement` | N/A | Use line-or-region |
| `, s k` | `spacemacs/python-shell-send-block` | N/A | Use defun or region |

### Additional Jupyter Functions (New Bindings)

| Proposed Binding | Jupyter Function | Description |
|-----------------|------------------|-------------|
| `, s k` | `jupyter-repl-interrupt-kernel` | Interrupt running code (Ctrl+C equivalent) |
| `, s c` | `jupyter-repl-clear-cells` | Clear REPL output |
| `, s q` | `jupyter-repl-pop-to-buffer` | Jump to REPL buffer |

### emacs-jupyter Interactive Functions Reference

**Starting/Managing REPL:**
- `jupyter-run-repl` - Start a new REPL with specified kernel
- `jupyter-connect-repl` - Connect to existing kernel via connection file
- `jupyter-repl-associate-buffer` - Associate current buffer with a REPL client

**Code Execution:**
- `jupyter-eval-line-or-region` - Execute current line or selected region
- `jupyter-eval-buffer` - Execute entire buffer
- `jupyter-eval-defun` - Execute function/definition at point
- `jupyter-load-file` - Load/execute a file

**Kernel Control:**
- `jupyter-repl-restart-kernel` - Restart the kernel
- `jupyter-repl-interrupt-kernel` - Interrupt/stop kernel execution
- `jupyter-repl-shutdown-kernel` - Shutdown kernel

**Buffer Operations:**
- `jupyter-repl-clear-cells` - Clear all input/output cells
- `jupyter-repl-pop-to-buffer` - Switch to REPL buffer

**History Navigation:**
- `jupyter-repl-history-next` - Navigate to next history item
- `jupyter-repl-history-previous` - Navigate to previous history item

### Default emacs-jupyter Keybindings (for reference)

In `jupyter-repl-mode`:
- `RET` → `jupyter-repl-ret`
- `M-n` → `jupyter-repl-history-next`
- `M-p` → `jupyter-repl-history-previous`
- `C-c C-o` → `jupyter-repl-clear-cells`

In `jupyter-repl-interaction-mode`:
- `C-c C-c` → `jupyter-eval-line-or-region`
- `C-M-x` → `jupyter-eval-defun`
- `C-c C-b` → `jupyter-eval-buffer`
- `C-c C-r` → `jupyter-repl-restart-kernel`
- `C-c C-i` → `jupyter-repl-interrupt-kernel`
- `C-c C-z` → `jupyter-repl-pop-to-buffer`

---

## 11. Files to Modify in Python Layer

### config.el

Add new variable:
```elisp
(defvar python-repl-backend 'inferior-python
  "The backend to use for Python REPL.
Possible values are `inferior-python' (default) and `jupyter'.
When set to `jupyter', requires the jupyter package and a working
Jupyter installation with ipykernel.")
(put 'python-repl-backend 'safe-local-variable #'symbolp)
```

### packages.el

1. Add `jupyter` to package list with toggle:
```elisp
(jupyter :toggle (eq python-repl-backend 'jupyter))
```

2. Add init function for jupyter package

3. Modify `python/init-python` to dispatch based on `python-repl-backend`

### funcs.el

Add dispatch wrapper functions that check `python-repl-backend`:
```elisp
(defun spacemacs/python-start-or-switch-repl ()
  "Start and/or switch to the REPL based on python-repl-backend."
  (interactive)
  (pcase python-repl-backend
    ('jupyter (spacemacs//python-jupyter-start-or-switch-repl))
    (_ (spacemacs//python-inferior-start-or-switch-repl))))
```

Add jupyter-specific implementations:
- `spacemacs//python-jupyter-start-or-switch-repl`
- `spacemacs//python-jupyter-send-buffer`
- `spacemacs//python-jupyter-send-buffer-switch`
- etc.

---

## 12. Implementation Strategy

### Phase 1: Add jupyter package and variable
- Add `python-repl-backend` variable to config.el
- Add `jupyter` package to packages.el with proper toggle
- Basic init function

### Phase 2: Create dispatch layer
- Rename existing REPL functions to `spacemacs//python-inferior-*`
- Create new dispatch functions `spacemacs/python-*` that check backend
- Create `spacemacs//python-jupyter-*` equivalents

### Phase 3: Keybindings
- Keybindings remain the same (`, s i`, `, s b`, etc.)
- They call the dispatch functions which route to correct backend

### Phase 4: Org-babel integration
- Add `(jupyter . t)` to org-babel-load-languages (like Python layer does for python)

### Phase 5: Testing
- Test on macOS (primary target for fixing completion)
- Test on Linux
- Test backend switching via .dir-locals.el

---

## References

- [emacs-jupyter GitHub](https://github.com/emacs-jupyter/jupyter)
- [emacs-jupyter README](https://github.com/emacs-jupyter/jupyter/blob/master/README.org)
- [Spacemacs Python Layer](https://www.spacemacs.org/layers/+lang/python/README.html)
- [Spacemacs Layer Development](https://www.spacemacs.org/doc/LAYERS.html)
- [Spacemacs Conventions](https://github.com/syl20bnr/spacemacs/blob/develop/doc/CONVENTIONS.org)
- [Archived: spacemacs-jupyter](https://github.com/benneti/spacemacs-jupyter) (reference implementation)

---

## 13. Implementation Review and Questions

*Review conducted: 2025-12-22*

### 1. Gaps Identified

#### 1.1 Missing REPL Functions in Mapping (Section 10)

The function mapping in Section 10 is missing several functions from `funcs.el`:

| Function | Line | Status |
|----------|------|--------|
| `spacemacs/python-shell-send-block` | 551 | **Missing** - no jupyter equivalent listed |
| `spacemacs/python-shell-send-block-switch` | 572 | **Missing** - no jupyter equivalent listed |
| `spacemacs/python-shell-send-statement` | 629 | Listed as N/A but may need jupyter handling |
| `spacemacs/python-shell-send-statement-switch` | 635 | **Missing** |
| `spacemacs/python-shell-restart-switch` | 671 | **Missing** - listed `sn` but not `sN` |
| `spacemacs/python-shell-send-with-output` | 642 | Listed but behavior differs (comint vs jupyter) |

**Note**: The block-sending functions (`sk`, `sK`) use `python-nav-beginning-of-block` and `python-nav-end-of-block` which are Python-mode specific. Jupyter has no direct equivalent; closest is `jupyter-eval-defun` or manual region selection.

#### 1.2 Missing Keybindings in Plan

Current `packages.el` (lines 406-427) defines these bindings that need jupyter equivalents:

```elisp
"sB" 'spacemacs/python-shell-send-buffer-switch  ; Covered
"sb" 'spacemacs/python-shell-send-buffer          ; Covered
"sE" 'spacemacs/python-shell-send-statement-switch ; NOT covered
"se" 'spacemacs/python-shell-send-statement        ; Listed as N/A
"sF" 'spacemacs/python-shell-send-defun-switch     ; Covered
"sf" 'spacemacs/python-shell-send-defun            ; Covered
"sK" 'spacemacs/python-shell-send-block-switch     ; NOT covered
"sk" 'spacemacs/python-shell-send-block            ; NOT covered
"sn" 'spacemacs/python-shell-restart               ; Covered
"sN" 'spacemacs/python-shell-restart-switch        ; NOT covered
```

#### 1.3 Variable Naming Inconsistency

The runbook proposes `python-repl-backend` (Section 11, line 703), but the draft layer code (Section 7) uses `jupyter-repl-default-repl`. These need to be unified. Recommendation: Use `python-repl-backend` since we're modifying the Python layer.

#### 1.4 Missing `jupyter-current-client` Usage

The draft `spacemacs/jupyter-repl-start` function (Section 7, line 377) uses `jupyter-repl-client` which doesn't exist. The correct variable is `jupyter-current-client`:

```elisp
;; Wrong (line 377):
(if-let ((client (jupyter-repl-client)))

;; Correct:
(if-let ((client (bound-and-true-p jupyter-current-client)))
```

#### 1.5 Missing Package Toggle in Phase 1

Section 12 Phase 1 says "Add `jupyter` package to packages.el with proper toggle" but doesn't specify the toggle condition. Should be:

```elisp
(jupyter :toggle (eq python-repl-backend 'jupyter))
```

---

### 2. Potential Issues

#### 2.1 Jupyter Package Not Installed

**Issue**: If `python-repl-backend` is `'jupyter` but:
- The `jupyter` Emacs package isn't installed (toggle ensures this)
- OR jupyter/ipykernel isn't installed on the system

**Current handling**: None specified.

**Recommendation**: Add validation in `spacemacs//python-jupyter-start-or-switch-repl`:

```elisp
(defun spacemacs//python-jupyter-start-or-switch-repl ()
  (unless (featurep 'jupyter)
    (user-error "Jupyter package not loaded. Check python-repl-backend setting."))
  (unless (executable-find "jupyter")
    (user-error "jupyter not found in PATH. Install with: pip install jupyter ipykernel"))
  ;; ... rest of function
  )
```

#### 2.2 Conda/Virtualenv Kernel Selection

**Issue**: emacs-jupyter caches kernelspecs at startup. Switching virtualenvs won't automatically update the available kernels.

**Source**: [emacs-jupyter issue #93](https://github.com/dzop/emacs-jupyter/issues/93)

**Impact**: User activates conda env, starts jupyter REPL, gets wrong kernel.

**Recommendation**: Add advice to virtualenv activation functions:

```elisp
(defun spacemacs//refresh-jupyter-kernelspecs ()
  "Refresh jupyter kernelspecs after environment change."
  (when (and (eq python-repl-backend 'jupyter)
             (featurep 'jupyter))
    (jupyter-available-kernelspecs t)))  ; t forces refresh

(dolist (func '(pyvenv-activate pyvenv-deactivate pyvenv-workon
                pyenv-mode-set pyenv-mode-unset
                pipenv-activate pipenv-deactivate
                poetry-venv-workon poetry-venv-deactivate))
  (advice-add func :after #'spacemacs//refresh-jupyter-kernelspecs))
```

#### 2.3 Company-Mode Setup Conflict

**Issue**: `packages.el` line 106-108 sets up company for `inferior-python-mode`:

```elisp
(spacemacs|add-company-backends
  :backends (company-files company-capf)
  :modes inferior-python-mode)
```

When using jupyter backend, the REPL buffer is `jupyter-repl-mode`, not `inferior-python-mode`. This existing setup won't affect jupyter, but:
- Need equivalent setup for `jupyter-repl-mode`
- Jupyter uses `completion-at-point` (capf), so `company-capf` should work

**Recommendation**: Add to `python/init-jupyter`:

```elisp
(spacemacs|add-company-backends
  :backends company-capf
  :modes jupyter-repl-mode)
```

#### 2.4 Keybinding Conflicts in REPL Buffer

**Issue**: `packages.el` lines 437-455 set up vim-style keybindings for `inferior-python-mode-map`:
- `C-j` -> `comint-next-input`
- `C-k` -> `comint-previous-input`
- `C-r` -> `comint-history-isearch-backward`
- `C-l` -> `spacemacs/comint-clear-buffer`

`jupyter-repl-mode` has its own history navigation (`M-n`, `M-p`). Need to ensure consistent UX.

**Recommendation**: Add equivalent vim-style bindings for `jupyter-repl-mode-map` (already done in draft Section 7 lines 316-319, but missing `C-r` for history search).

#### 2.5 Code-Cells Package Interaction

**Issue**: `packages.el` line 27 enables `code-cells` when ipython-notebook is not used:

```elisp
(code-cells :toggle (not (configuration-layer/layer-used-p 'ipython-notebook)))
```

`code-cells-mode` provides `code-cells-eval` (bound to `sc`) and `code-cells-eval-above` (`sa`). When using jupyter backend:
- Should `code-cells-eval` use jupyter instead of inferior-python?
- Current: `code-cells-eval` calls `python-shell-send-region`

**Recommendation**: Leave as-is initially. Code-cells is for notebook-style cell evaluation in .py files; it can work independently. Document that `sc`/`sa` always use inferior-python regardless of `python-repl-backend`. Users wanting jupyter cell execution should use region/buffer commands.

#### 2.6 DAP Mode Interaction

**Issue**: `packages.el` line 136-139:

```elisp
(defun python/pre-init-dap-mode ()
  (when (eq python-backend 'lsp)
    (add-to-list 'spacemacs--dap-supported-modes 'python-mode))
  (add-hook 'python-mode-local-vars-hook #'spacemacs//python-setup-dap))
```

DAP (Debug Adapter Protocol) is separate from REPL. No conflict expected.

**Confirmation needed**: Does jupyter-mode interfere with DAP debugging? They should be orthogonal.

#### 2.7 Window-Purpose Configuration

**Issue**: `packages.el` lines 512-521 configures window-purpose:

```elisp
:mode-purposes '((inferior-python-mode . repl))
```

When using jupyter, the REPL is `jupyter-repl-mode`, not `inferior-python-mode`.

**Recommendation**: Add jupyter-repl-mode to purpose configuration:

```elisp
:mode-purposes '((inferior-python-mode . repl)
                 (jupyter-repl-mode . repl))
```

#### 2.8 `spacemacs/register-repl` Call

**Issue**: `packages.el` line 385-386:

```elisp
(spacemacs/register-repl 'python
                         'spacemacs/python-start-or-switch-repl "python")
```

This registers the REPL for `SPC a '` (application REPL menu). Should work with dispatch pattern since `spacemacs/python-start-or-switch-repl` will be the dispatch function.

**Confirmation needed**: Verify this still works after refactoring.

---

### 3. Questions for User

#### 3.1 Block Evaluation Strategy

The current layer has `sk` (send-block) and `sK` (send-block-switch) which use Python's AST-aware block detection. Jupyter has no equivalent.

**DECISION**: Implement proper block detection using Python-mode navigation functions, then send via `jupyter-eval-region`:

```elisp
(defun spacemacs//python-jupyter-send-block ()
  "Send current block to Jupyter REPL using Python's block detection."
  (interactive)
  (let ((beg (save-excursion
               (python-nav-beginning-of-block)
               (point)))
        (end (save-excursion
               (python-nav-end-of-block)
               (point))))
    (jupyter-eval-region beg end)))

(defun spacemacs//python-jupyter-send-block-switch ()
  "Send current block to Jupyter REPL and switch to it."
  (interactive)
  (spacemacs//python-jupyter-send-block)
  (jupyter-repl-pop-to-buffer)
  (evil-insert-state))
```

This maintains feature parity with inferior-python by reusing Python-mode's AST-aware block detection.

#### 3.2 Statement Evaluation (`se`, `sE`)

`spacemacs/python-shell-send-statement` uses `python-shell-send-statement` which sends the current statement (can span multiple lines).

**DECISION**: Implement using `python-nav-beginning-of-statement` and `python-nav-end-of-statement` to determine region, then send via `jupyter-eval-region`.

#### 3.3 Automatic Buffer Association

When a jupyter REPL is started, should all python-mode buffers automatically associate with it?

**DECISION**: No. Do not interfere with python buffers. User has LSP/pyright for source completion.

#### 3.4 Multiple Kernel Support

If user has multiple virtualenvs active (e.g., different projects), how should kernel selection work?

**DECISION**: One global REPL (same as current inferior-python behavior). Match existing pattern.

#### 3.5 Org-Babel Integration Priority

Phase 4 mentions adding `(jupyter . t)` to org-babel-load-languages.

**DECISION**: Not required for MVP. Defer to later.

#### 3.6 IPython-Notebook Layer Conflict Detection

**DECISION**: No detection needed. Different packages (EIN vs emacs-jupyter), different file types (.ipynb vs .py). Can coexist.

#### 3.7 Kernel Selection Behavior

When user runs `, s i` with jupyter backend, should it prompt for kernel?

**DECISION**: Do NOT prompt. Auto-select kernel like inferior-python auto-selects ipython/python. Use `python3` kernel by default, or detect from active conda/pyenv environment if possible.

#### 3.8 Graceful Degradation

If `python-repl-backend` is `'jupyter` but jupyter isn't installed:

**DECISION**: Both - warn user with helpful message AND fall back to `'inferior-python`.

#### 3.9 REPL Buffer Vim Keybindings

Mirror the current inferior-python-mode bindings exactly. From packages.el:437-455:

| Key | inferior-python-mode | jupyter-repl-mode equivalent |
|-----|---------------------|------------------------------|
| `C-j` | `comint-next-input` | `jupyter-repl-history-next` |
| `C-k` | `comint-previous-input` | `jupyter-repl-history-previous` |
| `C-r` | `comint-history-isearch-backward` | Need to verify jupyter equivalent |
| `C-l` | `spacemacs/comint-clear-buffer` | `jupyter-repl-clear-cells` |
| `C-c M-l` | `spacemacs/comint-clear-buffer` | `jupyter-repl-clear-cells` |

**DECISION**: Add all vim-style keybindings to jupyter-repl-mode-map for consistency.

#### 3.10 Send-Line-Switch Function

**Issue**: The current Python layer has `sl` (send-line) but NO `sL` (send-line-switch). This is inconsistent with other send functions that have switch variants (`sb`/`sB`, `sf`/`sF`, `sr`/`sR`).

**DECISION**: Create `spacemacs/python-shell-send-line-switch` for BOTH backends:

```elisp
;; Add to funcs.el - new function for inferior-python
(defun spacemacs//python-inferior-send-line-switch ()
  "Send current line to Python shell and switch to it."
  (interactive)
  (spacemacs//python-inferior-send-line)
  (python-shell-switch-to-shell)
  (evil-insert-state))

;; Jupyter equivalent
(defun spacemacs//python-jupyter-send-line-switch ()
  "Send current line to Jupyter REPL and switch to it."
  (interactive)
  (spacemacs//python-jupyter-send-line)
  (jupyter-repl-pop-to-buffer)
  (evil-insert-state))

;; Dispatch wrapper
(defun spacemacs/python-shell-send-line-switch ()
  "Send current line to REPL and switch."
  (interactive)
  (pcase python-repl-backend
    ('jupyter (spacemacs//python-jupyter-send-line-switch))
    (_ (spacemacs//python-inferior-send-line-switch))))
```

**Keybinding**: Add `sL` to `spacemacs/python-shell-send-line-switch` in packages.el (line 426):

```elisp
"sl" 'spacemacs/python-shell-send-line
"sL" 'spacemacs/python-shell-send-line-switch  ;; NEW
```

---

### 4. Recommendations

#### 4.1 Phasing Adjustments

**Current Phase 2** (Create dispatch layer):
- "Rename existing REPL functions to `spacemacs//python-inferior-*`"

**Problem**: This is a breaking change. Existing user configs may call `spacemacs/python-shell-send-buffer` directly.

**Recommendation**: Keep existing function names as dispatch wrappers. Create internal `spacemacs//python-inferior-*` AND `spacemacs//python-jupyter-*` implementations:

```elisp
;; Public API (unchanged names, now dispatches)
(defun spacemacs/python-shell-send-buffer ()
  (interactive)
  (pcase python-repl-backend
    ('jupyter (spacemacs//python-jupyter-send-buffer))
    (_ (spacemacs//python-inferior-send-buffer))))

;; Internal: inferior-python implementation
(defun spacemacs//python-inferior-send-buffer ()
  (let ((python-mode-hook nil))
    (python-shell-send-buffer)))

;; Internal: jupyter implementation
(defun spacemacs//python-jupyter-send-buffer ()
  (jupyter-eval-buffer))
```

#### 4.2 Add Graceful Degradation

If jupyter isn't available but `python-repl-backend` is `'jupyter`, fall back to `'inferior-python` with a warning:

```elisp
(defun spacemacs//python-ensure-repl-backend ()
  "Ensure python-repl-backend is valid, fall back if needed."
  (when (and (eq python-repl-backend 'jupyter)
             (not (featurep 'jupyter)))
    (message "Warning: jupyter package not available, falling back to inferior-python")
    (setq-local python-repl-backend 'inferior-python)))
```

#### 4.3 Add Kernel Refresh Hook

As noted in 2.2, add automatic kernelspec refresh when virtualenv changes.

#### 4.4 Add `python-jupyter-default-kernel` Variable

Allow users to specify default kernel name:

```elisp
(defvar python-jupyter-default-kernel nil
  "Default kernel name for jupyter REPL.
If nil, prompt for kernel selection.
Example: \"python3\", \"conda-myenv\".")
```

#### 4.5 Update window-purpose Configuration

Add `jupyter-repl-mode` alongside `inferior-python-mode` in purpose configuration.

#### 4.6 Document Limitations

Add a "Known Limitations" section documenting:
- Block evaluation (`sk`) uses defun in jupyter mode
- Statement evaluation (`se`) uses line-or-region in jupyter mode
- Kernel must be refreshed after env switch (or use provided helper)
- code-cells always uses inferior-python

---

### 5. Implementation Checklist Update

Based on this review, the implementation phases should be:

**Phase 0: Preparation**
- [ ] Add `python-repl-backend` variable to `config.el`
- [ ] Add `python-jupyter-default-kernel` variable to `config.el`
- [ ] Add `jupyter` package to `packages.el` with toggle

**Phase 1: Core Infrastructure**
- [ ] Create `spacemacs//python-ensure-repl-backend` validation function
- [ ] Create `spacemacs//refresh-jupyter-kernelspecs` function
- [ ] Add kernelspec refresh advice to virtualenv functions

**Phase 2: Dispatch Functions**
- [ ] Convert `spacemacs/python-start-or-switch-repl` to dispatch
- [ ] Convert `spacemacs/python-shell-send-buffer` to dispatch
- [ ] Convert `spacemacs/python-shell-send-buffer-switch` to dispatch
- [ ] Convert `spacemacs/python-shell-send-defun` to dispatch
- [ ] Convert `spacemacs/python-shell-send-defun-switch` to dispatch
- [ ] Convert `spacemacs/python-shell-send-region` to dispatch
- [ ] Convert `spacemacs/python-shell-send-region-switch` to dispatch
- [ ] Convert `spacemacs/python-shell-send-line` to dispatch
- [ ] Create `spacemacs/python-shell-send-line-switch` (NEW - both backends)
- [ ] Add `sL` keybinding for send-line-switch
- [ ] Convert `spacemacs/python-shell-restart` to dispatch
- [ ] Convert `spacemacs/python-shell-restart-switch` to dispatch
- [ ] Convert `spacemacs/python-shell-send-block` to dispatch (using python-nav block detection)
- [ ] Convert `spacemacs/python-shell-send-block-switch` to dispatch
- [ ] Convert `spacemacs/python-shell-send-statement` to dispatch
- [ ] Convert `spacemacs/python-shell-send-statement-switch` to dispatch

**Phase 3: Jupyter Init Function**
- [ ] Create `python/init-jupyter` in `packages.el`
- [ ] Add company-capf for jupyter-repl-mode
- [ ] Add vim-style keybindings for jupyter-repl-mode
- [ ] Add window-purpose configuration for jupyter-repl-mode

**Phase 4: Testing**
- [ ] Test on macOS (primary target)
- [ ] Test on Linux
- [ ] Test inferior-python still works (no regression)
- [ ] Test backend switching via `.dir-locals.el`
- [ ] Test virtualenv activation + kernel refresh
- [ ] Test with LSP backend enabled
- [ ] Test with DAP mode

**Phase 5: Documentation**
- [ ] Update README.org for Python layer
- [ ] Document `python-repl-backend` variable
- [ ] Document limitations and workarounds

---

## 14. Hardening Review (2025-12-22)

### Critical Issues Resolved

| # | Issue | Resolution |
|---|-------|------------|
| 1 | `spacemacs/python-shell-send-line-switch` missing | Create for both backends (Section 3.10) |
| 2 | `jupyter-repl-client()` not a real API | Use `(bound-and-true-p jupyter-current-client)` |
| 3 | Variable naming inconsistency | Use `python-repl-backend` throughout (integration approach) |
| 4 | Block evaluation no direct jupyter equivalent | Use python-nav block detection + `jupyter-eval-region` (Section 3.1) |
| 5 | `sL` keybinding doesn't exist | Add to packages.el alongside `sl` |
| 6 | window-purpose missing jupyter-repl-mode | Add to purpose config (Section 2.7) |
| 7 | Company-mode needs jupyter-repl-mode setup | Add in `python/init-jupyter` (Section 2.3) |

### API Corrections

```elisp
;; WRONG - function doesn't exist:
(if-let ((client (jupyter-repl-client)))

;; CORRECT - check variable:
(if-let ((client (bound-and-true-p jupyter-current-client)))
```

### Confirmed Architecture

- **Approach**: Modify existing Python layer (NOT create private layer)
- **Variable**: `python-repl-backend` in `config.el` with values `'inferior-python` (default) or `'jupyter`
- **Pattern**: Dispatch wrappers that route to `spacemacs//python-inferior-*` or `spacemacs//python-jupyter-*`

### Warnings to Address During Implementation

1. **Virtualenv kernel refresh**: Add advice to pyvenv/pyenv activation functions
2. **Emacs module support**: Verify Emacs 30.1 built with `--with-modules`
3. **code-cells**: Always uses inferior-python (documented limitation)
4. **History search**: Verify `C-r` equivalent in jupyter-repl-mode

---

---

## 15. Debugging Session (2025-12-22)

### Attempted Fixes

| Fix | Result |
|-----|--------|
| `pip install gnureadline` | Installed successfully, no effect |
| Verify company-mode active | Yes, active in inferior-python-mode |
| Verify company-backends | `company-capf` is configured correctly |

### Diagnostic Findings

**`M-x company-diag` output revealed:**
```
Current c-a-p-f: comint-completion-at-point   <-- PROBLEM
```

- `python-shell-completion-at-point` is in the list but returns nil
- Falls back to `comint-completion-at-point` (file completion)
- Completions show filenames (`solutions_2.py`) instead of Python methods (`os.path`)

**Configuration state:**
- `python-shell-completion-native-enable` = `t` (enabled)
- Native completion enabled but silently failing

### Next Steps (Resume Here)

1. Check `python-shell-interpreter` value
2. Check `*Messages*` for completion errors after TAB
3. Evaluate in `*scratch*`:
   ```elisp
   (with-current-buffer "*Python*"
     (python-shell-completion-native-try))
   ```
   - Returns `t` = native completion working
   - Returns `nil` = native completion broken (confirms need for Jupyter)

4. If native completion is broken, proceed with Jupyter integration

---

*Last updated: 2025-12-22*
