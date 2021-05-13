;;; init-org.el --- org config -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(use-package org
  :hook ((org-mode . visual-line-mode)
         (org-mode . org-indent-mode)))

(use-package toc-org
  :ensure t
  :hook (org-mode . toc-org-mode))

(provide 'init-org)

