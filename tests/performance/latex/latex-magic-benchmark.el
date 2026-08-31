;;; latex-magic-benchmark.el --- Benchmark Magic LaTeX JIT passes -*- lexical-binding: t; -*-
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

;; Run from the repository root as documented in README.org.  Timing results
;; are diagnostics rather than pass/fail tests because CI timing assertions
;; are inherently noisy.

;;; Code:

(require 'cl-lib)
(require 'seq)

(when-let ((directory (getenv "SPACEMACS_BENCH_PACKAGE_DIR")))
  (setq package-user-dir (expand-file-name directory))
  (require 'package)
  (package-initialize))

(require 'tex)
(require 'magic-latex-buffer)

(defconst latex-magic-benchmark--positions '(0.02 0.25 0.50 0.75 0.95))

(defconst latex-magic-benchmark--synthetic-fragment
  (concat
   "\\section{A representative section}\n"
   "Text with \\textbf{bold}, \\emph{emphasis}, and a citation \\cite{sample}.\n"
   "The model is $y_i = \\alpha + \\beta x_i + \\epsilon_i$ and "
   "$\\sigma^2 = \\frac{1}{n} \\sum_{i=1}^{n}(x_i-\\mu)^2$.\n"
   "\\begin{align}\n"
   "  \\mathbb{E}[Y|X] &= \\alpha + \\beta X \\\\\n"
   "  \\operatorname{Var}(Y) &= \\sigma^2 + \\tau^2\n"
   "\\end{align}\n"
   "{\\large A highlighted block} and {\\centering centered text}.\n"
   "\\begin{itemize}\n"
   "\\item A nested value $a_{b_c}^{d^e}$ with arrows $A \\rightarrow B$.\n"
   "\\item Relations $x \\leq y$, $x \\neq z$, and $u \\in \\mathbb{R}$.\n"
   "\\end{itemize}\n\n"))

(defun latex-magic-benchmark--env-number (name default)
  "Return numeric environment variable NAME, or DEFAULT."
  (if-let ((value (getenv name)))
      (string-to-number value)
    default))

(defun latex-magic-benchmark--synthetic-document (kib)
  "Return a synthetic LaTeX document of approximately KIB kibibytes."
  (let ((target (* kib 1024))
        (header "\\documentclass{article}\n\\usepackage{amsmath,amssymb}\n\\begin{document}\n")
        (footer "\\end{document}\n")
        parts
        (size 0))
    (while (< size target)
      (push latex-magic-benchmark--synthetic-fragment parts)
      (setq size (+ size (string-bytes latex-magic-benchmark--synthetic-fragment))))
    (concat header (apply #'concat (nreverse parts)) footer)))

(defun latex-magic-benchmark--percentile (sorted fraction)
  "Return FRACTION percentile from SORTED numeric values."
  (nth (min (1- (length sorted))
            (floor (* fraction (length sorted))))
       sorted))

(defun latex-magic-benchmark--region-at (fraction lines)
  "Return a region of approximately LINES lines near buffer FRACTION."
  (goto-char (+ (point-min)
                (floor (* fraction (- (point-max) (point-min))))))
  (let ((beg (line-beginning-position)))
    (forward-line lines)
    (cons beg (point))))

(defun latex-magic-benchmark--clear-overlays ()
  "Delete overlays created by Magic LaTeX in the current buffer."
  (dolist (overlay (overlays-in (point-min) (point-max)))
    (when (memq (overlay-get overlay 'category)
                '(ml/ov-pretty ml/ov-block ml/ov-align ml/ov-align-alignment))
      (delete-overlay overlay))))

(defun latex-magic-benchmark--overlay-count ()
  "Count Magic LaTeX overlays in the current buffer."
  (cl-count-if
   (lambda (overlay)
     (memq (overlay-get overlay 'category)
           '(ml/ov-pretty ml/ov-block ml/ov-align ml/ov-align-alignment)))
   (overlays-in (point-min) (point-max))))

(defun latex-magic-benchmark--run-prettifier (beg end pretty suscript)
  "Run the prettifier on BEG through END.

Enable symbol display when PRETTY is non-nil and su/subscript display when
SUSCRIPT is non-nil."
  (let ((magic-latex-enable-pretty-symbols pretty)
        (magic-latex-enable-suscript suscript))
    (ml/jit-prettifier beg end)))

(defun latex-magic-benchmark--run-all (beg end)
  "Run all Magic LaTeX JIT passes from BEG through END.

The order matches `jit-lock-functions' after Magic LaTeX registers its
functions.  Point movement between passes is intentionally preserved because
that is how `run-hook-wrapped' invokes the real hook."
  (font-lock-fontify-region beg end)
  (ml/jit-block-aligner beg end)
  (ml/jit-block-highlighter beg end)
  (ml/jit-prettifier beg end))

(defun latex-magic-benchmark--run-all-with
    (beg end pretty suscript highlight align)
  "Run all passes over BEG through END with selected features.

PRETTY, SUSCRIPT, HIGHLIGHT, and ALIGN control their corresponding Magic LaTeX
features."
  (let ((magic-latex-enable-pretty-symbols pretty)
        (magic-latex-enable-suscript suscript)
        (magic-latex-enable-block-highlight highlight)
        (magic-latex-enable-block-align align))
    (latex-magic-benchmark--run-all beg end)))

(defun latex-magic-benchmark--run-font-lock (beg end)
  "Refontify BEG through END with AUCTeX's ordinary font lock."
  (font-lock-unfontify-region beg end)
  (font-lock-fontify-region beg end))

(defun latex-magic-benchmark--run-auctex-prettify (beg end)
  "Refontify BEG through END using AUCTeX's built-in symbol prettifier."
  (unless prettify-symbols-mode
    (prettify-symbols-mode 1))
  (latex-magic-benchmark--run-font-lock beg end))

(defconst latex-magic-benchmark--scenarios
  `((symbols . ,(lambda (beg end)
                  (latex-magic-benchmark--run-prettifier beg end t nil)))
    (suscript . ,(lambda (beg end)
                   (latex-magic-benchmark--run-prettifier beg end nil t)))
    (prettifier . ,(lambda (beg end)
                     (latex-magic-benchmark--run-prettifier beg end t t)))
    (block-highlight . ml/jit-block-highlighter)
    (block-align . ml/jit-block-aligner)
    (all-no-symbols . ,(lambda (beg end)
                         (latex-magic-benchmark--run-all-with
                          beg end nil t t t)))
    (all-no-block-highlight . ,(lambda (beg end)
                                 (latex-magic-benchmark--run-all-with
                                  beg end t t nil t)))
    (all-no-block-align . ,(lambda (beg end)
                             (latex-magic-benchmark--run-all-with
                              beg end t t t nil)))
    (spacemacs-magic-no-symbols . ,(lambda (beg end)
                                     (latex-magic-benchmark--run-all-with
                                      beg end nil t t nil)))
    (spacemacs-magic . ,(lambda (beg end)
                          (latex-magic-benchmark--run-all-with
                           beg end t t t nil)))
    (all . latex-magic-benchmark--run-all)
    ;; Keep these last: enabling `prettify-symbols-mode' changes subsequent
    ;; ordinary font-lock passes in this buffer.
    (auctex-font-lock . latex-magic-benchmark--run-font-lock)
    (auctex-prettify . latex-magic-benchmark--run-auctex-prettify)))

(defun latex-magic-benchmark--sample (function beg end)
  "Time FUNCTION over BEG through END and return timing plus overlay count."
  (latex-magic-benchmark--clear-overlays)
  (garbage-collect)
  (let ((gc-before gc-elapsed)
        (gcs-before gcs-done)
        (started (current-time)))
    ;; JIT functions are normally invoked with point at the beginning of the
    ;; chunk.  Two Magic LaTeX passes ignore their BEG argument and instead
    ;; inspect point, so making this explicit is required for reproducibility.
    (goto-char beg)
    (funcall function beg end)
    (list (float-time (time-subtract (current-time) started))
          (- gcs-done gcs-before)
          (- gc-elapsed gc-before)
          (latex-magic-benchmark--overlay-count))))

(defun latex-magic-benchmark--measure-scenario
    (name function regions iterations)
  "Measure NAME using FUNCTION over REGIONS for ITERATIONS traversals."
  (let (elapsed gc-time overlays)
    ;; Exclude one-time regexp and glyph-composition setup from steady-state
    ;; viewport timings.
    (goto-char (caar regions))
    (funcall function (caar regions) (cdar regions))
    (latex-magic-benchmark--clear-overlays)
    (dotimes (_ iterations)
      (dolist (region regions)
        (pcase-let ((`(,seconds ,_gcs ,gc-seconds ,count)
                     (latex-magic-benchmark--sample
                      function (car region) (cdr region))))
          (push seconds elapsed)
          (push gc-seconds gc-time)
          (push count overlays))))
    (setq elapsed (sort elapsed #'<))
    (list name
          (length elapsed)
          (/ (apply #'+ elapsed) (length elapsed))
          (latex-magic-benchmark--percentile elapsed 0.50)
          (latex-magic-benchmark--percentile elapsed 0.95)
          (car (last elapsed))
          (apply #'+ gc-time)
          (/ (float (apply #'+ overlays)) (length overlays)))))

(defun latex-magic-benchmark--print-result (source chars result)
  "Print benchmark RESULT for SOURCE containing CHARS characters."
  (pcase-let ((`(,name ,samples ,mean ,median ,p95 ,maximum ,gc-time ,overlays)
               result))
    (princ
     (format "%s\t%d\t%s\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.1f\n"
             source chars name samples mean median p95 maximum gc-time overlays))))

(defun latex-magic-benchmark--run-buffer (source content iterations lines)
  "Benchmark CONTENT identified by SOURCE with ITERATIONS and viewport LINES."
  (with-temp-buffer
    (setq buffer-file-name source)
    (insert content)
    (LaTeX-mode)
    (font-lock-mode 1)
    ;; Magic LaTeX expects its passes to run after ordinary fontification.
    (font-lock-fontify-region (point-min) (point-max))
    (let ((ml/jit-point (point-max))
          (regions (mapcar
                    (lambda (fraction)
                      (save-excursion
                        (latex-magic-benchmark--region-at fraction lines)))
                    latex-magic-benchmark--positions)))
      (dolist (scenario latex-magic-benchmark--scenarios)
        (latex-magic-benchmark--print-result
         source (buffer-size)
         (latex-magic-benchmark--measure-scenario
          (car scenario) (cdr scenario) regions iterations))))))

(defun latex-magic-benchmark-main ()
  "Run the Magic LaTeX benchmark using command-line arguments."
  (when (equal (car command-line-args-left) "--")
    (pop command-line-args-left))
  (let ((iterations (latex-magic-benchmark--env-number
                     "LATEX_BENCH_ITERATIONS" 5))
        (lines (latex-magic-benchmark--env-number
                "LATEX_BENCH_VIEWPORT_LINES" 80))
        (synthetic-kib (latex-magic-benchmark--env-number
                        "LATEX_BENCH_SYNTHETIC_KIB" 256))
        (files command-line-args-left))
    (setq command-line-args-left nil)
    (princ "source\tchars\tscenario\tsamples\tmean_s\tmedian_s\tp95_s\tmax_s\tgc_s\tmean_overlays\n")
    (if files
        (dolist (file files)
          (latex-magic-benchmark--run-buffer
           (expand-file-name file)
           (with-temp-buffer
             (insert-file-contents file)
             (buffer-string))
           iterations lines))
      (latex-magic-benchmark--run-buffer
       (format "synthetic-%d-KiB.tex" synthetic-kib)
       (latex-magic-benchmark--synthetic-document synthetic-kib)
       iterations lines))))

(unless (getenv "LATEX_BENCH_LIBRARY_ONLY")
  (latex-magic-benchmark-main))

;;; latex-magic-benchmark.el ends here
