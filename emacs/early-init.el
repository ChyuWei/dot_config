;;; early-init.el --- Early init file -*- lexical-binding: t; -*-

;; defer gc
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.5)
(add-hook 'emacs-startup-hook
          (lambda ()
            "Recover GC"
            (setq gc-cons-threshold #x4000000
                  gc-cons-percentage 0.1)))

;; init package later
(setq package-enable-at-startup nil)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(provide 'early-init)
