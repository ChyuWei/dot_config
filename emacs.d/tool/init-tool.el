;;; init-tool.el --- Usefule tools -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(use-package magit
  :ensure t
  :init (setq magic-diff-refine-hunk t))

(provide 'init-tool)
