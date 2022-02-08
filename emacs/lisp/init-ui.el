(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message t
      inhibit-default-init t
      initial-scratch-message nil)

(blink-cursor-mode -1)

(setq frame-resize-pixelwise t
      window-resize-pixelwise nil)

(use-package hl-line
  :ensure nil
  :hook (after-init . global-hl-line-mode))

(show-paren-mode 1)

(provide 'init-ui)
