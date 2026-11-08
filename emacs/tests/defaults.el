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

(require 'treesit)
;; The grammar directory no-littering registered, and the grammars that must be
;; installed for the modes below to make sense.
(let ((grammar-directory (no-littering-expand-var-file-name "treesit/")))
  (cl-assert (file-directory-p grammar-directory))
  (cl-assert (equal (car treesit-extra-load-path) grammar-directory))
  (cl-assert (not (member (expand-file-name "tree-sitter" user-emacs-directory)
                          treesit-extra-load-path)))
  (dolist (language '(markdown markdown-inline python rust))
    (cl-assert (treesit-language-available-p language))))

;; Tree-sitter modes are enabled by the built-in `treesit-enabled-modes'
;; (static remaps, no per-file probing).  The configuration applies it from
;; `my/after-init-hook', which batch mode never runs, so call the activation
;; step directly.
(my/init-defaults-activate-treesit)
(cl-assert (equal treesit-enabled-modes my/treesit-enabled-ts-modes))
(dolist (pair '((rust-mode . rust-ts-mode)
                (python-mode . python-ts-mode)
                (conf-toml-mode . toml-ts-mode)))
  (cl-assert (eq (cdr (assq (car pair) major-mode-remap-alist)) (cdr pair))))
;; Both ways of installing a grammar must land in var/treesit/ -- beside the
;; other grammars, inside the path no-littering registered, and ignored by git.
(cl-assert (equal (car treesit--install-language-grammar-out-dir-history)
                  (no-littering-expand-var-file-name "treesit/")))
(cl-assert (equal (car treesit-extra-load-path)
                  (no-littering-expand-var-file-name "treesit/")))
(cl-assert (not (file-exists-p (expand-file-name "tree-sitter" user-emacs-directory))))
;; A language whose grammar is not installed must keep its classic mode.
(cl-assert (null (assq 'yaml-mode major-mode-remap-alist)))
(cl-assert (null (assq 'go-mode major-mode-remap-alist)))
;; `setopt' must be used: with `setq' the :set function never runs.
(cl-assert (memq 'rust-ts-mode (mapcar #'cdr treesit-major-mode-remap-alist)))

(princ "PASS: current-mode grammar checks and user remaps preserved\n")

;; Mouse: point stays put on screen while scrolling, selections can be dragged,
;; and right-click opens a menu instead of deleting the selection.
(cl-assert scroll-preserve-screen-position)
(cl-assert mouse-drag-and-drop-region)
(my/init-defaults-activate-editing)
(cl-assert context-menu-mode)

;; Isearch tuning: feel only, plus `isearch-lazy-count' (the one with a cost).
(cl-assert (eq isearch-wrap-pause 'no))
(cl-assert isearch-repeat-on-direction-change)
(cl-assert isearch-allow-scroll)
(cl-assert isearch-lazy-count)

;; Line spacing is split above and below (a pair since Emacs 31) instead of
;; only below, so text is centred in its line box.  The total must stay 0.25.
(cl-assert (equal (default-value 'line-spacing) '(0.125 . 0.125)))
(princ "PASS: line spacing centred above and below\n")

;; fd-backed file search.  `consult-fd' must not drop dotfiles from its own
;; arguments, and `dirvish-fd' must turn fd's output into a usable Dired buffer
;; (that path needs GNU ls, hence coreutils on macOS).
(cl-assert (member "--hidden" consult-fd-args))
(cl-assert (equal (cadr (member "--exclude" consult-fd-args)) ".git"))
(let* ((directory (make-temp-file "emacs-fd-test-" t))
       (buffer nil))
  (unwind-protect
      (progn
        (dolist (name '("alpha.txt" "beta.txt" "gamma.md"))
          (with-temp-file (expand-file-name name directory) (insert "x\n")))
        (make-directory (expand-file-name "deep" directory) t)
        (with-temp-file (expand-file-name "deep/delta.txt" directory) (insert "x\n"))
        (require 'dirvish)
        (require 'dirvish-fd)
        (unless (and dirvish-fd-ls-program
                     (executable-find dirvish-fd-ls-program))
          (error "dirvish-fd needs GNU ls; install coreutils"))
        (setq buffer (let ((default-directory directory))
                       (my/dirvish-fd "txt")))
        ;; fd writes into the buffer from a process filter: wait for it.
        (let ((proc (get-buffer-process "*dirvish-fd*"))
              (start (float-time)))
          (while (and proc (process-live-p proc) (< (- (float-time) start) 10))
            (accept-process-output proc 0.1)))
        (with-current-buffer buffer
          (cl-assert (derived-mode-p 'dired-mode))
          (let ((raw (buffer-substring-no-properties (point-min) (point-max))))
            (cl-assert (string-match-p "alpha.txt" raw))
            (cl-assert (string-match-p "deep/delta.txt" raw))   ; recursive
            (cl-assert (not (string-match-p "gamma.md" raw)))))) ; pattern
    (when (buffer-live-p buffer) (kill-buffer buffer))
    (when (get-buffer "*dirvish-fd*") (kill-buffer "*dirvish-fd*"))
    (delete-directory directory t)))

;; zoxide directory jumping (autoloaded, not loaded) and format-on-save.
(cl-assert (commandp 'consult-zoxide))
(cl-assert (not (featurep 'consult-zoxide)))
(my/init-defaults-activate-formatting)
(cl-assert apheleia-global-mode)
(cl-assert (not (assq 'emacs-lisp-mode apheleia-mode-alist)))
(cl-assert (eq (cdr (assq 'rust-ts-mode apheleia-mode-alist)) 'rustfmt))
;; End to end: rustfmt runs asynchronously on save and rewrites the file.
(let ((file (make-temp-file "emacs-apheleia-" nil ".rs")))
  (unwind-protect
      (progn
        (unless (executable-find "rustfmt")
          (error "apheleia test needs rustfmt (rustup component)"))
        (with-temp-file file
          (insert "fn main(){let  x=1;println!(\"{}\",x);}\n"))
        (find-file file)
        (cl-assert apheleia-mode)
        (goto-char (point-min))
        (insert "// touch\n")
        (save-buffer)
        (let ((start (float-time)))
          (while (< (- (float-time) start) 5)
            (accept-process-output nil 0.1)))
        (with-temp-buffer
          (insert-file-contents file)
          (cl-assert (string-match-p "    let x = 1;" (buffer-string)))
          (cl-assert (string-match-p "^fn main() {$" (buffer-string)))))
    (when (get-file-buffer file)
      (with-current-buffer (get-file-buffer file) (set-buffer-modified-p nil))
      (kill-buffer (get-file-buffer file)))
    (delete-file file)))

(princ "PASS: ripgrep xref, fd-backed file search and format-on-save\n")

;; Running one `xref' search command is enough to check the program choice:
;; every one of them expands its command from `xref-search-program'.
(require 'xref)
(cl-assert (eq xref-search-program 'ripgrep))
(let ((template (cdr (assq xref-search-program xref-search-program-alist))))
  (cl-assert (string-match-p "\\`xargs -0 rg " template))
  (cl-assert (not (string-match-p "\\bgrep\\b" template))))
(princ "PASS: xref text search uses ripgrep\n")

(princ "PASS: real sidebar open/close, file opening, follow and unrelated sidebar preservation\n")
