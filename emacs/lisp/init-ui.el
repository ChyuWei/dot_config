(setq visible-bell nil
      inhibit-compacting-font-caches t
      delete-by-moving-to-trash t
      make-backup-files nil
      auto-save-default nil)

(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message t
      inhibit-default-init t
      initial-scratch-message nil)

(blink-cursor-mode -1)

(setq frame-resize-pixelwise t
      window-resize-pixelwise nil)

(line-number-mode t)
(column-number-mode t)

(show-paren-mode 1)

;; misc
(fset 'yes-or-no-p 'y-or-n-p)
(setq ring-bell-function 'ignore)

(provide 'init-ui)
