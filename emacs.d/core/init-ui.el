;;; init-ui.el --- ui configurations -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(use-package doom-themes
  :ensure t
  :init 
  (load-theme 'doom-one t)
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(use-package doom-modeline
  :ensure t
  :custom
  (doom-modeline-minor-modes t)
  (doom-modeline-unicode-fallback t)
  :hook (after-init . doom-modeline-mode))

(use-package default-text-scale
  :ensure t
  :hook (after-init . default-text-scale-mode)
  :bind (:map default-text-scale-mode-map
         ("C-=" . default-text-scale-increase)
         ("C--" . default-text-scale-decrease)))

(setq use-file-dialog nil
      use-dialog-box nil
      inhibit-startup-screen t
      inhibit-startup-echo-area-message t)

(provide 'init-ui)
;;; init-ui.el ends here
