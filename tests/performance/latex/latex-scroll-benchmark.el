;;; latex-scroll-benchmark.el --- Benchmark LaTeX GUI scrolling -*- lexical-binding: t; -*-
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

;; Exercise viewport jumps and forced GUI redisplay.  See README.org for an
;; isolated invocation.  This script terminates only the Emacs process in
;; which it was loaded.

;;; Code:

(require 'cl-lib)
(require 'seq)

(when-let ((directory (getenv "SPACEMACS_BENCH_PACKAGE_DIR")))
  (setq package-user-dir (expand-file-name directory))
  (require 'package)
  (package-initialize))

(require 'tex)
(require 'magic-latex-buffer)

(defconst latex-scroll-benchmark--positions '(0.02 0.25 0.50 0.75 0.95))

(defun latex-scroll-benchmark--env-number (name default)
  "Return numeric environment variable NAME, or DEFAULT."
  (if-let ((value (getenv name)))
      (string-to-number value)
    default))

(defun latex-scroll-benchmark--percentile (sorted fraction)
  "Return FRACTION percentile from SORTED numeric values."
  (nth (min (1- (length sorted))
            (floor (* fraction (length sorted))))
       sorted))

(defun latex-scroll-benchmark--region-at (fraction lines)
  "Return a region of approximately LINES lines near buffer FRACTION."
  (goto-char (+ (point-min)
                (floor (* fraction (- (point-max) (point-min))))))
  (let ((beg (line-beginning-position)))
    (forward-line lines)
    (cons beg (point))))

(defun latex-scroll-benchmark--clear-overlays (beg end)
  "Delete Magic LaTeX overlays between BEG and END."
  (dolist (overlay (overlays-in beg end))
    (when (memq (overlay-get overlay 'category)
                '(ml/ov-pretty ml/ov-block ml/ov-align ml/ov-align-alignment))
      (delete-overlay overlay))))

(defun latex-scroll-benchmark--prepare (scenario)
  "Configure the current LaTeX buffer for SCENARIO."
  (pcase scenario
    ('auctex-font-lock nil)
    ('auctex-prettify (prettify-symbols-mode 1))
    ((or 'magic 'magic-no-symbols)
     ;; Match the layer's defaults: highlighting and su/subscripts are on,
     ;; while block alignment and inline images are off.
     (setq-local magic-latex-enable-block-highlight t
                 magic-latex-enable-suscript t
                 magic-latex-enable-block-align nil
                 magic-latex-enable-inline-image nil
                 magic-latex-enable-pretty-symbols (eq scenario 'magic))
     (magic-latex-buffer 1))))

(defun latex-scroll-benchmark--redisplay (window region cold)
  "Jump WINDOW to REGION and return forced redisplay time.

When COLD is non-nil, invalidate fontification and Magic LaTeX overlays first,
simulating navigation into a viewport which has not yet been displayed."
  (pcase-let ((`(,beg . ,end) region))
    (when cold
      (latex-scroll-benchmark--clear-overlays beg end)
      (font-lock-flush beg end))
    (goto-char beg)
    (set-window-point window beg)
    (set-window-start window beg t)
    (let ((started (current-time)))
      (redisplay t)
      (float-time (time-subtract (current-time) started)))))

(defun latex-scroll-benchmark--measure (window regions iterations cold)
  "Measure WINDOW jumps through REGIONS for ITERATIONS.

COLD controls whether fontification is invalidated before every jump."
  (let (elapsed)
    (dotimes (_ iterations)
      (dolist (region regions)
        (push (latex-scroll-benchmark--redisplay window region cold) elapsed)))
    (sort elapsed #'<)))

(defun latex-scroll-benchmark--print-result
    (stream source scenario phase elapsed)
  "Write one result for SOURCE, SCENARIO, PHASE and ELAPSED to STREAM."
  (princ
   (format "%s\t%s\t%s\t%d\t%.6f\t%.6f\t%.6f\t%.6f\n"
           source scenario phase (length elapsed)
           (/ (apply #'+ elapsed) (length elapsed))
           (latex-scroll-benchmark--percentile elapsed 0.50)
           (latex-scroll-benchmark--percentile elapsed 0.95)
           (car (last elapsed)))
   stream))

(defun latex-scroll-benchmark--run-scenario
    (stream source content scenario iterations lines)
  "Benchmark one SCENARIO over CONTENT and write it to STREAM.

SOURCE identifies the content.  Run ITERATIONS viewport traversals using
regions of LINES lines."
  (with-temp-buffer
    (setq buffer-file-name source)
    (insert content)
    (set-buffer-modified-p nil)
    (LaTeX-mode)
    (font-lock-mode 1)
    (latex-scroll-benchmark--prepare scenario)
    (let* ((window (selected-window))
           (regions (mapcar
                     (lambda (fraction)
                       (save-excursion
                         (latex-scroll-benchmark--region-at fraction lines)))
                     latex-scroll-benchmark--positions)))
      (set-window-buffer window (current-buffer))
      ;; Prime package and display initialization outside the measurements.
      (latex-scroll-benchmark--redisplay window (car regions) t)
      (latex-scroll-benchmark--print-result
       stream source scenario 'uncached
       (latex-scroll-benchmark--measure window regions iterations t))
      (latex-scroll-benchmark--print-result
       stream source scenario 'cached
       (latex-scroll-benchmark--measure window regions iterations nil)))))

(defun latex-scroll-benchmark-main ()
  "Run the GUI redisplay benchmark from command-line arguments."
  (unless (display-graphic-p)
    (error "LaTeX scroll benchmark requires a graphical display"))
  (when (equal (car command-line-args-left) "--")
    (pop command-line-args-left))
  (pcase-let ((`(,source ,output) command-line-args-left))
    (unless (and source output)
      (error "Expected SOURCE.tex and OUTPUT.tsv arguments"))
    (setq command-line-args-left nil)
    (let ((iterations (latex-scroll-benchmark--env-number
                       "LATEX_BENCH_ITERATIONS" 5))
          (lines (latex-scroll-benchmark--env-number
                  "LATEX_BENCH_VIEWPORT_LINES" 80))
          (content (with-temp-buffer
                     (insert-file-contents source)
                     (buffer-string))))
      (with-temp-file output
        (insert "source\tscenario\tphase\tsamples\tmean_s\tmedian_s\tp95_s\tmax_s\n")
        (dolist (scenario
                 '(auctex-font-lock auctex-prettify magic-no-symbols magic))
          (latex-scroll-benchmark--run-scenario
           (current-buffer) (expand-file-name source) content
           scenario iterations lines)))))
  (kill-emacs 0))

(latex-scroll-benchmark-main)

;;; latex-scroll-benchmark.el ends here
