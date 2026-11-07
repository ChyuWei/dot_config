;;; init-ui.el --- Fonts, theme and frame -*- lexical-binding: t; -*-

;;; Commentary:

;; macOS-oriented look:
;;   - JetBrains Mono for Latin, LXGW WenKai for Chinese;
;;   - Gruvbox light-soft warm paper theme;
;;   - doom-modeline with Nerd Font icons;
;;   - padded frame, centered prose in Org and Markdown.

;;; Code:

;;; Fonts -----------------------------------------------------------------

(defvar my-fonts-configured nil
  "Non-nil once the graphical font stack has been applied.")

(defun my/setup-fonts (&rest _)
  "Apply the shared font stack once a graphical frame is available."
  (when (and (display-graphic-p) (not my-fonts-configured))
    (setq my-fonts-configured t)
    ;; Prose, code and the modeline share the same Latin typeface.
    (dolist (face '(default fixed-pitch variable-pitch))
      (set-face-attribute face nil :family "JetBrains Mono"
                          :height (if (eq face 'default) 160 1.0)))
    ;; WenKai is the primary Chinese font; PingFang fills missing glyphs.
    (dolist (script '(han cjk-misc))
      (set-fontset-font t script (font-spec :family "LXGW WenKai")))
    (dolist (script '(han cjk-misc))
      (set-fontset-font t script (font-spec :family "PingFang SC") nil 'append))
    (dolist (entry '((symbol "Apple Symbols")
                     ((#xe000 . #xf8ff) "Symbols Nerd Font Mono")
                     (emoji "Apple Color Emoji" append)))
      (apply #'set-fontset-font t (car entry)
             (font-spec :family (cadr entry))
             (when (nth 2 entry) (list nil (nth 2 entry)))))))

(if (display-graphic-p)
    (my/setup-fonts)
  (add-hook 'after-make-frame-functions #'my/setup-fonts))

;;; Prose layout ----------------------------------------------------------

;; Org and Markdown enable these per buffer; keep package loading deferred.

(use-package valign
  :ensure t
  :defer t)

(use-package olivetti
  :ensure t
  :defer t
  :custom
  (olivetti-body-width 96)
  (olivetti-margin-width 8)
  (olivetti-style 'fancy))

;;; Theme -----------------------------------------------------------------

;; Fixed warm paper theme, independent of macOS light/dark appearance.
(use-package gruvbox-theme
  :ensure t
  :config
  (load-theme 'gruvbox-light-soft t)
  ;; Org block faces exist only after Org loads.
  (with-eval-after-load 'org
    (dolist (face '(org-block org-block-begin-line org-block-end-line))
      (set-face-attribute face nil :background "#ebdbb2" :extend t))))

;; Keep heading sizes explicit across Org and both Markdown implementations.
;; These are markdown-mode's existing scaling defaults, relative to body text.
(dolist (entry '((org . "org-level-")
                 (markdown-mode . "markdown-header-face-")
                 (markdown-ts-mode . "markdown-ts-heading-")))
  (let ((library (car entry))
        (prefix (cdr entry)))
    (with-eval-after-load library
      (cl-loop for height in '(2.0 1.7 1.4 1.1 1.0 1.0)
               for level from 1
               do (set-face-attribute (intern (format "%s%d" prefix level))
                                      nil :height height)))))

;;; Modeline --------------------------------------------------------------

;; Doom modeline loads after init; Nerd Font icons load on demand.
(use-package nerd-icons
  :ensure t
  :defer t)

(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode)
  :init
  (setq doom-modeline-height 30
        doom-modeline-bar-width 4
        doom-modeline-icon t
        doom-modeline-major-mode-icon t
        doom-modeline-major-mode-color-icon t
        doom-modeline-buffer-state-icon t
        doom-modeline-buffer-modification-icon t
        doom-modeline-enable-word-count t
        doom-modeline-continuous-word-count-modes '(markdown-mode org-mode)
        doom-modeline-buffer-file-name-style 'truncate-upto-project
        doom-modeline-lsp nil
        doom-modeline-env-version nil
        doom-modeline-indent-info nil
        doom-modeline-checker-simple-format t
        doom-modeline-number-limit 99
        doom-modeline-display-default-buffer-name t
        doom-modeline-gui (display-graphic-p))
  :config
  ;; The header owns file identity.  Show only file state for file buffers,
  ;; but retain names and icons for scratch, Help and Dired buffers.
  (doom-modeline-def-segment my/buffer-state-or-name
    (concat
     (doom-modeline-spc)
     (if buffer-file-name
         (doom-modeline--buffer-state-icon)
       (concat (doom-modeline--buffer-mode-icon)
               (doom-modeline--buffer-state-icon)
               (doom-modeline--buffer-simple-name)))))

  ;; Keep stock main segments, replacing only buffer-info.
  (doom-modeline-def-modeline
   'main
   '(eldoc bar window-state workspace-name window-number modals matches follow
           my/buffer-state-or-name remote-host buffer-position word-count parrot
           selection-info)
   '(compilation objed-state misc-info project-name persp-name battery grip irc
                 mu4e gnus github debug repl lsp spell minor-modes input-method
                 indent-info buffer-encoding major-mode process vcs check time)))

;; Org and Markdown share the same per-buffer reading indicator.
(defun my/reading-progress ()
  "Return a progress bar and percentage for point in this buffer."
  (let* ((frac (/ (float (point)) (max 1 (buffer-size))))
         (filled (round (* 8.0 frac))))
    (format "%s %2d%%"
            (concat (make-string filled ?▓)
                    (make-string (- 8 filled) ?░))
            (round (* 100.0 frac)))))

(defun my/prose-progress-modeline ()
  "Show the reading progress bar in the current buffer's mode line."
  (unless (member '(:eval (my/reading-progress)) mode-line-misc-info)
    (setq-local mode-line-misc-info
                (append (copy-sequence (default-value 'mode-line-misc-info))
                        (list " " '(:eval (my/reading-progress)))))))

(defun my/prose-layout ()
  "Apply the shared Org and Markdown reading layout in this buffer."
  (olivetti-mode 1)
  ;; Olivetti enables word wrapping; restore character wrapping afterwards.
  (setq-local word-wrap nil)
  (display-line-numbers-mode -1)
  (my/prose-progress-modeline))

;;; Change indicators -----------------------------------------------------

;; Show uncommitted changes in the fringe and Dired file-state marks.
(use-package diff-hl
  :ensure t
  :hook (after-init . global-diff-hl-mode)
  :config
  ;; Refresh on a timer, and immediately when a file is opened, so the
  ;; marks are there as soon as a modified file appears on screen.
  (diff-hl-flydiff-mode 1)
  (add-hook 'find-file-hook
            (lambda ()
              (when (and buffer-file-name (fboundp 'diff-hl-update)
                         (ignore-errors (vc-backend buffer-file-name)))
                (ignore-errors (diff-hl-update)))))
  (add-hook 'dired-mode-hook #'diff-hl-dired-mode))

;;; Frame and startup buffer ----------------------------------------------

;; A padded frame with subtle dividers between windows.
(modify-all-frames-parameters
 '((internal-border-width . 12)
   (right-divider-width . 12)
   (bottom-divider-width . 12)))

;; A calm frame title and a useful scratch buffer.
(setq frame-title-format "%b — Emacs")
(setq initial-scratch-message
      (concat
       ";; Emacs 31 — normal state, SPC is the leader\n"
       ";;\n"
       ";; SPC SPC  find project file     SPC ,   switch buffer\n"
       ";; SPC :    M-x                   SPC /   search project\n"
       ";; SPC e    file sidebar          SPC sb  search lines\n"
       ";; SPC cs   outline sidebar       SPC ss  jump to heading\n"
       ";; SPC na   org agenda            SPC nc  org capture\n"
       ";; SPC mh   Markdown markup       SPC uz  centered writing\n"
       ";; SPC f/b/s/w/c/g/u — press and pause for available keys\n"))

(column-number-mode 1)
(size-indication-mode 1)

(provide 'init-ui)

;;; init-ui.el ends here
