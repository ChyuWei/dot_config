;;; ui.el --- UI regression checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/ui.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))

;; Test the shipped source, not a byte/native-compiled copy: natively
;; compiled code calls `set-fontset-font' directly, which the `cl-letf'
;; stubs below cannot intercept (the count silently drops to the calls
;; made through `apply').  Reloading init-ui.el from source keeps this
;; check meaningful whether or not the config was built.
(load (expand-file-name "lisp/init-ui.el" user-emacs-directory) nil 'nomessage)

;; Exercise the graphical setup without requiring a graphical batch frame.
(let ((native-comp-enable-subr-trampolines nil)
      (my/fonts-configured-p nil)
      calls)
  (cl-letf (((symbol-function 'display-graphic-p) (lambda (&rest _) nil)))
    (my/setup-fonts)
    (cl-assert (not my/fonts-configured-p)))
  (cl-letf (((symbol-function 'display-graphic-p) (lambda (&rest _) t))
            ((symbol-function 'set-face-attribute)
             (lambda (&rest args) (push (cons 'face args) calls)))
            ((symbol-function 'set-fontset-font)
             (lambda (&rest args) (push (cons 'fontset args) calls))))
    (my/setup-fonts)
    (cl-assert my/fonts-configured-p)
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

;; The mode line shows which keybinding profile is active.
(require 'doom-modeline)
(cl-assert (not doom-modeline-enable-word-count))
(cl-assert (not (memq 'word-count (car (alist-get 'main doom-modeline--modelines)))))
(cl-assert (not (fboundp 'my/word-count-setup)))
(cl-assert (commandp 'count-words))
(unless (memq 'my/keybinding-profile
              (car (alist-get 'main doom-modeline--modelines)))
  (error "Keybinding profile segment is missing from the mode line"))

(let ((segment (lambda ()
                 (string-trim
                  (substring-no-properties
                   (doom-modeline-segment--my/keybinding-profile))))))
  (my/apply-keybinding-profile 'vim)
  (unless (equal (funcall segment) "VIM")
    (error "Mode line should read VIM, got %S" (funcall segment)))
  (my/apply-keybinding-profile 'emacs)
  (unless (equal (funcall segment) "EMACS")
    (error "Mode line should read EMACS, got %S" (funcall segment)))
  (my/apply-keybinding-profile 'vim))

;; The built-in theme is loaded from early-init, before any package, so the
;; first frame is already drawn with it.  Org block faces are left to the
;; theme (they report `unspecified' in batch, where no frame exists).
(cl-assert (memq 'modus-operandi custom-enabled-themes))
(cl-assert (custom-theme-enabled-p 'modus-operandi))
(cl-assert (equal frame-title-format "%b — Emacs"))
(princ "PASS: font setup, reading progress, profile indicator, Org faces, theme and frame defaults\n")
