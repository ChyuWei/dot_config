;;; eglot.el --- Installed-server gates and real LSP checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/eglot.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))
(require 'eglot)

;; No process or connection should be attempted for missing executables,
;; unsupported modes, non-file buffers or remote files.
(let (scheduled)
  (cl-letf (((symbol-function 'eglot--guess-contact)
             (lambda (&rest _) '(nil nil nil ("missing-language-server"))))
            ((symbol-function 'eglot-ensure) (lambda () (setq scheduled t)))
            ((symbol-function 'executable-find) (lambda (_) nil)))
    (with-temp-buffer
      (setq buffer-file-name "/tmp/example.c")
      (my/eglot-ensure)
      (cl-assert (not scheduled)))
    (cl-letf (((symbol-function 'executable-find) (lambda (_) "/installed/server")))
      (with-temp-buffer
        (my/eglot-ensure)
        (cl-assert (not scheduled))
        (setq buffer-file-name "/ssh:example:/tmp/example.c")
        (my/eglot-ensure)
        (cl-assert (not scheduled))
        (setq buffer-file-name "/tmp/example.c")
        (my/eglot-ensure)
        (cl-assert scheduled)))))

;; clangd is already installed on this host.  No grammar/server downloads.
(unless (executable-find "clangd") (error "Install clangd manually to run the LSP integration check"))
(global-treesit-auto-mode -1)
(let* ((directory (make-temp-file "eglot-regression-" t))
       (default-directory (file-name-as-directory directory))
       (file (expand-file-name "main.c" directory))
       (eglot-sync-connect 0)
       (eglot-connect-timeout 5)
       (eglot-server-programs
        '(((c-mode c-ts-mode) . ("clangd" "--background-index=0"))))
       buffer server)
  (unwind-protect
      (progn
        (with-temp-file file
          (insert "int add(int a,int b){return a+b;}\nint main(void){return add(\"bad\",2);}\n"))
        (setq buffer (find-file-noselect file))
        (switch-to-buffer buffer)
        (cl-assert (eq major-mode 'c-mode))
        (run-hooks 'post-command-hook)
        (let ((deadline (+ (float-time) 5)))
          (while (and (not (eglot-managed-p)) (< (float-time) deadline))
            (accept-process-output nil 0.05)))
        (cl-assert (eglot-managed-p))
        (setq server (eglot-current-server))
        (cl-assert (jsonrpc-running-p server))
        (cl-assert flymake-mode)
        (cl-assert (memq #'eglot-completion-at-point completion-at-point-functions))
        (goto-char (point-max))
        (search-backward "add")
        (let* ((definitions (xref-backend-definitions 'eglot "add"))
               (marker (xref-location-marker (xref-item-location (car definitions)))))
          (cl-assert (equal (buffer-file-name (marker-buffer marker)) file))
          (cl-assert (= (with-current-buffer (marker-buffer marker)
                          (line-number-at-pos marker)) 1)))
        (let* ((completion (eglot-completion-at-point))
               (candidates (all-completions "ad" (nth 2 completion))))
          (cl-assert (cl-some (lambda (candidate) (string-prefix-p "add" candidate)) candidates)))
        (flymake-start)
        (let ((deadline (+ (float-time) 5)))
          (while (and (null (flymake-diagnostics)) (< (float-time) deadline))
            (accept-process-output nil 0.05)))
        (cl-assert (flymake-diagnostics))
        (eglot-rename "sum")
        (cl-assert (string-match-p "int sum(" (buffer-string)))
        (cl-assert (string-match-p "return sum(" (buffer-string)))
        (eglot-format)
        (cl-assert (string-match-p "int sum(int a, int b)" (buffer-string))))
    (when server (ignore-errors (eglot-shutdown server)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer (set-buffer-modified-p nil))
      (kill-buffer buffer))
    (delete-directory directory t)))

(princ "PASS: installed-server gate, remote/non-file skip, real clangd connection, completion, diagnostics, definition, rename and format\n")
