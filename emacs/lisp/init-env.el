;;; init-env.el --- Shell environment after UI setup -*- lexical-binding: t; -*-

;;; Commentary:

;; Keep shell initialization out of early-init and the initial UI path.
;; window-setup-hook also runs for daemon startup, before serving clients.

;;; Code:

(use-package exec-path-from-shell
  :ensure t
  :commands exec-path-from-shell-initialize
  :custom
  (exec-path-from-shell-variables '("PATH"))
  (exec-path-from-shell-arguments '("-l" "-i"))
  :init
  (add-hook 'window-setup-hook
            (lambda ()
              (redisplay)
              (condition-case err
                  (exec-path-from-shell-initialize)
                (error (message "Shell PATH import failed: %s"
                                (error-message-string err))))
              ;; The shell currently lacks Go's user bin directory.
              (let ((go-bin (expand-file-name "~/go/bin")))
                (when (and (file-directory-p go-bin) (not (member go-bin exec-path)))
                  (setq exec-path (append exec-path (list go-bin)))
                  (setenv "PATH" (concat (or (getenv "PATH") "") path-separator go-bin))))
              ;; Command-line files may have opened before the shell PATH
              ;; became available.  Retry their installed-server check.
              (when (fboundp 'my/eglot-ensure)
                (dolist (buffer (buffer-list))
                  (with-current-buffer buffer
                    (when (and (bound-and-true-p my/eglot-missing-server)
                               buffer-file-name (derived-mode-p 'prog-mode))
                      (my/eglot-ensure))))))))

(provide 'init-env)

;;; init-env.el ends here
