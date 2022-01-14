;;; init-util.el --- Usefule tools -*- lexical-binding: t; -*-

(windmove-default-keybindings)

(use-package diminish
  :ensure t)

(use-package ivy
  :ensure t
  :diminish ivy-mode
  :hook (after-init . ivy-mode))

(use-package which-key
  :ensure t
  :diminish which-key-mode
  :config (which-key-mode))

(use-package magit
  :ensure t
  :init (setq magic-diff-refine-hunk t))

(provide 'init-util)
