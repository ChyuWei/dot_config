;;; init-editor.el --- editor config -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(setq-default indent-tabs-mode nil
	      tab-always-indent nil
	      tab-width 4)

(setq-default fill-column 80
	      require-final-newline t)

;; show number in prog-mode
(use-package display-line-numbers
  :hook (prog-mode . display-line-numbers-mode))

(use-package highlight-numbers
  :ensure t
  :hook (prog-mode . highlight-numbers-mode))

(use-package highlight-escape-sequences
  :ensure t
  :hook (prog-mode . hes-mode))

(use-package autorevert
  :diminish
  :hook (after-init . global-auto-revert-mode))

(use-package elec-pair
  :hook (prog-mode . electric-pair-mode))

(require 'init-evil)

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

(provide 'init-editor)
;;; init-editor.el ends here
