;;; env.el --- Deferred shell environment checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/env.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init" user-emacs-directory))
(load (expand-file-name "init" user-emacs-directory))
(cl-assert (not (featurep 'exec-path-from-shell)))
(cl-assert (autoloadp (symbol-function 'exec-path-from-shell-initialize)))
(require 'exec-path-from-shell)

(dolist (fail '(nil t))
  (let ((process-environment (copy-sequence process-environment))
        (exec-path '("/inherited/bin"))
        (native-comp-enable-subr-trampolines nil)
        (go-bin (expand-file-name "~/go/bin"))
        imported retried)
    (setenv "PATH" "/inherited/bin")
    (cl-letf (((symbol-function 'exec-path-from-shell-getenvs)
               (lambda (names)
                 (cl-assert (equal names '("PATH")))
                 (cl-assert (equal exec-path-from-shell-arguments '("-l" "-i")))
                 (setq imported t)
                 (when fail (error "Simulated shell failure"))
                 '(("PATH" . "/shell/bin:/shell tools/bin"))))
              ((symbol-function 'file-directory-p) (lambda (dir) (equal dir go-bin)))
              ((symbol-function 'my/eglot-ensure)
               (lambda () (setq retried t))))
      (with-temp-buffer
        (setq buffer-file-name "/tmp/environment-check.el")
        (emacs-lisp-mode)
        (setq retried nil)
        (setq-local my/eglot-missing-server t)
        (cl-assert (not imported))
        (run-hooks 'window-setup-hook)
        (cl-assert imported)
        (cl-assert retried)
        (cl-assert (member go-bin exec-path))
        (cl-assert (equal (getenv "PATH")
                          (concat (if fail "/inherited/bin" "/shell/bin:/shell tools/bin")
                                  path-separator go-bin)))
        (unless fail
          (cl-assert (equal (car exec-path) "/shell/bin/")))))))

(princ "PASS: lazy package load, post-UI PATH import, fallback, Go supplement and Eglot retry\n")
