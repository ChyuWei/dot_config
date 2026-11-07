;;; ui.el --- UI regression checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/ui.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))

;; Exercise the graphical setup without requiring a graphical batch frame.
(let ((native-comp-enable-subr-trampolines nil)
      (my-fonts-configured nil)
      calls)
  (cl-letf (((symbol-function 'display-graphic-p) (lambda (&rest _) nil)))
    (my/setup-fonts)
    (cl-assert (not my-fonts-configured)))
  (cl-letf (((symbol-function 'display-graphic-p) (lambda (&rest _) t))
            ((symbol-function 'set-face-attribute)
             (lambda (&rest args) (push (cons 'face args) calls)))
            ((symbol-function 'set-fontset-font)
             (lambda (&rest args) (push (cons 'fontset args) calls))))
    (my/setup-fonts)
    (cl-assert my-fonts-configured)
    (cl-assert (= (length calls) 10))
    (cl-assert (member '(face default nil :family "JetBrains Mono" :height 160) calls))
    (cl-assert (member '(face fixed-pitch nil :family "JetBrains Mono" :height 1.0) calls))
    (cl-assert (member '(face variable-pitch nil :family "JetBrains Mono" :height 1.0) calls))
    (dolist (script '(han cjk-misc))
      (cl-assert (member (list 'fontset t script (font-spec :family "LXGW WenKai")) calls))
      (cl-assert (member (list 'fontset t script (font-spec :family "PingFang SC") nil 'append) calls)))
    (my/setup-fonts)
    (cl-assert (= (length calls) 10))))

(with-temp-buffer
  (insert (make-string 100 ?x))
  (goto-char 50)
  (cl-assert (equal (my/reading-progress) "▓▓▓▓░░░░ 50%"))
  (my/prose-progress-modeline)
  (let ((format (copy-tree mode-line-misc-info)))
    (my/prose-progress-modeline)
    (cl-assert (equal format mode-line-misc-info)))
  (cl-assert (= (cl-count '(:eval (my/reading-progress)) mode-line-misc-info :test #'equal) 1)))

(require 'org)
(dolist (face '(org-block org-block-begin-line org-block-end-line))
  (cl-assert (equal (face-attribute face :background) "#ebdbb2"))
  (cl-assert (eq (face-attribute face :extend) t)))
(cl-assert (memq 'gruvbox-light-soft custom-enabled-themes))
(cl-assert (equal frame-title-format "%b — Emacs"))
(cl-assert (equal (alist-get 'internal-border-width default-frame-alist) 12))
(princ "PASS: font setup, reading progress, Org faces, theme and frame defaults\n")
