;;; init-tool.el --- Usefule tools -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(require 'init-custom)

(use-package magit
  :ensure t
  :init (setq magic-diff-refine-hunk t))

(use-package rime
  :if myself/use-rime
  :ensure t
  :custom
  ((default-input-method "rime")
   (rime-show-candidate `posframe)
   (rime-posframe-style `vertical)))

(provide 'init-tool)
