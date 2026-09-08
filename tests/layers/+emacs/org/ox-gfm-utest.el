;;; ox-gfm-utest.el --- Org exporter load-order tests -*- lexical-binding: t; -*-

;; Run without Spacemacs startup or network access.  Each test starts a fresh
;; Emacs, since unloading Org cannot reliably restore deferred load hooks.
;; Supply the installed Org and ox-gfm directories with -L (see README.org).

(require 'ert)

(defconst org-test--packages-file
  (expand-file-name "../../../../layers/+emacs/org/packages.el"
                    (file-name-directory (or load-file-name buffer-file-name))))

(defun org-test--fresh-emacs (body)
  "Evaluate BODY in a fresh Emacs using the caller's package load path."
  (let ((script (make-temp-file "org-ox-gfm-test-" nil ".el"))
        (state (make-temp-file "org-ox-gfm-state-" t)))
    (unwind-protect
        (progn
          (with-temp-file script
            (prin1
             `(progn
                (setq load-path ',load-path
                      user-emacs-directory ,(file-name-as-directory state)
                      native-comp-jit-compilation nil)
                (require 'ert)
                (require 'use-package)
                (setq use-package-always-ensure nil
                      use-package-always-defer nil)
                (load ,org-test--packages-file nil t)
                ;; Package activation installs these autoloads, not ox-gfm.
                (load "ox-gfm-autoloads" nil t)
                (should-not (featurep 'org))
                (should-not (featurep 'ox))
                (should-not (featurep 'ox-gfm))
                ;; There must be no residual eager Org post-config hook.
                (should-not (fboundp 'org/pre-init-ox-gfm))
                ,@body)
             (current-buffer)))
          (with-temp-buffer
            (let ((status (call-process
                           (expand-file-name invocation-name invocation-directory)
                           nil t nil "-Q" "--batch" "-l" script)))
              (ert-info ((buffer-string))
                (should (eql status 0))))))
      (delete-file script)
      (delete-directory state t))))

(defconst org-test--document
  "#+OPTIONS: toc:nil num:nil\n* Heading\n\nA +deleted+ word.\n\n#+begin_src text\nhello\n#+end_src\n")

(defconst org-test--assert-output
  '(with-current-buffer "*Org GFM Export*"
     (should (string-match-p "# Heading" (buffer-string)))
     (should (string-match-p "~~deleted~~" (buffer-string)))
     (should (string-match-p "```text\nhello\n```" (buffer-string)))))

(ert-deftest org-ox-gfm-deferred-on-org-mode ()
  (org-test--fresh-emacs
   '((org/init-ox-gfm)
     (with-temp-buffer (org-mode))
     (should (featurep 'org))
     (dolist (feature '(ox ox-md ox-html ox-publish ox-gfm))
       (should-not (featurep feature))))))

(ert-deftest org-ox-gfm-dispatcher-registers-and-exports ()
  (org-test--fresh-emacs
   `((org/init-ox-gfm)
     (with-temp-buffer
       (insert ,org-test--document)
       (org-mode)
       (should-not (featurep 'ox))
       ;; Exercise the real autoloaded dispatcher and its G/GFM menu, not a
       ;; mocked dispatcher or a manually required export backend.
       (let ((unread-command-events (list ?g ?G))
             (org-export-show-temporary-export-buffer nil))
         (org-export-dispatch))
       (should (org-export-get-backend 'gfm))
       ,org-test--assert-output))))

(ert-deftest org-ox-gfm-direct-autoload-before-ox ()
  (org-test--fresh-emacs
   `((org/init-ox-gfm)
     (should (autoloadp (symbol-function 'org-gfm-export-as-markdown)))
     (with-temp-buffer
       (insert ,org-test--document)
       (org-mode)
       (should-not (featurep 'ox))
       (let ((org-export-show-temporary-export-buffer nil))
         (org-gfm-export-as-markdown))
       (should (featurep 'ox-gfm))
       ,org-test--assert-output))))

(ert-deftest org-ox-gfm-initialized-after-ox ()
  (org-test--fresh-emacs
   `((require 'ox)
     (should-not (featurep 'ox-gfm))
     (org/init-ox-gfm)
     (should (featurep 'ox-gfm))
     (should (org-export-get-backend 'gfm))
     (with-temp-buffer
       (insert ,org-test--document)
       (org-mode)
       (let ((org-export-show-temporary-export-buffer nil))
         (org-gfm-export-as-markdown))
       ,org-test--assert-output))))

(ert-deftest org-ox-gfm-github-toggle-disabled ()
  (org-test--fresh-emacs
   '((let* ((org-enable-github-support nil)
            (toggle (plist-get (cdr (assq 'ox-gfm org-packages)) :toggle)))
       (should (eq toggle 'org-enable-github-support))
       ;; Respect the layer's actual package toggle, as configuration-layer
       ;; does when deciding whether to invoke the package initializer.
       (when (eval toggle) (org/init-ox-gfm))
       (with-temp-buffer (org-mode))
       (require 'ox)
       (should-not (featurep 'ox-gfm))
       (should-not (org-export-get-backend 'gfm))))))
