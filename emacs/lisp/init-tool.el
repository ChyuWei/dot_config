;;; init-util.el --- Usefule tools -*- lexical-binding: t; -*-

(use-package which-key
  :config (which-key-mode))

(use-package magit
  :init (setq magic-diff-refine-hunk t))

(use-package yasnippet
  :diminish
  :hook (after-init . yas-global-mode))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer))

(use-package dired
  :ensure nil
  :config (setq dired-recursive-copies 'always
                dired-recursive-deletes 'always))

(use-package diredfl
  :init (diredfl-global-mode 1))

(use-package dired-aux
  :ensure nil)

(provide 'init-util)
