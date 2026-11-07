;;; init-defaults.el --- Editing and session defaults -*- lexical-binding: t; -*-

;;; Commentary:

;; Sensible built-in behaviour: files, history, scrolling, prose wrapping,
;; and programming niceties, with treesit-auto and Dirvish integrations.

;;; Code:

;;; Files and persistence -------------------------------------------------

(setq backup-by-copying t
      version-control t
      delete-old-versions t
      kept-new-versions 5
      kept-old-versions 2
      create-lockfiles nil
      require-final-newline t
      vc-follow-symlinks t
      large-file-warning-threshold (* 50 1024 1024))

;; `recentf-exclude' is not autoloaded, so load the library first.
(require 'recentf)
(setq recentf-max-saved-items 200
      recentf-max-menu-items 25)
(dolist (dir '("elpa" "var" "etc"))
  (add-to-list 'recentf-exclude
               (expand-file-name dir user-emacs-directory)))
(recentf-mode 1)

(setq history-length 1000
      history-delete-duplicates t)
(savehist-mode 1)

(save-place-mode 1)
(setq global-auto-revert-non-file-buffers t)
(global-auto-revert-mode 1)

;;; Typing and editing ----------------------------------------------------

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80
              sentence-end-double-space nil)

(setq use-short-answers t
      enable-recursive-minibuffers t
      read-extended-command-predicate #'command-completion-default-include-p
      completion-ignore-case t
      read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t)

(setq select-enable-clipboard t
      save-interprogram-paste-before-kill t
      mouse-yank-at-point t
      kill-do-not-save-duplicates t)

(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))

;; Smooth, readable scrolling.  Pixel scrolling must keep the stock
;; recentering rules: a high `scroll-conservatively' makes redisplay
;; chase point on every frame and the pinning stops the buffer scrolling
;; to the very top or bottom under the wheel.
(setq-default scroll-margin 0
              echo-keystrokes 0.02)
(setq-default line-spacing 0.25)

(delete-selection-mode 1)
(pixel-scroll-precision-mode 1)
(repeat-mode 1)
(show-paren-mode 1)
(blink-cursor-mode -1)
(setq ring-bell-function #'ignore)

;; Window management.
(winner-mode 1)
(setq window-combination-resize t)

;;; Prose vs code ---------------------------------------------------------

;; Wrapped lines for prose buffers.  Org and Markdown inherit from
;; text-mode, and enable this explicitly as well.
(add-hook 'text-mode-hook (lambda () (visual-line-mode 1)))
(setq visual-line-fringe-indicators nil)

;; Line numbers everywhere by default, including Markdown/Org prose and
;; their code blocks.  `t' means absolute numbers; the width starts at
;; three columns and only grows, so the text does not jump around.
(setq display-line-numbers-type t
      display-line-numbers-width 3
      display-line-numbers-grow-only t)
(global-display-line-numbers-mode 1)

;;; Tree-sitter grammars ---------------------------------------------------

;; Built-in tree-sitter modes load grammar libraries from
;; ~/.emacs.d/tree-sitter.  markdown, markdown-inline and python live
;; there already (built by build-tree-sitter.sh, which works around
;; Emacs 31's installer picking the wrong source directories in the
;; two-language markdown repository).  Everything else is automatic:
;; treesit-auto clones and builds the grammar the first time a buffer
;; switches to that language's tree-sitter mode.
(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install t)
  :config
  ;; Markdown grammars stay with build-tree-sitter.sh, everything
  ;; common gets pulled on demand the first time its mode runs.
  (setq treesit-auto-langs
        '(rust go json toml yaml html css javascript typescript
               lua c cpp python sql))
  (global-treesit-auto-mode 1))

;; Programming buffers: pair completion and current line.
(add-hook 'prog-mode-hook
          (lambda ()
            (electric-pair-mode 1)
            (hl-line-mode 1)))

;;; Dired -----------------------------------------------------------------

(use-package dirvish
  :ensure t
  :defer t
  :config
  ;; Dirvish 2.3 keeps side/subtree extensions outside its autoload path.
  (add-to-list 'load-path
               (expand-file-name "extensions"
                                 (file-name-directory (locate-library "dirvish"))))
  (require 'dirvish-side)
  (dirvish-override-dired-mode 1)
  (dirvish-side-follow-mode 1))

(defun my/dirvish-side ()
  "Toggle the current frame's Dirvish sidebar, loading it on first use."
  (interactive)
  (require 'dirvish)
  ;; Use Dirvish's session lookup: a left side window may belong to another
  ;; package.  Close a visible tree even when an editing window is selected.
  (if-let* ((window (dirvish-side--session-visible-p)))
      (progn
        (select-window window)
        (dirvish-quit))
    (dirvish-side)))

;; Line numbers refer to listing rows in Dired, not file contents.
(add-hook 'dired-mode-hook
          (lambda () (display-line-numbers-mode -1)))

(setq dired-listing-switches "-alh"
      dired-dwim-target t
      dired-recursive-copies 'always
      dired-recursive-deletes 'top)
(add-hook 'dired-mode-hook #'dired-hide-details-mode)

;;; Misc ------------------------------------------------------------------

(setq use-file-dialog nil
      use-dialog-box nil
      uniquify-buffer-name-style 'forward)

(provide 'init-defaults)

;;; init-defaults.el ends here
