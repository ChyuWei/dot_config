;;; modes.el --- Document, outline and completion checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/modes.el
;; EMACS_MODE_SNAPSHOT=/tmp/modes.el also writes a behavior snapshot.
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))

(let (snapshot)
  (dolist (mode '(org-mode markdown-mode markdown-ts-mode))
    (with-temp-buffer
      (insert (if (eq mode 'org-mode)
                  "* Parent\nBody\n** Child\nText\n"
                "# Parent\nBody\n## Child\nText\n"))
      (funcall mode)
      (font-lock-ensure)
      ;; Check actual fontification and face heights, not only enabled modes.
      (let ((prefix (pcase mode
                      ('org-mode "org-level-")
                      ('markdown-mode "markdown-header-face-")
                      ('markdown-ts-mode "markdown-ts-heading-"))))
        (cl-loop for height in '(2.0 1.7 1.4 1.1 1.0 1.0)
                 for level from 1
                 do (cl-assert (= (face-attribute
                                  (intern (format "%s%d" prefix level)) :height)
                                 height)))
        (goto-char (point-min))
        (search-forward "Parent")
        (cl-assert (memq (intern (concat prefix "1"))
                         (ensure-list (get-text-property (1- (point)) 'face)))))
      (cl-assert visual-line-mode)
      (cl-assert olivetti-mode)
      (cl-assert valign-mode)
      (cl-assert (not word-wrap))
      (cl-assert (not display-line-numbers-mode))
      (cl-assert (memq 'cape-dabbrev completion-at-point-functions))
      (cl-assert breadcrumb-local-mode)
      (cl-assert (= (cl-count '(:eval (my/reading-progress)) mode-line-misc-info :test #'equal) 1))
      (when (eq mode 'org-mode)
        (cl-assert org-modern-mode)
        (cl-assert org-appear-mode))
      (when (eq mode 'markdown-ts-mode)
        (cl-assert markdown-ts-appear-mode)
        (evil-local-mode 1)
        (evil-normal-state)
        (evil-insert-state)
        (evil-normal-state))
      (push (list mode
                  (mapcar (lambda (variable)
                            (cons variable (and (boundp variable) (symbol-value variable))))
                          '(visual-line-mode olivetti-mode valign-mode word-wrap
                            display-line-numbers-mode breadcrumb-local-mode
                            org-modern-mode org-appear-mode markdown-ts-appear-mode
                            completion-at-point-functions)))
            snapshot)))
  (with-temp-buffer
    (emacs-lisp-mode)
    (cl-assert electric-pair-mode)
    (cl-assert hl-line-mode)
    (cl-assert (memq 'cape-dabbrev completion-at-point-functions)))
  ;; Synthetic Imenu bookkeeping must disappear without mutating the input.
  (let* ((input '(("Parent" ("." . 1) ("Child" . 2))
                  ("Parent" . 1) ("-" ("Leaf" . 3)) ("End" . 4)))
         (copy (copy-tree input))
         (clean (my/imenu-clean-tree input)))
    (cl-assert (equal clean '(("Parent" ("Child" . 2)) ("Leaf" . 3) ("End" . 4))))
    (cl-assert (equal input copy))
    (push clean snapshot))
  (cl-assert
   (equal (my/consult-imenu-drop-pseudo
           (lambda () '(("Parent ." . 1) ("." . 2) ("Child" . 3))))
          '(("Child" . 3))))
  (require 'corfu-auto)
  (require 'consult)
  (require 'embark)
  (require 'imenu-list)
  (dolist (variable '(completion-styles completion-category-overrides consult-preview-key
                     consult-narrow-key prefix-help-command corfu-auto corfu-auto-delay
                     corfu-auto-prefix corfu-cycle corfu-preselect corfu-on-exact-match
                     corfu-quit-no-match corfu-popupinfo-delay org-capture-templates
                     org-babel-load-languages org-refile-targets org-export-backends
                     org-imenu-depth org-confirm-babel-evaluate org-babel-python-command
                     imenu-list-position imenu-list-size imenu-list-auto-update
                     breadcrumb-imenu-max-length breadcrumb-imenu-crumb-separator))
    (push (cons variable (symbol-value variable)) snapshot))
  (dolist (key '("zo" "zO" "zc" "za" "zr" "zm" "C-a"))
    (push (cons key (lookup-key evil-normal-state-map key)) snapshot))
  (when-let* ((file (getenv "EMACS_MODE_SNAPSHOT")))
    (with-temp-file file
      (let ((print-length nil) (print-level nil))
        (prin1 snapshot (current-buffer))))))
;; Exercise the actual right outline window and heading navigation.
(let ((buffer (generate-new-buffer "outline-regression.org")))
  (unwind-protect
      (progn
        (switch-to-buffer buffer)
        (insert "* Parent\nBody\n** Child\nText\n")
        (org-mode)
        (goto-char (point-min))
        (imenu-list-smart-toggle)
        (imenu-list-update t)
        (let ((window (get-buffer-window imenu-list-buffer-name)))
          (cl-assert (window-live-p window))
          (select-window window)
          (goto-char (point-min))
          (search-forward "Child")
          (imenu-list-goto-entry)
          (cl-assert (eq (current-buffer) buffer))
          (cl-assert (looking-at "\\*\\* Child")))
        (imenu-list-smart-toggle)
        (cl-assert (null (get-buffer-window imenu-list-buffer-name))))
    (imenu-list-minor-mode -1)
    (with-current-buffer buffer (set-buffer-modified-p nil))
    (kill-buffer buffer)))
(princ "PASS: Org/Markdown reading, completion, outline navigation and Evil bindings\n")
