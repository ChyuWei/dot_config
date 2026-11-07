;;; packages.el --- Package startup regression checks -*- lexical-binding: t; -*-

;; Run from the repository root; network and installation are stubbed:
;; emacs -Q --batch -l emacs/tests/packages.el
(require 'cl-lib)
(require 'package)
(require 'use-package)
(require 'use-package-ensure)
;; Stand in for the package; this test covers bootstrap, not its internals.
(provide 'no-littering)

(defconst my/test-packages-file
  (or (getenv "EMACS_PACKAGES_TEST_FILE")
      (expand-file-name "../lisp/init-packages.el" (file-name-directory load-file-name))))
(defvar my/elpa-mirror)

;; Cover both mirrors, fallback, a missing index and an unavailable mirror.
(dolist (scenario '(("tuna" "tuna.tsinghua.edu.cn" cached)
                    ("ustc" "ustc.edu.cn" cached)
                    ("unknown" "tuna.tsinghua.edu.cn" cached)
                    ("tuna" "tuna.tsinghua.edu.cn" empty)
                    ("tuna" "tuna.tsinghua.edu.cn" offline)
                    ("tuna" "tuna.tsinghua.edu.cn" quickstart)))
  (let ((my/elpa-mirror (nth 0 scenario))
        (package-archive-contents (when (eq (nth 2 scenario) 'cached) '(cached)))
        (user-emacs-directory (make-temp-file "emacs-packages-test-" t))
        (package--initialized nil)
        (initialization-count 0)
        (activation-count 0)
        (refresh-count 0)
        ensured)
    (unwind-protect
        (progn
          (when (eq (nth 2 scenario) 'quickstart)
            (make-directory (expand-file-name "var" user-emacs-directory))
            (with-temp-file (expand-file-name "var/package-quickstart.el" user-emacs-directory)))
          (cl-letf (((symbol-function 'package-initialize)
                     (lambda (&rest _)
                       (cl-incf initialization-count)
                       (setq package--initialized t)))
                    ((symbol-function 'package-activate-all)
                     (lambda () (cl-incf activation-count)))
                    ((symbol-function 'package-installed-p) (lambda (&rest _) t))
                    ((symbol-function 'package-refresh-contents)
                     (lambda ()
                       (cl-incf refresh-count)
                       (when (eq (nth 2 scenario) 'offline)
			 (error "Simulated unavailable mirror"))))
                    ((symbol-function 'use-package-ensure-elpa)
                     (lambda (name &rest _)
                       (push name ensured)
                       (when (eq (nth 2 scenario) 'offline)
			 (error "Simulated failed installation"))
                       t)))
            (load my/test-packages-file nil t)
            (cl-assert (= refresh-count
                          (if (memq (nth 2 scenario) '(cached quickstart)) 0 1)))
            (cl-assert (= initialization-count (if (eq (nth 2 scenario) 'quickstart) 0 1)))
            (cl-assert (= activation-count (if (eq (nth 2 scenario) 'quickstart) 1 0)))
            (cl-assert (member 'no-littering ensured))
            (when (eq (nth 2 scenario) 'quickstart)
              ;; Missing packages must restore full metadata before installation.
              (cl-letf (((symbol-function 'package-installed-p) (lambda (&rest _) nil)))
		(funcall use-package-ensure-function 'missing '(t) nil)
		(cl-assert (= initialization-count 1))))
            (cl-assert (equal package-archive-priorities
                              '(("gnu" . 30) ("nongnu" . 20) ("melpa" . 10))))
            (dolist (archive '("gnu" "nongnu" "melpa"))
              (cl-assert
               (equal (cdr (assoc archive package-archives))
                      (format "https://mirrors.%s/elpa/%s/"
                              (nth 1 scenario) archive))))
            (cl-assert (equal custom-file
                              (expand-file-name "custom.el" user-emacs-directory)))
            ;; The ensure callback forwards all arguments and the return value.
            (cl-letf (((symbol-function 'use-package-ensure-elpa)
                       (lambda (&rest args) args)))
              (cl-assert (equal (funcall use-package-ensure-function 'demo '(t) '(state) t)
				'(demo (t) (state) t))))))
      (delete-directory user-emacs-directory t))))

(princ "PASS: mirrors, archive priorities, refresh policy, offline startup and ensure callback\n")
