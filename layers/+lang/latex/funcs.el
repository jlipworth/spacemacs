;;; funcs.el --- Auctex Layer Functions File for Spacemacs  -*- lexical-binding: nil; -*-
;;
;; Copyright (c) 2012-2025 Sylvain Benner & Contributors
;;
;; Author: Sylvain Benner <sylvain.benner@gmail.com>
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


(defun spacemacs//latex-setup-company ()
  "Conditionally setup company based on backend."
  ;; Always activate auctex and reftex backends so that they're
  ;; accessible via company-other-backend even when using lsp.
  (when (configuration-layer/package-used-p 'company-auctex)
    (if (configuration-layer/package-used-p 'company-math)
        (spacemacs|add-company-backends
          :backends (company-math-symbols-unicode
                     company-math-symbols-latex
                     company-auctex-macros
                     company-auctex-symbols
                     company-auctex-environments)
          :modes LaTeX-mode)
      (spacemacs|add-company-backends
        :backends (company-auctex-macros
                   company-auctex-symbols
                   company-auctex-environments)
        :modes LaTeX-mode)))
  (when (configuration-layer/package-used-p 'company-reftex)
    (spacemacs|add-company-backends
      :backends company-reftex-labels
      company-reftex-citations
      :modes LaTeX-mode))
  (when (eq latex-backend 'lsp)
    (spacemacs|add-company-backends
      :backends company-capf
      :modes LaTeX-mode)))

(defun spacemacs//latex-setup-backend ()
  "Conditionally setup latex backend."
  (when (eq latex-backend 'lsp)
    (require 'lsp-latex)
    (lsp-deferred)))

(defun spacemacs//latex-setup-pdf-tools ()
  "Conditionally setup pdf-tools."
  (when latex-view-with-pdf-tools
    (if (configuration-layer/layer-used-p 'pdf)
        (progn
          (setf (alist-get 'output-pdf TeX-view-program-selection) '("PDF Tools"))
          (when latex-view-pdf-in-split-window
            (setq pdf-sync-forward-display-action
                  '(nil . ((inhibit-same-window . t))))))
      (spacemacs-buffer/warning "Latex Layer: latex-view-with-pdf-tools is non-nil but pdf layer is not installed, this setting will have no effect."))))

(defun spacemacs//latex-magic-search-symbol (regexp bound point-safe)
  "Search forward for Magic LaTeX symbol REGEXP before BOUND.

Skip escaped commands, comments, verbatim text, and a match containing point
when POINT-SAFE is non-nil.  Return nil instead of signaling an error when no
valid match remains.  Match data describes the successful match."
  (let ((case-fold-search nil)
        found
        valid)
    (while
        (progn
          (setq found
                (condition-case nil
                    (re-search-forward regexp bound t)
                  (invalid-regexp nil)))
          (when found
            (setq valid
                  (save-match-data
                    (save-excursion
                      (and (goto-char (match-beginning 0))
                           (not (and point-safe
                                     (or (null ml/jit-point)
                                         (and (< (point) ml/jit-point)
                                              (< ml/jit-point
                                                 (match-end 0))))))
                           (spacemacs//latex-magic-unescaped-p (point))
                           (not (ml/skip-comments-and-verbs)))))))
          (and found (not valid))))
    found))

(defun spacemacs//latex-magic-unescaped-p (position)
  "Return non-nil when POSITION follows an even number of backslashes."
  (let ((cursor position)
        (backslashes 0))
    (while (and (> cursor (point-min))
                (eq ?\\ (char-before cursor)))
      (setq cursor (1- cursor)
            backslashes (1+ backslashes)))
    (zerop (% backslashes 2))))

(defvar spacemacs--latex-magic-symbol-plan nil
  "Cached segmented search plan for `ml/symbols'.")

(defvar spacemacs--latex-magic-symbol-plan-source nil
  "Value of `ml/symbols' used to build the cached search plan.")

(defun spacemacs//latex-magic-exact-symbol-source (symbol)
  "Return literal command text when SYMBOL has a simple exact regexp."
  (let ((regexp (car symbol)))
    (when (and (string-prefix-p "\\\\" regexp)
               (string-suffix-p "\\>" regexp)
               (> (length regexp) 4)
               (string-match-p "\\`[[:alpha:]@]+\\'"
                               (substring regexp 2 -2)))
      (concat "\\" (substring regexp 2 -2)))))

(defun spacemacs//latex-magic-exact-segment (symbols)
  "Return a combined search-plan segment for exact SYMBOLS."
  (let ((table (make-hash-table :test #'equal))
        sources)
    (dolist (symbol symbols)
      (let ((source (spacemacs//latex-magic-exact-symbol-source symbol)))
        (puthash source symbol table)
        (push source sources)))
    (list 'exact
          (concat (regexp-opt (nreverse sources)) "\\>")
          table)))

(defun spacemacs//latex-magic-build-symbol-plan ()
  "Build an order-preserving segmented search plan for `ml/symbols'."
  (let ((counts (make-hash-table :test #'equal))
        exact-run
        plan)
    (dolist (symbol ml/symbols)
      (when-let ((source (spacemacs//latex-magic-exact-symbol-source symbol)))
        (puthash source (1+ (gethash source counts 0)) counts)))
    (cl-labels
        ((flush-exact-run
          ()
          (when exact-run
            (push (spacemacs//latex-magic-exact-segment
                   (nreverse exact-run))
                  plan)
            (setq exact-run nil))))
      (dolist (symbol ml/symbols)
        (let ((source (spacemacs//latex-magic-exact-symbol-source symbol)))
          (if (and source (= 1 (gethash source counts)))
              (push symbol exact-run)
            (flush-exact-run)
            (push (list 'regexp (car symbol) symbol) plan))))
      (flush-exact-run))
    (nreverse plan)))

(defun spacemacs//latex-magic-symbol-plan ()
  "Return a cached search plan corresponding to `ml/symbols'."
  (unless (eq spacemacs--latex-magic-symbol-plan-source ml/symbols)
    (setq spacemacs--latex-magic-symbol-plan-source ml/symbols
          spacemacs--latex-magic-symbol-plan
          (spacemacs//latex-magic-build-symbol-plan)))
  spacemacs--latex-magic-symbol-plan)

(defun spacemacs//latex-magic-apply-symbol (symbol)
  "Create a Magic LaTeX overlay for the current SYMBOL match."
  (let* ((old-overlay
          (ml/overlay-at (match-beginning 0) 'category 'ml/ov-pretty))
         (priority-base
          (and old-overlay (or (overlay-get old-overlay 'priority) 1)))
         (old-display (and old-overlay (overlay-get old-overlay 'display))))
    (unless (stringp old-display)
      (ml/make-pretty-overlay
       (match-beginning 0) (match-end 0)
       'priority (when old-overlay (1+ priority-base))
       'display (propertize (eval (cdr symbol)) 'display old-display)))))

(defun spacemacs//latex-magic-prettify-symbols (beg end)
  "Create Magic LaTeX symbol overlays between BEG and END."
  (dolist (segment (spacemacs//latex-magic-symbol-plan))
    (save-excursion
      (goto-char beg)
      (let ((regexp (cadr segment)))
        (while (spacemacs//latex-magic-search-symbol regexp end t)
          (spacemacs//latex-magic-apply-symbol
           (if (eq 'exact (car segment))
               (gethash (match-string-no-properties 0) (nth 2 segment))
             (nth 2 segment))))))))

(defun spacemacs//latex-magic-jit-prettifier (function beg end)
  "Run Magic LaTeX prettifier FUNCTION over BEG through END efficiently.

The package implementation still creates subscript and superscript overlays.
Its exception-driven symbol pass is replaced with
`spacemacs//latex-magic-prettify-symbols'."
  (if (not latex-enable-magic-symbols-optimization)
      (funcall function beg end)
    (let ((pretty-symbols magic-latex-enable-pretty-symbols))
      (let ((magic-latex-enable-pretty-symbols nil))
        (funcall function beg end))
      (when pretty-symbols
        (spacemacs//latex-magic-prettify-symbols beg end)))))

(defun latex/build ()
  (interactive)
  (let ((TeX-save-query nil))
    (TeX-save-document (TeX-master-file)))
  (TeX-command latex-build-command 'TeX-master-file -1))
;; (setq build-proc (TeX-command latex-build-command 'TeX-master-file -1))
;; ;; Sometimes, TeX-command returns nil causing an error in set-process-sentinel
;; (when build-proc
;;   (set-process-sentinel build-proc 'latex//build-sentinel))))

(defun latex//build-sentinel (process event)
  (if (string= event "finished\n")
      (TeX-view)
    (message "Errors! Check with C-`")))

(defun latex//autofill ()
  "Check whether the pointer is currently inside one of the
environments described in `latex-nofill-env' and if so, inhibits
the automatic filling of the current paragraph."
  (let ((do-auto-fill t)
        (current-environment "")
        (level 0))
    (while (and do-auto-fill (not (string= current-environment "document")))
      (setq level (1+ level)
            current-environment (LaTeX-current-environment level)
            do-auto-fill (not (member current-environment latex-nofill-env))))
    (when do-auto-fill
      (do-auto-fill))))

(defun latex/auto-fill-mode ()
  "Toggle auto-fill-mode using the custom auto-fill function."
  (interactive)
  (auto-fill-mode)
  (setq auto-fill-function 'latex//autofill))

;; Rebindings for TeX-font
(defun latex/font-bold () (interactive) (TeX-font nil ?\C-b))
(defun latex/font-medium () (interactive) (TeX-font nil ?\C-m))
(defun latex/font-code () (interactive) (TeX-font nil ?\C-t))
(defun latex/font-emphasis () (interactive) (TeX-font nil ?\C-e))
(defun latex/font-italic () (interactive) (TeX-font nil ?\C-i))
(defun latex/font-clear () (interactive) (TeX-font nil ?\C-d))
(defun latex/font-calligraphic () (interactive) (TeX-font nil ?\C-a))
(defun latex/font-small-caps () (interactive) (TeX-font nil ?\C-c))
(defun latex/font-sans-serif () (interactive) (TeX-font nil ?\C-f))
(defun latex/font-normal () (interactive) (TeX-font nil ?\C-n))
(defun latex/font-serif () (interactive) (TeX-font nil ?\C-r))
(defun latex/font-oblique () (interactive) (TeX-font nil ?\C-s))
(defun latex/font-upright () (interactive) (TeX-font nil ?\C-u))
