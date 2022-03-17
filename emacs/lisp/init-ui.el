(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message t
      inhibit-default-init t
      initial-scratch-message nil)

(blink-cursor-mode -1)

(setq frame-resize-pixelwise t
      window-resize-pixelwise nil)

(use-package hl-line
  :hook (after-init . global-hl-line-mode))

(show-paren-mode 1)

(set-face-attribute 'default nil :font "Monaco")

(provide 'init-ui)
