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
  :diminish
  :config (which-key-mode))

(use-package magit
  :ensure t
  :defer t
  :init (setq magic-diff-refine-hunk t))

(use-package yasnippet
  :ensure t
  :defer t
  :diminish
  :hook (after-init . yas-global-mode))

(use-package yasnippet-snippets
  :ensure t
  :defer t
  :after yasnippet)


(provide 'init-util)
