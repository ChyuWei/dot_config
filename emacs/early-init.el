;;; early-init.el --- Startup defaults for Emacs 31 -*- lexical-binding: t; -*-

;;; Commentary:

;; Prepare startup performance and the initial frame.
;; Shell paths are imported after window setup by init-env.el.
;; Packages and the remaining UI settings belong to init.el and lisp/.

;;; Code:

;;; Startup and runtime performance ---------------------------------------

;; Use a larger GC budget while loading, then restore the interactive budget.
(setq gc-cons-threshold (* 128 1024 1024)
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1)))

(setq read-process-output-max (* 4 1024 1024)
      ;; init-packages.el activates packages after configuring the archives.
      package-enable-at-startup nil
      native-comp-async-report-warnings-errors 'silent
      native-comp-jit-compilation t
      ;; Prefer edited source over stale bytecode.
      load-prefer-newer t
      ;; Avoid rebuilding large CJK/emoji fontsets.
      inhibit-compacting-font-caches t)

;;; Initial frame ---------------------------------------------------------

(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t
      inhibit-startup-screen t)
(add-to-list 'default-frame-alist '(width . 120))
(add-to-list 'default-frame-alist '(height . 40))

;; Keep the menu bar available while learning Emacs.
(tool-bar-mode -1)
(scroll-bar-mode -1)

(provide 'early-init)

;;; early-init.el ends here
