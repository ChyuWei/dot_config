;;; init-edit.el --- editor config -*- lexical-binding: t; -*-

(setq-default indent-tabs-mode nil
              tab-always-indent nil
              tab-width 4)

(setq-default fill-column 80
              require-final-newline t)

(use-package ivy
  :hook (after-init . ivy-mode))

(use-package subword
  :ensure nil
  :hook (after-init . global-subword-mode))

(use-package delsel
  :ensure nil
  :hook (after-init . delete-selection-mode))

(use-package so-long
  :ensure nil
  :hook (after-init . global-so-long-mode)
  :config (setq so-long-threshold 400))

(use-package autorevert
  :ensure nil
  :hook (after-init . global-auto-revert-mode))

(use-package elec-pair
  :ensure nil
  :hook (after-init . electric-pair-mode))

(use-package hideshow
  :ensure nil
  :diminish hs-minor-mode
  :bind (:map hs-minor-mode-map
              ("C-`" . hs-toggle-hiding)))

(use-package imenu
  :ensure nil
  :bind (("C-." . imenu)))

(use-package sudo-edit)

(use-package company
  :diminish
  :hook (after-init . global-company-mode)
  :bind (("M-/" . company-complete)))   

(provide 'init-edit)
