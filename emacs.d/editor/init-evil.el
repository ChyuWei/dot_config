;;; init-evil.el --- evil config -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(use-package evil
  :ensure t
  :init (setq evil-want-keybinding nil)
  :hook (after-init . evil-mode))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :ensure t
  :after evil
  :config
  (global-evil-surround-mode 1))

(provide 'init-evil)
