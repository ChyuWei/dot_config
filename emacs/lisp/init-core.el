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

(provide 'init-core)
