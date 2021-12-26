;;; init-core.el --- Core Package and Config -*- lexical-binding: t; -*-

;; init package.el
(setq package-archives
      '(("gnu" . "https://mirrors.sjtug.sjtu.edu.cn/emacs-elpa/gnu/")
        ("melpa" . "https://mirrors.sjtug.sjtu.edu.cn/emacs-elpa/melpa/")))

(require 'package)
(unless (bound-and-true-p package--initialized)
  (package-initialize))

;; init use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(use-package server
  :hook (after-init . server-mode))

(use-package diminish :ensure t)

(use-package ivy
  :ensure t
  :diminish ivy-mode
  :hook (after-init . ivy-mode))

(fset 'yes-or-no-p 'y-or-n-p)
(setq visible-bell nil
      inhibit-compacting-font-caches t
      delete-by-moving-to-trash t
      make-backup-files nil
      auto-save-default nil)

(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message t
      inhibit-default-init t
      initial-major-mode 'fundamental-mode
      initial-scratch-message nil)

(setq frame-resize-pixelwise t
      window-resize-pixelwise nil)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

(setq use-dialog-box nil)

(provide 'init-core)
