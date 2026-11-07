;;; init.el --- Emacs 31 configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; A small entry point.  The actual configuration is split into modules in
;; lisp/, each one responsible for a single area.

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'init-packages)     ; archives, use-package, no-littering
(require 'init-env)          ; import shell PATH after window setup
(require 'init-defaults)     ; editing, files, sessions
(require 'init-ui)           ; fonts, theme, frame
(require 'init-evil)         ; modal editing, SPC leader
(require 'init-completion)   ; vertico, consult, embark, corfu
(require 'init-eglot)        ; installed local language servers, no downloads
(require 'init-markdown)     ; Markdown reading/editing
(require 'init-org)          ; Org reading/capture/agenda
(require 'init-outline)      ; breadcrumbs and outline sidebar
(require 'init-keys)         ; personal global keys

(provide 'init)

;;; init.el ends here
