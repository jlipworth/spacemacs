;;; funcs.el --- PDF Layer functions File for Spacemacs  -*- lexical-binding: nil; -*-
;;
;; Copyright (c) 2012-2025 Sylvain Benner & Contributors
;;
;; Author: André Peric Tavares <andre.peric.tavares@gmail.com>
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


(defun spacemacs//pdf-tools-setup-transient-state ()
  "Setup pdf-tools transient state with toggleable help hint.

Beware: due to transient state's implementation details this
function must be called in the :init section of `use-package' or
full hint text will not show up!"
  (defvar spacemacs--pdf-tools-ts-full-hint-toggle t
    "Toggle the state of the pdf-tools transient state documentation.")

  (defvar spacemacs--pdf-tools-ts-full-hint nil
    "Display full pdf transient state documentation.")

  (defvar spacemacs--pdf-tools-ts-minified-hint nil
    "Display minified pdf transient state documentation.")

  (defun spacemacs//pdf-tools-ts-toggle-hint ()
    "Toggle the full hint docstring for the pdf-tools transient state."
    (interactive)
    (setq spacemacs--pdf-tools-ts-full-hint-toggle
          (not spacemacs--pdf-tools-ts-full-hint-toggle)))

  (defun spacemacs//pdf-tools-ts-hint ()
    "Return a condensed/full hint for the pdf-tools transient state"
    (concat
     " "
     (if spacemacs--pdf-tools-ts-full-hint-toggle
         spacemacs--pdf-tools-ts-full-hint
       (concat "[" (propertize "?" 'face 'hydra-face-red) "] help"))))

  (spacemacs|transient-state-format-hint pdf-tools
    spacemacs--pdf-tools-ts-full-hint
    (format "\n[_?_] toggle help
 Navigation^^^^                Scale/Fit^^                    Annotations^^       Actions^^           Other^^
 ----------^^^^--------------- ---------^^------------------  -----------^^------ -------^^---------- -----^^---
 [_j_/_k_] scroll down/up      [_W_] fit to width             [_aa_] attach       [_s_] search         [_q_] quit
 [_h_/_l_] scroll left/right   [_H_] fit to height            [_aD_] delete       [_O_] outline
 [_d_/_u_] pg down/up          [_P_] fit to page              [_ah_] highlight    [_p_] print
 [_J_/_K_] next/prev pg        [_m_] slice using mouse        [_al_] list         [_o_] open link
 [_0_/_$_] full scroll l/r     [_b_] slice from bounding box  [_am_] markup       [_r_] revert
 [_[_/_]_] history back/for    [_R_] reset slice              [_ao_] strikeout    [_n_] night mode
 ^^^^                          [_zr_] reset zoom              [_as_] squiggly
 ^^^^                          ^^                             [_at_] text
 ^^^^                          ^^                             [_au_] underline"))

  (spacemacs|define-transient-state pdf-tools
    :title "PDF-tools Transient State"
    :hint-is-doc t
    :dynamic-hint (spacemacs//pdf-tools-ts-hint)
    :on-enter (setq which-key-inhibit t)
    :on-exit (setq which-key-inhibit nil)
    :evil-leader-for-mode (pdf-view-mode . ".")
    :bindings
    ("?" spacemacs//pdf-tools-ts-toggle-hint)
    ;; Navigation
    ("j"  pdf-view-next-line-or-next-page)
    ("k"  pdf-view-previous-line-or-previous-page)
    ("l"  image-forward-hscroll)
    ("h"  image-backward-hscroll)
    ("J"  pdf-view-next-page)
    ("K"  pdf-view-previous-page)
    ("u"  pdf-view-scroll-down-or-previous-page)
    ("d"  pdf-view-scroll-up-or-next-page)
    ("0"  image-bol)
    ("$"  image-eol)
    ("["  pdf-history-backward)
    ("]"  pdf-history-forward)
    ;; Scale/Fit
    ("W"  pdf-view-fit-width-to-window)
    ("H"  pdf-view-fit-height-to-window)
    ("P"  pdf-view-fit-page-to-window)
    ("m"  pdf-view-set-slice-using-mouse)
    ("b"  pdf-view-set-slice-from-bounding-box)
    ("R"  pdf-view-reset-slice)
    ("zr" pdf-view-scale-reset)
    ;; Annotations
    ("aa" pdf-annot-attachment-dired :exit t)
    ("aD" pdf-annot-delete)
    ("ah" pdf-annot-add-highlight-markup-annotation)
    ("al" pdf-annot-list-annotations :exit t)
    ("am" pdf-annot-add-markup-annotation)
    ("ao" pdf-annot-add-strikeout-markup-annotation)
    ("as" pdf-annot-add-squiggly-markup-annotation)
    ("at" pdf-annot-add-text-annotation)
    ("au" pdf-annot-add-underline-markup-annotation)
    ;; Actions
    ("s" pdf-occur :exit t)
    ("O" pdf-outline :exit t)
    ("p" pdf-misc-print-document :exit t)
    ("o" pdf-links-action-perform :exit t)
    ("r" pdf-view-revert-buffer)
    ("n" pdf-view-midnight-minor-mode)
    ;; Other
    ("q" nil :exit t)))
