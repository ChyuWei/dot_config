;;; init-edit.el --- editor config -*- lexical-binding: t; -*-

(setq-default indent-tabs-mode nil
              tab-always-indent nil
              tab-width 4)

(setq-default fill-column 80
              require-final-newline t)

;; encoding
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
(set-language-environment 'utf-8)
(set-default-coding-systems 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(set-file-name-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)

(use-package company
  :ensure t
  :diminish
  :hook (after-init . global-company-mode)
  :bind (("M-/" . company-complete)))

(use-package smartparens
  :ensure t
  :config (require 'smartparens-config)
  :hook (prog-mode . smartparens-mode))

(provide 'init-edit)
