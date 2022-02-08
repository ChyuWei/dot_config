;;; init-core.el --- Core Package and Config -*- lexical-binding: t; -*-

;; init package.el
(setq package-archives
      '(("gnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
        ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))

(setq package-user-dir
      (expand-file-name (format "elpa-%s.%s" emacs-major-version emacs-minor-version)
                        user-emacs-directory))

(unless (bound-and-true-p package--initialized)
  (package-initialize))

;; init use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-and-compile
  (setq use-package-always-ensure t)
  (setq use-package-always-defer t)
  (setq use-package-expand-minimally t))

(eval-when-compile
  (require 'use-package))

(use-package diminish)
(use-package bind-key)

(use-package gnu-elpa-keyring-update)


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

(use-package gcmh
  :diminish
  :init (gcmh-mode 1))

(use-package server
  :ensure nil
  :hook (after-init . server-mode))

(use-package simple
  :ensure nil
  :hook ((after-init . size-indication-mode)
	 (text-mode . visual-line-mode))
  :init
  (setq column-number-mode t
	line-number-mode t))

(use-package time
  :ensure nil
  :init (setq display-time-24hr-format t
	      display-time-day-and-date t))

(fset 'yes-or-no-p 'y-or-n-p)

(setq visible-bell t
      inhibit-compacting-font-caches t
      delete-by-moving-to-trash t
      make-backup-files nil
      auto-save-default nil)

(provide 'init-core)
