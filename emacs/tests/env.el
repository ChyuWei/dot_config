;;; env.el --- Cached shell PATH checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/env.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init" user-emacs-directory))
(load (expand-file-name "init" user-emacs-directory))

;; The package is not loaded at startup: a cache hit never touches it and the
;; command is autoloaded.  Load it here (what the slow path would do) so the
;; stubs below are not overwritten by its own defuns.
(cl-assert (not (featurep 'exec-path-from-shell)))
(cl-assert (autoloadp (symbol-function 'exec-path-from-shell-initialize)))
(require 'exec-path-from-shell)

;; Work in a scratch directory, so the real var/exec-path.el is untouched.
(let* ((dir (make-temp-file "emacs-env-test-" t))
       (cache (expand-file-name "exec-path.el" dir))
       (fake-rc (expand-file-name ".zshrc" dir))
       (my/env-cache-file cache)
       (process-environment (cons "SHELL=/bin/zsh" process-environment))
       (imports 0)
       (native-comp-enable-subr-trampolines nil))
  (cl-letf (((symbol-function 'my/env-shell-files)
             (lambda () (list fake-rc)))
            ((symbol-function 'exec-path-from-shell-getenvs)
             (lambda (names)
               (cl-assert (equal names '("PATH")))
               (cl-assert (equal exec-path-from-shell-arguments '("-l" "-i")))
               (cl-incf imports)
               '(("PATH" . "/shell/bin:/shell tools/bin")))))
    (unwind-protect
        (with-temp-buffer
          ;; 1. No cache: ask the shell once, apply it, write the cache.
          (let ((exec-path '("/inherited/bin")))
            (setenv "PATH" "/inherited/bin")
            (my/init-env-activate)
            (cl-assert (= imports 1))
            (cl-assert (equal (car exec-path) "/shell/bin/"))
            (cl-assert (equal (getenv "PATH") "/shell/bin:/shell tools/bin"))
            (cl-assert (file-exists-p cache))
            (cl-assert (with-temp-buffer
                         (insert-file-contents cache)
                         (string-match-p "my/env-cache-shell-times"
                                         (buffer-string)))))

          ;; 2. Fresh cache: no shell, PATH comes from the file.
          (let ((exec-path '("/inherited/bin")))
            (setenv "PATH" "/inherited/bin")
            (my/init-env-activate)
            (cl-assert (= imports 1))
            (cl-assert (equal (car exec-path) "/shell/bin/"))
            (cl-assert (equal (getenv "PATH") "/shell/bin:/shell tools/bin")))

          ;; 3. A shell startup file changed: re-import.
          (with-temp-file fake-rc (insert "# changed\n"))
          (set-file-times fake-rc (time-add (current-time) 5))
          (let ((exec-path '("/inherited/bin")))
            (my/init-env-activate)
            (cl-assert (= imports 2)))

          ;; 4. A different $SHELL invalidates it too.
          (let ((process-environment (cons "SHELL=/bin/bash" process-environment))
                (exec-path '("/inherited/bin")))
            (my/init-env-activate)
            (cl-assert (= imports 3)))

          ;; 5. `my/env-refresh' always re-imports.
          (let ((exec-path '("/inherited/bin")))
            (my/env-refresh)
            (cl-assert (= imports 4)))

          ;; 6. A failing shell leaves PATH alone and writes no cache.
          (let ((exec-path '("/inherited/bin"))
                (cache-writes 0))
            (setenv "PATH" "/inherited/bin")
            (cl-letf (((symbol-function 'my/env--write-cache)
                       (lambda (&rest _) (cl-incf cache-writes)))
                      ((symbol-function 'exec-path-from-shell-getenvs)
                       (lambda (&rest _) (error "Simulated shell failure"))))
              (cl-assert (not (my/env-refresh)))
              (cl-assert (zerop cache-writes))
              (cl-assert (equal (getenv "PATH") "/inherited/bin")))))
      (delete-directory dir t))))

(princ "PASS: shell PATH cache (fresh, stale, $SHELL change, forced refresh, failure)\n")

;; Temporary proxy: set for this session only, visible to the processes Emacs
;; starts and to Emacs' own HTTP, and undone by `my/proxy-disable'.  Whatever
;; the test environment had before is what comes back.
(let ((before (mapcar (lambda (name) (cons name (getenv name))) my/proxy-env-vars))
      (before-url-proxy url-proxy-services))
  (my/proxy-enable "http://127.0.0.1:7890")
  (dolist (name my/proxy-env-vars)
    (cl-assert (equal (getenv name) "http://127.0.0.1:7890")))
  (cl-assert (equal (with-temp-buffer
                      (call-process "sh" nil t nil "-c" "printf %s \"$https_proxy\"")
                      (buffer-string))
                    "http://127.0.0.1:7890"))
  ;; Emacs' own HTTP reads `url-proxy-services', which wants HOST:PORT.
  (cl-assert (equal url-proxy-services
                    '(("http" . "127.0.0.1:7890") ("https" . "127.0.0.1:7890"))))
  ;; A second enable must not record the proxy itself as the value to restore.
  (my/proxy-enable "http://127.0.0.1:7891")
  (cl-assert (equal (getenv "https_proxy") "http://127.0.0.1:7891"))
  (cl-assert (equal (cdr (assoc "https" url-proxy-services)) "127.0.0.1:7891"))
  (my/proxy-disable)
  (dolist (pair before)
    (cl-assert (equal (getenv (car pair)) (cdr pair))))
  (cl-assert (equal url-proxy-services before-url-proxy))
  ;; With nothing enabled by us, "off" means clear: that is the only way to get
  ;; rid of a proxy that came from the shell.
  (setenv "https_proxy" "http://127.0.0.1:7892")
  (setq url-proxy-services '(("https" . "127.0.0.1:7892")))
  (my/proxy-disable)
  (dolist (name my/proxy-env-vars)
    (cl-assert (null (getenv name))))
  (cl-assert (null url-proxy-services))
  ;; A scheme-less URL works too.
  (my/proxy-enable "127.0.0.1:7893")
  (cl-assert (equal (cdr (assoc "http" url-proxy-services)) "127.0.0.1:7893"))
  (my/proxy-disable)
  ;; Leave the environment as the rest of the suite found it.
  (dolist (pair before)
    (setenv (car pair) (cdr pair)))
  (setq url-proxy-services before-url-proxy))

(princ "PASS: temporary proxy on/off, restored and visible to subprocesses\n")
