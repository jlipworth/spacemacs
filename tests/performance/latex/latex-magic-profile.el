;;; latex-magic-profile.el --- Profile Magic LaTeX viewport work -*- lexical-binding: t; -*-
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

;; Produce an expanded Emacs CPU-profiler call tree for one of the scenarios
;; defined by latex-magic-benchmark.el.  See README.org for usage.

;;; Code:

(require 'profiler)

(let ((process-environment (copy-sequence process-environment)))
  (setenv "LATEX_BENCH_LIBRARY_ONLY" "1")
  (load (expand-file-name
         "latex-magic-benchmark.el"
         (file-name-directory (or load-file-name buffer-file-name)))
        nil t))

(defvar latex-magic-benchmark--scenarios)
(defvar latex-magic-benchmark--positions)
(declare-function latex-magic-benchmark--env-number
                  "latex-magic-benchmark" (name default))
(declare-function latex-magic-benchmark--region-at
                  "latex-magic-benchmark" (fraction lines))
(declare-function latex-magic-benchmark--clear-overlays
                  "latex-magic-benchmark" ())

(defun latex-magic-profile--report-buffer ()
  "Return the newest CPU profiler report buffer."
  (seq-find
   (lambda (buffer)
     (string-prefix-p "*CPU-Profiler-Report " (buffer-name buffer)))
   (buffer-list)))

(defun latex-magic-profile--write-report (output)
  "Render the CPU call tree in full and write it to OUTPUT."
  (profiler-report)
  (let ((buffer (latex-magic-profile--report-buffer)))
    (unless buffer
      (error "The CPU profiler did not create a report buffer"))
    (with-current-buffer buffer
      (goto-char (point-min))
      (profiler-report-expand-entry t)
      (write-region
       (buffer-substring-no-properties (point-min) (point-max))
       nil output nil 'silent))))

(defun latex-magic-profile-main ()
  "Profile a benchmark scenario using command-line arguments."
  (when (equal (car command-line-args-left) "--")
    (pop command-line-args-left))
  (pcase-let ((`(,source ,output) command-line-args-left))
    (unless (and source output)
      (error "Expected SOURCE.tex and OUTPUT.txt arguments"))
    (setq command-line-args-left nil)
    (let* ((scenario-name
            (intern (or (getenv "LATEX_BENCH_PROFILE_SCENARIO")
                        "spacemacs-magic")))
           (scenario (alist-get scenario-name
                                latex-magic-benchmark--scenarios))
           (iterations (latex-magic-benchmark--env-number
                        "LATEX_BENCH_PROFILE_ITERATIONS" 40))
           (lines (latex-magic-benchmark--env-number
                   "LATEX_BENCH_VIEWPORT_LINES" 80)))
      (unless scenario
        (error "Unknown benchmark scenario: %s" scenario-name))
      (with-temp-buffer
        (setq buffer-file-name (expand-file-name source))
        (insert-file-contents source)
        (LaTeX-mode)
        (font-lock-mode 1)
        (let ((regions
               (mapcar
                (lambda (fraction)
                  (save-excursion
                    (latex-magic-benchmark--region-at fraction lines)))
                latex-magic-benchmark--positions))
              (ml/jit-point (point-max)))
          ;; Prime one-time regexp setup before starting the sampler.
          (goto-char (caar regions))
          (funcall scenario (caar regions) (cdar regions))
          (latex-magic-benchmark--clear-overlays)
          (garbage-collect)
          (profiler-start 'cpu)
          (dotimes (_ iterations)
            (dolist (region regions)
              (latex-magic-benchmark--clear-overlays)
              (goto-char (car region))
              (funcall scenario (car region) (cdr region))))
          (profiler-stop)
          (latex-magic-profile--write-report (expand-file-name output)))))))

(latex-magic-profile-main)

;;; latex-magic-profile.el ends here
