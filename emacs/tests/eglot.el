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
;; unsupported modes, non-file buffers or remote files.  The mapping is a
;; fixed `eglot-server-programs' table so the gate does not depend on which
;; servers Emacs maps by default; nothing below touches Eglot internals.
(let ((eglot-server-programs '(((c-mode c-ts-mode) . ("probe-ls" "--stdio"))))
      (scheduled nil))
  (cl-letf (((symbol-function 'eglot-ensure) (lambda () (setq scheduled t)))
            ((symbol-function 'executable-find) (lambda (_) nil)))
    ;; A mode without a server mapping is skipped silently.
    (with-temp-buffer
      (setq buffer-file-name "/tmp/example.c")
      (my/eglot-ensure)
      (cl-assert (not scheduled))
      (cl-assert (not my/eglot-missing-server)))
    ;; A mapped mode whose server is missing is reported, not connected.
    (with-temp-buffer
      (setq buffer-file-name "/tmp/example.c" major-mode 'c-mode)
      (my/eglot-ensure)
      (cl-assert (not scheduled))
      (cl-assert my/eglot-missing-server))
    (cl-letf (((symbol-function 'executable-find) (lambda (_) "/installed/probe-ls")))
      ;; Installed: connect.
      (with-temp-buffer
        (setq buffer-file-name "/tmp/example.c" major-mode 'c-mode)
        (my/eglot-ensure)
        (cl-assert scheduled))
      ;; Non-file buffers and remote files never connect.
      (dolist (name '(nil "/ssh:example:/tmp/example.c"))
        (setq scheduled nil)
        (with-temp-buffer
          (setq buffer-file-name name major-mode 'c-mode)
          (my/eglot-ensure)
          (cl-assert (not scheduled)))))))

;; A contact written as a function (`eglot-alternatives' makes one) is
;; resolved with INTERACTIVE nil, as Eglot itself does, so an unavailable
;; executable is reported instead of attempted.
(let ((eglot-server-programs
       (list (cons 'ruby-mode (lambda (&optional _) (list "probe-ruby")))))
      (scheduled nil))
  (cl-letf (((symbol-function 'eglot-ensure) (lambda () (setq scheduled t))))
    (cl-letf (((symbol-function 'executable-find) (lambda (_) nil)))
      (with-temp-buffer
        (setq buffer-file-name "/tmp/example.rb" major-mode 'ruby-mode)
        (my/eglot-ensure)
        (cl-assert (not scheduled))
        (cl-assert my/eglot-missing-server)))
    (setq scheduled nil)
    (cl-letf (((symbol-function 'executable-find) (lambda (_) "/installed/probe-ruby")))
      (with-temp-buffer
        (setq buffer-file-name "/tmp/example.rb" major-mode 'ruby-mode)
        (my/eglot-ensure)
        (cl-assert scheduled)))))

;; A contact function that cannot resolve anything is left to Eglot.
(let ((eglot-server-programs
       (list (cons 'ruby-mode (lambda (&optional _) nil))))
      (scheduled nil))
  (cl-letf (((symbol-function 'eglot-ensure) (lambda () (setq scheduled t))))
    (with-temp-buffer
      (setq buffer-file-name "/tmp/example.rb" major-mode 'ruby-mode)
      (my/eglot-ensure)
      (cl-assert scheduled))))

;; `my/eglot-shell-path-setup' adds ~/go/bin to the PATH and retries buffers
;; whose automatic connection was skipped.  It runs from
;; `my/window-ready-hook' at depth 30, after init-env's import at depth 20.
(let ((go-bin (expand-file-name "~/go/bin"))
      (exec-path '("/usr/bin/"))
      (process-environment (cons "PATH=/usr/bin/" process-environment))
      (retried nil))
  (cl-letf (((symbol-function 'file-directory-p) (lambda (d) (equal d go-bin)))
            ((symbol-function 'my/eglot-ensure) (lambda () (setq retried t))))
    (with-temp-buffer
      ;; `setq major-mode' instead of calling the mode function: running a
      ;; real mode would trigger Eglot's own after-change-major-mode hook,
      ;; which asks for the project and has nothing to do with this test.
      (setq buffer-file-name "/tmp/pending.el" major-mode 'emacs-lisp-mode)
      (setq-local my/eglot-missing-server t)
      (my/eglot-shell-path-setup)
      (cl-assert (member go-bin exec-path))
      (cl-assert (equal (getenv "PATH")
                        (concat "/usr/bin/" path-separator go-bin)))
      (cl-assert retried)
      ;; Idempotent: a second run must not add the directory twice.
      (my/eglot-shell-path-setup)
      (cl-assert (= 1 (seq-count (lambda (d) (equal d go-bin)) exec-path))))))

;; clangd is already installed on this host.  No grammar/server downloads.
(unless (executable-find "clangd") (error "Install clangd manually to run the LSP integration check"))
;; Tree-sitter modes are enabled by `treesit-enabled-modes' from
;; `my/after-init-hook', which this test does not run, so `.c' files stay in
;; `c-mode' here and Eglot's `(c-mode c-ts-mode)' entry covers them.
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
        (cl-assert (eq (car completion-at-point-functions) #'tempel-expand))
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
