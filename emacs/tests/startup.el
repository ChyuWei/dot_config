;;; startup.el --- Startup timing and lazy command checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/startup.el
;; Timings cover configuration and startup hooks, not GUI frame creation.
(let ((start (current-time)))
  (setq user-emacs-directory
        (file-name-directory
         (directory-file-name (file-name-directory load-file-name))))
  (load (expand-file-name "early-init" user-emacs-directory))
  (load (expand-file-name "init" user-emacs-directory))
  (let ((init-seconds (float-time (time-subtract (current-time) start))))
    (run-hooks 'after-init-hook 'emacs-startup-hook 'window-setup-hook)
    (let ((ready-seconds (float-time (time-subtract (current-time) start))))
      (unless (and evil-mode which-key-mode vertico-mode global-corfu-mode
                   doom-modeline-mode global-diff-hl-mode)
        (error "A startup mode is disabled"))
      (dolist (feature '(eglot ol))
        (when (featurep feature)
          (error "Unnecessary eager load: %S" feature)))
      (dolist (entry '((eglot-code-actions . eglot)
                       (eglot-format . eglot)
                       (eglot-rename . eglot)
                       (flymake-goto-prev-error . flymake)
                       (flymake-goto-next-error . flymake)
                       (flymake-show-buffer-diagnostics . flymake)
                       (org-store-link . ol)))
        (let ((command (car entry)))
          (unless (commandp command)
            (error "Command unavailable before first use: %S" command))
          ;; Exercise command autoloading without needing a language server.
          (when (autoloadp (symbol-function command))
            (autoload-do-load (symbol-function command) command))
          (unless (and (featurep (cdr entry))
                       (commandp command)
                       (not (autoloadp (symbol-function command))))
            (error "First-use autoload failed: %S" command))))
      (princ (format "PASS: startup modes and first-use commands; init=%.3fs ready=%.3fs\n"
                     init-seconds ready-seconds)))))
