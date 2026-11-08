;;; early-init.el --- Early startup regression checks -*- lexical-binding: t; -*-

;; Run from the repository root:
;; emacs -Q --batch -l emacs/tests/early-init.el
(require 'cl-lib)
(defconst my/test-early-init-file
  (expand-file-name "../early-init.el" (file-name-directory load-file-name)))
(load my/test-early-init-file)

;; Early init must not run the shell or change the inherited PATH.
(let ((native-comp-enable-subr-trampolines nil)
      (exec-path '("/inherited/bin"))
      (process-environment (copy-sequence process-environment)))
  (setenv "PATH" "/inherited/bin")
  (cl-letf (((symbol-function 'call-process)
             (lambda (&rest _) (error "Shell started before UI setup"))))
    (load my/test-early-init-file nil t))
  (cl-assert (equal exec-path '("/inherited/bin")))
  (cl-assert (equal (getenv "PATH") "/inherited/bin")))

(cl-assert (= gc-cons-threshold (* 128 1024 1024)))
(cl-assert (= gc-cons-percentage 0.6))
(let ((gc-cons-threshold gc-cons-threshold)
      (gc-cons-percentage gc-cons-percentage))
  (run-hooks 'emacs-startup-hook)
  (cl-assert (= gc-cons-threshold (* 32 1024 1024)))
  (cl-assert (= gc-cons-percentage 0.1)))
(cl-assert (null package-enable-at-startup))
(cl-assert (= (alist-get 'width default-frame-alist) 120))
(cl-assert (= (alist-get 'height default-frame-alist) 40))
(cl-assert (not tool-bar-mode))
(cl-assert (not scroll-bar-mode))

;; `load' asks `my/load-path-filter' where to look first; the directory that
;; served a file last time must come up front, with the rest kept as fallback.
(cl-assert (eq load-path-filter-function #'my/load-path-filter))
(cl-assert (memq 'my/load-path--remember after-load-functions))
(let ((path '("/a/" "/b/" "/c/")))
  (cl-assert (equal path (my/load-path-filter path "nothing-known" '(".elc" ".el"))))
  (cl-assert (equal path (my/load-path-filter path "known" '(".elc" ".el")))))
(puthash "my-known-lib.elc" "/c/" my/load-path--directories)
(cl-assert (equal '("/c/" "/a/" "/b/")
                  (my/load-path-filter '("/a/" "/b/" "/c/") "my-known-lib" '(".elc" ".el"))))
;; A remembered directory that is no longer on `load-path' must be ignored.
(puthash "my-gone-lib.el" "/nowhere/" my/load-path--directories)
(cl-assert (equal '("/a/" "/b/")
                  (my/load-path-filter '("/a/" "/b/") "my-gone-lib" '(".elc" ".el"))))
;; `after-load-functions' records where a file came from.
(my/load-path--remember "/tmp/somewhere/thing.el")
(cl-assert (equal "/tmp/somewhere/" (gethash "thing.el" my/load-path--directories)))
(my/load-path--remember nil)            ; must not signal

(princ "PASS: no early shell execution, GC lifecycle, frame defaults and load-path filter\n")
