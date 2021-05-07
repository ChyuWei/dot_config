;;; init-core.el --- Core Package and Config -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:
(require 'init-custom)

;; init package.el
(require 'package)
(setq package-archives myself/package-archives)
(unless (bound-and-true-p package--initialized)
  (package-initialize))

;; init use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-and-compile
  (setq use-package-always-ensure nil)
  (setq use-package-always-defer nil)
  (setq use-package-expand-minimally t))

(eval-when-compile
  (require 'use-package))
(use-package diminish :ensure t)
(use-package bind-key :ensure t)

(use-package exec-path-from-shell
  :ensure t
  :init
  (setq exec-path-from-shell-variables '("PATH"))
  (exec-path-from-shell-initialize))

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

;; misc
(fset 'yes-or-no-p 'y-or-n-p)
(setq visible-bell t
      inhibit-compacting-font-caches t
      delete-by-moving-to-trash t
      make-backup-files nil
      auto-save-default nil)

(provide 'init-core)
;;; init-core.el ends here
