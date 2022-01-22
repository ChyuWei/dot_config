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

(use-package gcmh
  :ensure t
  :diminish
  :init
  (setq gcmh-idle-delay 5
        gcmh-high-cons-threshold #x1000000)
  (gcmh-mode 1))

(use-package server
  :hook (after-init . server-mode))

;; encoding
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
(set-language-environment 'utf-8)
(set-default-coding-systems 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(set-file-name-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)

(provide 'init-core)
