;;; defaults.el --- Defaults and real sidebar regression checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/defaults.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))

(let* ((directory (make-temp-file "emacs-sidebar-test-" t))
       (file (expand-file-name "example.txt" directory))
       (other-file (expand-file-name "second.txt" directory))
       (other-sidebar (get-buffer-create " *other-sidebar-test*")))
  (unwind-protect
      (progn
        (with-temp-file file (insert "Sidebar opening test\n"))
        (with-temp-file other-file (insert "Sidebar follow test\n"))
        (find-file file)
        (let* ((editing-window (selected-window))
               (unrelated-window
                (display-buffer-in-side-window
                 other-sidebar '((side . left) (slot . 1)))))
          (my/dirvish-side)
          (let ((tree (dirvish-side--session-visible-p)))
            (cl-assert (window-live-p tree))
            (cl-assert (not (eq tree unrelated-window)))
            (cl-assert dirvish-side-follow-mode)
            (cl-assert dirvish-override-dired-mode)
            (cl-assert (not display-line-numbers-mode))
            ;; Open an actual file from the tree into an editing window.
            (dired-goto-file file)
            ;; Batch Emacs has no redisplay loop to initialize the index.
            (dirvish-pre-redisplay-h tree)
            (dired-find-file)
            (cl-assert (equal buffer-file-name file))
            (cl-assert (not (eq (selected-window) tree)))
            (cl-assert (window-live-p tree))
            ;; Follow another file, then close from the editing window.
            (find-file other-file)
            (dirvish-side--auto-jump)
            (with-selected-window tree
              (cl-assert (equal (dired-get-filename) other-file)))
            (my/dirvish-side)
            (cl-assert (null (dirvish-side--session-visible-p)))
            (cl-assert (window-live-p unrelated-window))
            ;; Reopen and close while the tree itself has focus.
            (select-window editing-window)
            (my/dirvish-side)
            (cl-assert (eq (selected-window) (dirvish-side--session-visible-p)))
            (my/dirvish-side)
            (cl-assert (null (dirvish-side--session-visible-p)))
            (cl-assert (window-live-p unrelated-window)))))
    (dolist (window (window-list))
      (when (window-parameter window 'window-side) (delete-window window)))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (or (eq buffer other-sidebar)
                  (and buffer-file-name (file-in-directory-p buffer-file-name directory))
                  (and (derived-mode-p 'dired-mode)
                       (file-in-directory-p default-directory directory)))
          (set-buffer-modified-p nil)
          (kill-buffer buffer))))
    (delete-directory directory t)))

(princ "PASS: real sidebar open/close, file opening, follow and unrelated sidebar preservation\n")
