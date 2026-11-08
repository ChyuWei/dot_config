;;; init.el --- Emacs 31 configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; A small entry point.  The actual configuration is split into modules in
;; lisp/, each one responsible for a single area.

;;; Code:

;; Named startup hooks.  Loaded here, not from early-init: the only hook
;; that would need to be earlier (`before-init-hook') is not wired (see
;; init-hooks.el), so everything this layer relays is triggered after this
;; file has been read.  The guard keeps a second `load init.el' harmless.
(unless (featurep 'init-hooks)
  (load (expand-file-name "init-hooks.el" user-emacs-directory) t t))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'init-packages)     ; archives, use-package, no-littering
(require 'init-env)          ; import shell PATH after window setup
(require 'init-ui)           ; fonts, theme, frame -- before anything that prints
(require 'init-defaults)     ; editing, files, sessions
(require 'init-profile)      ; which keybinding profile is active
(require 'init-evil)         ; Evil declarations, enabled only in the vim profile
(require 'init-completion)   ; vertico, consult, embark, corfu
(require 'init-eglot)        ; installed local language servers, no downloads
(require 'init-markdown)     ; Markdown reading/editing
(require 'init-org)          ; Org reading/capture/agenda
(require 'init-outline)      ; breadcrumbs and outline sidebar
(require 'init-keys)         ; leader table + the active profile's keys
;; Last, and it installs on demand: an application is optional and must never
;; keep the editor from starting (see init-app.el).
(require 'init-app)

(provide 'init)

;;; init.el ends here
