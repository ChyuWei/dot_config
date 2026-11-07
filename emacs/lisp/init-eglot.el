;;; init-eglot.el --- Local language servers via Eglot -*- lexical-binding: t; -*-

;;; Commentary:

;; Use Emacs' built-in server mappings and installed executables only.
;; Eglot supplies Corfu completion, Xref navigation, Eldoc and Flymake.
;; No server installers, download commands or format-on-save hooks.

;;; Code:

(use-package eglot
  :ensure nil
  :defer t
  :custom
  (eglot-autoshutdown t)
  (eglot-sync-connect 0)
  (eglot-extend-to-xref t))

(defvar-local my/eglot-missing-server nil
  "Non-nil if automatic connection was skipped because no server was found.")

(defun my/eglot-ensure ()
  "Connect a local file buffer only when its language server is installed."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name)))
    (require 'eglot)
    (unless (eglot-managed-p)
      (setq my/eglot-missing-server nil)
      ;; Resolve Eglot's native mode/alternative mappings without prompting
      ;; or launching anything.  This helper is from the required Emacs 31.
      (condition-case err
          (let* ((contact (nth 3 (eglot--guess-contact)))
                 (program (car-safe contact)))
            (when (stringp program)
              (if (executable-find program)
                  (eglot-ensure)
                (setq my/eglot-missing-server t)
                (message "[Eglot] 未启动：找不到 %s，请手动安装语言服务器" program))))
        (error
         (setq my/eglot-missing-server t)
         (message "[Eglot] 未启动：%s" (error-message-string err)))))))

(add-hook 'prog-mode-hook #'my/eglot-ensure)

(provide 'init-eglot)

;;; init-eglot.el ends here
