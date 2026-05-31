;;; config.el --- PDF Layer Configuration File for Spacemacs  -*- lexical-binding: nil; -*-
;;
;; Copyright (c) 2012-2021 Sylvain Benner
;; Copyright (c) 2020-2025 Sylvain Benner & Contributors
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

(defvar pdf-view-use-scaling t
  "Whether images should be scaled for rendering, e.g. on HiDPI/Retina displays.

This mirrors `pdf-view-use-scaling' from pdf-tools (which also defaults to t).
Scaling produces sharper pages on high-resolution displays, but can cause
performance problems on some setups, especially after zooming.  Set this to nil
in the layer variables if you experience sluggish rendering:

  (pdf :variables pdf-view-use-scaling nil)")
