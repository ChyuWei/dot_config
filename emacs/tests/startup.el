;;; startup.el --- Startup timing and lazy command checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/startup.el
;; Timings cover configuration and startup hooks, not GUI frame creation.
;; Probes: startup must leave document options alone.  Their :config
;; should apply the configured values only when the corresponding library loads.
(setq org-imenu-depth 3
      markdown-max-image-size '(111 . 222))

(let ((start (current-time)))
  (setq user-emacs-directory
        (file-name-directory
         (directory-file-name (file-name-directory load-file-name))))
  (load (expand-file-name "early-init" user-emacs-directory))
  (load (expand-file-name "init" user-emacs-directory))
  (let ((init-seconds (float-time (time-subtract (current-time) start))))
    ;; Native startup hooks drive our relays; the idle timer needs a nudge in
    ;; batch mode, where Emacs never goes idle.
    (run-hooks 'after-init-hook 'emacs-startup-hook 'window-setup-hook)
    (my/init-run-hook-once 'my/idle-hook)
    (let ((ready-seconds (float-time (time-subtract (current-time) start))))
      (unless (and evil-mode which-key-mode vertico-mode global-corfu-mode
                   doom-modeline-mode global-diff-hl-mode)
        (error "A startup mode is disabled"))
      (unless (and (= org-imenu-depth 3)
                   (equal markdown-max-image-size '(111 . 222)))
        (error "Document settings were applied before their library loaded"))
      (dolist (feature '(eglot ol indent-bars rainbow-delimiters symbol-overlay
                        tempel tempel-collection dsh-emacs org markdown-mode markdown-ts-mode
                        org-appear org-tree-slide markdown-ts-appear))
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
