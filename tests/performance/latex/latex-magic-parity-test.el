;;; latex-magic-parity-test.el --- Magic LaTeX visual parity tests -*- lexical-binding: t; -*-
;;
;; Copyright (c) 2012-2025 Sylvain Benner & Contributors
;;
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

;;; Commentary:

;; Capture the visual properties produced by Magic LaTeX independently of GUI
;; glyph rasterization.  Optimized prettifier implementations can be compared
;; with `latex-magic-parity-compare-prettifiers' before GUI testing.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'seq)

(when-let ((directory (getenv "SPACEMACS_BENCH_PACKAGE_DIR")))
  (setq package-user-dir (expand-file-name directory))
  (require 'package)
  (package-initialize))

(require 'tex)
(require 'magic-latex-buffer)

(load (expand-file-name
       "layers/+lang/latex/funcs.el"
       (file-name-concat
        (file-name-directory (or load-file-name buffer-file-name)) "../../.."))
      nil t)

(defvar latex-enable-magic-symbols-optimization)
(declare-function spacemacs//latex-magic-jit-prettifier
                  "../../../layers/+lang/latex/funcs" (function beg end))
(declare-function spacemacs//latex-magic-build-symbol-plan
                  "../../../layers/+lang/latex/funcs" ())
(declare-function spacemacs//latex-magic-search-regexp
                  "../../../layers/+lang/latex/funcs"
                  (regexp &optional bound backward point-safe))
(declare-function spacemacs//latex-magic-search-regexp-advice
                  "../../../layers/+lang/latex/funcs"
                  (function regexp &optional bound backward point-safe))
(declare-function spacemacs//latex-magic-unescaped-p
                  "../../../layers/+lang/latex/funcs" (position))
(declare-function spacemacs//latex-magic-skip-blocks
                  "../../../layers/+lang/latex/funcs"
                  (n &optional exclusive backward brace-only))
(declare-function spacemacs//latex-magic-skip-blocks-advice
                  "../../../layers/+lang/latex/funcs"
                  (function n &optional exclusive backward brace-only))

(defconst latex-magic-parity--fixture
  (concat
   "\\documentclass{article}\n"
   "\\begin{document}\n"
   "\\section{Visual parity}\n"
   "Math symbols: $\\alpha + \\beta \\leq \\sum_{i=1}^{n} x_i \\rightarrow \\infty$.\n"
   "Negation: $x \\notin A$, $a \\neq b$, and $p \\not\\rightarrow q$.\n"
   "Composed accents: $\\mathbb{R} \\vec{x} \\tilde{y} \\bar{z} \\dot{q} "
   "\\hat{w} \\acute{a} \\ddot{o} \\grave{e} \\check{v} \\breve{u} \\r{a}$.\n"
   "Nested scripts: $a_{b_c}^{d^e} + \\sigma^2$.\n"
   "Decorations: \\textbf{bold}, \\textit{italic}, \\underline{under}, "
   "\\texttt{type}, and \\mathcal{C}.\n"
   "Structural commands: \\begin{itemize}\n"
   "\\item first item \\\\\n"
   "\\item second item with \\% and \\$ and spacing~here\n"
   "\\end{itemize}\n"
   "{\\large Large text} and {\\color{red} red text}.\n"
   "\\begin{center}\ncentered text on a line\n\\end{center}\n"
   "%% This comment contains ignored symbols: \\alpha \\sum \\rightarrow.\n"
   "\\begin{verbatim}\n\\alpha \\sum \\vec{x}\n\\end{verbatim}\n"
   "\\end{document}\n"))

(defconst latex-magic-parity--visual-properties
  '(display face invisible priority before-string after-string
            line-prefix wrap-prefix)
  "Overlay properties which can affect visible output.")

(defun latex-magic-parity--string-properties (string)
  "Return canonical non-nil text-property spans in STRING."
  (let ((position 0)
        runs)
    (while (< position (length string))
      (let* ((next (or (next-property-change position string)
                       (length string)))
             (properties (text-properties-at position string))
             filtered)
        (while properties
          (when (cadr properties)
            (setq filtered
                  (append filtered
                          (list (car properties)
                                (format "%S" (cadr properties))))))
          (setq properties (cddr properties)))
        (when filtered
          (push (list position next filtered) runs))
        (setq position next)))
    (nreverse runs)))

(defun latex-magic-parity--value (value)
  "Return a canonical representation of visual property VALUE."
  (if (stringp value)
      (list 'string
            (substring-no-properties value)
            (latex-magic-parity--string-properties value))
    (format "%S" value)))

(defun latex-magic-parity--properties (overlay)
  "Return canonical visual properties for OVERLAY."
  (mapcar
   (lambda (property)
     (list property
           (latex-magic-parity--value (overlay-get overlay property))))
   latex-magic-parity--visual-properties))

(defun latex-magic-parity--partner (overlay)
  "Return canonical position and properties for partner OVERLAY."
  (when (overlayp overlay)
    (list (overlay-start overlay)
          (overlay-end overlay)
          (latex-magic-parity--properties overlay))))

(defun latex-magic-parity--overlay (overlay)
  "Return a canonical visual record for Magic LaTeX OVERLAY."
  (let ((partners (overlay-get overlay 'partners)))
    (list
     (overlay-start overlay)
     (overlay-end overlay)
     (buffer-substring-no-properties
      (overlay-start overlay) (overlay-end overlay))
     (overlay-get overlay 'category)
     (latex-magic-parity--properties overlay)
     (latex-magic-parity--partner (overlay-get overlay 'partner))
     (mapcar #'latex-magic-parity--partner partners))))

(defun latex-magic-parity--snapshot ()
  "Return sorted canonical records for all Magic LaTeX overlays."
  (let ((categories
         '(ml/ov-pretty ml/ov-block ml/ov-align ml/ov-align-alignment)))
    (sort
     (delq
      nil
      (mapcar
       (lambda (overlay)
         (when (memq (overlay-get overlay 'category) categories)
           (latex-magic-parity--overlay overlay)))
       (overlays-in (point-min) (point-max))))
     (lambda (left right)
       (or (< (car left) (car right))
           (and (= (car left) (car right))
                (< (cadr left) (cadr right))))))))

(defun latex-magic-parity-render (prettifier &optional content)
  "Render CONTENT using PRETTIFIER and return its canonical snapshot.

PRETTIFIER must accept the same BEG and END arguments as `ml/jit-prettifier'.
When CONTENT is nil, use `latex-magic-parity--fixture'."
  (with-temp-buffer
    (insert (or content latex-magic-parity--fixture))
    (setq buffer-file-name "magic-latex-parity.tex")
    (LaTeX-mode)
    (font-lock-mode 1)
    (font-lock-fontify-region (point-min) (point-max))
    (set-syntax-table ml/syntax-table)
    (let ((magic-latex-enable-pretty-symbols t)
          (magic-latex-enable-suscript t)
          (magic-latex-enable-block-highlight t)
          (magic-latex-enable-block-align t)
          (ml/jit-point (point-max)))
      (goto-char (point-min))
      (ml/jit-block-aligner (point-min) (point-max))
      (goto-char (point-min))
      (ml/jit-block-highlighter (point-min) (point-max))
      (goto-char (point-min))
      (funcall prettifier (point-min) (point-max))
      (latex-magic-parity--snapshot))))

(defun latex-magic-parity-compare-prettifiers
    (reference candidate &optional content)
  "Return non-nil when REFERENCE and CANDIDATE render CONTENT identically."
  (equal (latex-magic-parity-render reference content)
         (latex-magic-parity-render candidate content)))

(defun latex-magic-parity--optimized-prettifier (beg end)
  "Run the optimized prettifier over BEG through END."
  (let ((latex-enable-magic-symbols-optimization t))
    (spacemacs//latex-magic-jit-prettifier
     (symbol-function 'ml/jit-prettifier) beg end)))

(defun latex-magic-parity--optimized-render (&optional content)
  "Render CONTENT with the full optimized Magic LaTeX search pipeline."
  (let ((reference-search (symbol-function 'ml/search-regexp))
        (reference-skip (symbol-function 'ml/skip-blocks))
        (latex-enable-magic-symbols-optimization t))
    (cl-letf (((symbol-function 'ml/search-regexp)
               (lambda (regexp &optional bound backward point-safe)
                 (spacemacs//latex-magic-search-regexp-advice
                  reference-search regexp bound backward point-safe)))
              ((symbol-function 'ml/skip-blocks)
               (lambda (n &optional exclusive backward brace-only)
                 (spacemacs//latex-magic-skip-blocks-advice
                  reference-skip n exclusive backward brace-only))))
      (latex-magic-parity-render
       #'latex-magic-parity--optimized-prettifier content))))

(defun latex-magic-parity--render-region (prettifier content beg end)
  "Render CONTENT from BEG through END with PRETTIFIER."
  (with-temp-buffer
    (insert content)
    (setq buffer-file-name "magic-latex-region-parity.tex")
    (LaTeX-mode)
    (font-lock-mode 1)
    (font-lock-fontify-region (point-min) (point-max))
    (set-syntax-table ml/syntax-table)
    (let ((magic-latex-enable-pretty-symbols t)
          (magic-latex-enable-suscript t)
          (magic-latex-enable-block-highlight t)
          (magic-latex-enable-block-align nil)
          (ml/jit-point (point-max)))
      (goto-char beg)
      (ml/jit-block-highlighter beg end)
      (goto-char beg)
      (funcall prettifier beg end)
      (latex-magic-parity--snapshot))))

(defun latex-magic-parity--optimized-region (content beg end)
  "Render CONTENT from BEG through END using every optimized Magic pass."
  (let ((reference-search (symbol-function 'ml/search-regexp))
        (reference-skip (symbol-function 'ml/skip-blocks))
        (latex-enable-magic-symbols-optimization t))
    (cl-letf (((symbol-function 'ml/search-regexp)
               (lambda (regexp &optional bound backward point-safe)
                 (spacemacs//latex-magic-search-regexp-advice
                  reference-search regexp bound backward point-safe)))
              ((symbol-function 'ml/skip-blocks)
               (lambda (n &optional exclusive backward brace-only)
                 (spacemacs//latex-magic-skip-blocks-advice
                  reference-skip n exclusive backward brace-only))))
      (latex-magic-parity--render-region
       #'latex-magic-parity--optimized-prettifier content beg end))))

(defun latex-magic-parity--region-at (content fraction lines)
  "Return an approximately LINES-line region at FRACTION through CONTENT."
  (with-temp-buffer
    (insert content)
    (goto-char (+ (point-min)
                  (floor (* fraction (- (point-max) (point-min))))))
    (let ((beg (line-beginning-position)))
      (forward-line lines)
      (cons beg (point)))))

(defun latex-magic-parity--span-visible-p (start end beg limit)
  "Return non-nil when START through END can affect BEG through LIMIT."
  (if (= start end)
      (and (<= beg start) (< start limit))
    (and (< start limit) (> end beg))))

(defun latex-magic-parity--record-visible-p (record beg end)
  "Return non-nil when overlay RECORD can affect BEG through END."
  (or (latex-magic-parity--span-visible-p
       (nth 0 record) (nth 1 record) beg end)
      (when-let ((partner (nth 5 record)))
        (latex-magic-parity--span-visible-p
         (nth 0 partner) (nth 1 partner) beg end))
      (seq-some
       (lambda (partner)
         (latex-magic-parity--span-visible-p
          (nth 0 partner) (nth 1 partner) beg end))
       (nth 6 record))))

(defun latex-magic-parity--visible-snapshot (snapshot beg end)
  "Return records in SNAPSHOT which can affect BEG through END."
  (seq-filter
   (lambda (record)
     (latex-magic-parity--record-visible-p record beg end))
   snapshot))

(defun latex-magic-parity--records-for-source (snapshot source)
  "Return records in SNAPSHOT whose source text equals SOURCE."
  (seq-filter (lambda (record) (equal source (nth 2 record))) snapshot))

(defun latex-magic-parity--search-outcome
    (search regexp bound backward point-safe)
  "Capture the observable result of calling SEARCH with Magic LaTeX arguments."
  (condition-case error-data
      (let ((value (funcall search regexp bound backward point-safe)))
        (list 'success value (point) (match-data t) (match-string 0)))
    (error
     (list 'error (car error-data) (error-message-string error-data) (point)))))

(defun latex-magic-parity--compare-searches
    (content regexp start jit-point &optional backward point-safe ignored-range)
  "Compare reference and optimized searches over CONTENT.

Begin each search at START and bind `ml/jit-point' to JIT-POINT.  When
IGNORED-RANGE is non-nil, apply a comment face between its two positions."
  (with-temp-buffer
    (insert content)
    (when ignored-range
      (put-text-property (car ignored-range) (cdr ignored-range)
                         'face 'font-lock-comment-face))
    (let ((ml/jit-point jit-point))
      (goto-char start)
      (let ((reference
             (latex-magic-parity--search-outcome
              #'ml/search-regexp regexp nil backward point-safe)))
        (goto-char start)
        (should
         (equal reference
                (latex-magic-parity--search-outcome
                 #'spacemacs//latex-magic-search-regexp
                 regexp nil backward point-safe)))))))

(defun latex-magic-parity--skip-outcome
    (skip n exclusive backward brace-only)
  "Capture the observable result of calling block function SKIP."
  (condition-case error-data
      (let ((value (funcall skip n exclusive backward brace-only)))
        (list 'success value (point) (match-data t)))
    (error
     (list 'error (car error-data) (error-message-string error-data)
           (point) (match-data t)))))

(defun latex-magic-parity--compare-block-skips
    (content start n &optional exclusive backward brace-only)
  "Compare reference and iterative block skipping over CONTENT from START."
  (with-temp-buffer
    (insert content)
    (goto-char start)
    (set-match-data (list start start))
    (let ((reference
           (latex-magic-parity--skip-outcome
            #'ml/skip-blocks n exclusive backward brace-only)))
      (goto-char start)
      (set-match-data (list start start))
      (should
       (equal reference
              (latex-magic-parity--skip-outcome
               #'spacemacs//latex-magic-skip-blocks
               n exclusive backward brace-only))))))

(ert-deftest latex-magic-parity-reference-is-deterministic ()
  (should
   (latex-magic-parity-compare-prettifiers
    #'ml/jit-prettifier #'ml/jit-prettifier)))

(ert-deftest latex-magic-parity-optimized-matches-reference ()
  (should
   (equal (latex-magic-parity-render #'ml/jit-prettifier)
          (latex-magic-parity--optimized-render)))
  (when-let ((files (getenv "LATEX_BENCH_PARITY_FILES")))
    (dolist (file (split-string files (regexp-quote path-separator) t))
      (let ((content (with-temp-buffer
                       (insert-file-contents file)
                       (buffer-string))))
        (should
         (equal (latex-magic-parity-render #'ml/jit-prettifier content)
                (latex-magic-parity--optimized-render content)))))))

(ert-deftest latex-magic-parity-optimized-viewports-match-reference ()
  (when-let ((files (getenv "LATEX_BENCH_PARITY_FILES")))
    (dolist (file (split-string files (regexp-quote path-separator) t))
      (let ((content (with-temp-buffer
                       (insert-file-contents file)
                       (buffer-string))))
        (dolist (fraction '(0.02 0.25 0.50 0.75 0.95))
          (pcase-let ((`(,beg . ,end)
                       (latex-magic-parity--region-at content fraction 80)))
            (should
             (equal
              (latex-magic-parity--visible-snapshot
               (latex-magic-parity--render-region
                #'ml/jit-prettifier content beg end)
               beg end)
              (latex-magic-parity--visible-snapshot
               (latex-magic-parity--optimized-region content beg end)
               beg end)))))))))

(ert-deftest latex-magic-parity-search-plan-preserves-rules ()
  (let* ((plan (spacemacs//latex-magic-build-symbol-plan))
         (rules
          (apply
           #'+
           (mapcar
            (lambda (segment)
              (if (eq 'exact (car segment))
                  (hash-table-count (nth 2 segment))
                1))
            plan))))
    (should (= (length ml/symbols) rules))
    (should (< (length plan) (length ml/symbols)))))

(ert-deftest latex-magic-parity-escape-check-matches-reference-regexp ()
  (with-temp-buffer
    (dotimes (backslashes 12)
      (erase-buffer)
      (insert (make-string backslashes ?\\) "alpha")
      (goto-char (1+ backslashes))
      (should
       (eq (not (null
                 (looking-back "\\([^\\\\]\\|^\\)\\(\\\\\\\\\\)*"
                               (point-min))))
           (not (null
                 (spacemacs//latex-magic-unescaped-p (point)))))))))

(ert-deftest latex-magic-parity-optimized-search-matches-reference ()
  (let ((alpha "\\\\alpha\\>"))
    ;; Successful forward and backward searches retain point and match data.
    (latex-magic-parity--compare-searches
     "\\alpha and \\alpha" alpha 1 1)
    (latex-magic-parity--compare-searches
     "\\alpha and \\alpha" alpha 18 1 t)
    ;; Escaped matches, ignored faces, and matches containing point are skipped.
    (latex-magic-parity--compare-searches
     "\\\\alpha then \\alpha" alpha 1 1)
    (latex-magic-parity--compare-searches
     "\\alpha then \\\\alpha" alpha 20 1 t)
    (latex-magic-parity--compare-searches
     "\\alpha then \\alpha" alpha 1 4 nil t)
    (latex-magic-parity--compare-searches
     "x\\alpha then \\alpha" alpha 1 1 nil nil '(1 . 8))
    ;; Failure, including invalid regexps, retains the starting point and error.
    (latex-magic-parity--compare-searches "\\\\alpha" alpha 1 1)
    (latex-magic-parity--compare-searches "text" "[" 3 1)))

(ert-deftest latex-magic-parity-iterative-block-skip-matches-reference ()
  (dolist (exclusive '(nil t))
    (latex-magic-parity--compare-block-skips
     "{outer {inner} tail}" 1 0 exclusive)
    (latex-magic-parity--compare-block-skips
     "{outer {inner} tail}" 21 0 exclusive t)
    (latex-magic-parity--compare-block-skips
     "\\begin{center}text\\end{center}" 1 0 exclusive))
  (latex-magic-parity--compare-block-skips "{outer}" 1 0 nil nil t)
  (latex-magic-parity--compare-block-skips "{" 1 0)
  (latex-magic-parity--compare-block-skips "}" 1 0))

(ert-deftest latex-magic-parity-iterative-block-skip-handles-deep-input ()
  (with-temp-buffer
    (insert (make-string 2000 ?{) (make-string 2000 ?}))
    (goto-char (point-min))
    (should (spacemacs//latex-magic-skip-blocks 0 nil nil t))
    (should (= (point) (point-max)))))

(ert-deftest latex-magic-parity-fixture-covers-symbol-families ()
  (let ((snapshot (latex-magic-parity-render #'ml/jit-prettifier)))
    (dolist (source
             '("\\alpha" "\\leq" "\\sum" "\\rightarrow" "\\notin"
               "\\mathbb{R}" "\\vec{x}" "\\textbf" "\\begin" "\\end"
               "\\item" "~" "_" "^" "\\large" "\\begin{center}"))
      (should (latex-magic-parity--records-for-source snapshot source)))))

(ert-deftest latex-magic-parity-reference-glyphs ()
  (let ((snapshot (latex-magic-parity-render #'ml/jit-prettifier)))
    (dolist (pair '(("\\alpha" . "α")
                    ("\\sum" . "∑")
                    ("\\rightarrow" . "→")
                    ("\\begin" . "▽")
                    ("\\end" . "△")))
      (let* ((record (car (latex-magic-parity--records-for-source
                           snapshot (car pair))))
             (properties (nth 4 record)))
        (should record)
        (should (equal (list 'string (cdr pair) nil)
                       (cadr (assq 'display properties))))))))

;;; latex-magic-parity-test.el ends here
