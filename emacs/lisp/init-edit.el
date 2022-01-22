;;; init-edit.el --- editor config -*- lexical-binding: t; -*-

(setq-default indent-tabs-mode nil
              tab-always-indent nil
              tab-width 4)

(setq-default fill-column 80
              require-final-newline t)


(use-package company
  :ensure t
  :diminish
  :hook (after-init . global-company-mode)
  :bind (("M-/" . company-complete)))

(use-package smartparens
  :ensure t
  :diminish
  :config (require 'smartparens-config)
  :hook (prog-mode . smartparens-mode))

(provide 'init-edit)
