;;; init-tool.el --- Usefule tools -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(use-package magit
  :ensure t
  :init (setq magic-diff-refine-hunk t))

(use-package rime
  :ensure t
  :custom
  ((default-input-method "rime")
   (rime-show-candidate `posframe)
   (rime-posframe-style `vertical)))

(provide 'init-tool)
