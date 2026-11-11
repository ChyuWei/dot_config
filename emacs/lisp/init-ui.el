;;; init-ui.el --- Fonts, theme and frame -*- lexical-binding: t; -*-

;;; Commentary:

;; macOS-oriented look: JetBrains Mono + LXGW WenKai, the built-in
;; `modus-operandi' theme, doom-modeline with Nerd Font icons, a padded
;; frame, and centered prose in Org and Markdown.
;;
;; The file has three parts, in this order:
;;
;;   1. Settings    -- `setq'/face/frame settings.  Run while the file loads.
;;   2. Definitions -- functions and `use-package' declarations.  Run while
;;                     the file loads; packages they mention stay deferred.
;;   3. Activation  -- the functions that load packages and turn modes on.
;;                     They run from `my/init-hooks', registered at the end.
;;
;; A package goes in part 2 with `:defer t' and is loaded in part 3; anything
;; the first screen needs (frame, faces, theme) stays in part 1.

;;; Code:

;;; Part 1: settings -------------------------------------------------------

;; A calm frame title and a useful scratch buffer.
(setq frame-title-format "%b — Emacs")
(setq initial-scratch-message ";; Start Hacking\n")

;; Keep heading sizes explicit across Org and both Markdown implementations.
;; These are markdown-mode's existing scaling defaults, relative to body text.
(dolist (entry '((org . "org-level-")
                 (markdown-mode . "markdown-header-face-")
                 (markdown-ts-mode . "markdown-ts-heading-")))
  (let ((library (car entry))
        (prefix (cdr entry)))
    (with-eval-after-load library
      (let ((level 0))
        (dolist (height '(2.0 1.7 1.4 1.1 1.0 1.0))
          (setq level (1+ level))
          (set-face-attribute (intern (format "%s%d" prefix level))
                              nil :height height))))))

;; Unify Markdown's typography with Org's.  Org derives `org-level-N' from
;; `outline-N', so each heading level gets its own colour; both Markdown
;; modes instead paint every heading with `font-lock-function-name-face' +
;; bold.  Reusing the Org faces (and org-modern's symbol face for list
;; markers) makes .md and .org read the same.  The :height set above is
;; explicit and therefore left untouched by these :inherit settings.
(with-eval-after-load 'markdown-ts-mode
  (dotimes (i 6)
    (set-face-attribute (intern (format "markdown-ts-heading-%d" (1+ i))) nil
                        :inherit (intern (format "outline-%d" (1+ i)))
                        :weight 'unspecified))
  (set-face-attribute 'markdown-ts-block-quote nil
                      :inherit '(org-quote font-lock-doc-face))
  (set-face-attribute 'markdown-ts-code-block nil
                      :inherit '(org-block fixed-pitch))
  (set-face-attribute 'markdown-ts-code-span nil
                      :inherit '(org-code shadow))
  (set-face-attribute 'markdown-ts-table nil
                      :inherit '(org-table fixed-pitch))
  (set-face-attribute 'markdown-ts-list-marker nil
                      :inherit '(org-modern-symbol default))
  (set-face-attribute 'markdown-ts-task-checked nil
                      :inherit '(org-modern-symbol font-lock-builtin-face))
  (set-face-attribute 'markdown-ts-task-unchecked nil
                      :inherit '(org-modern-symbol font-lock-builtin-face))
  (set-face-attribute 'markdown-ts-thematic-break nil
                      :inherit '(org-modern-horizontal-rule markdown-ts-delimiter)))

(with-eval-after-load 'markdown-mode
  (dotimes (i 6)
    (set-face-attribute (intern (format "markdown-header-face-%d" (1+ i))) nil
                        :inherit (intern (format "outline-%d" (1+ i)))
                        :weight 'unspecified))
  (set-face-attribute 'markdown-blockquote-face nil
                      :inherit '(org-quote font-lock-doc-face))
  (set-face-attribute 'markdown-code-face nil
                      :inherit '(org-block fixed-pitch))
  (set-face-attribute 'markdown-inline-code-face nil
                      :inherit '(org-code shadow)))

;;; Part 2: definitions ----------------------------------------------------

;;; Fonts

(defvar my/fonts-configured-p nil
  "Non-nil once the Latin font faces have been applied.")

(defvar my/fontsets-configured-p nil
  "Non-nil once CJK and symbol fontsets have been applied.")

(defun my/setup-fontsets ()
  "Apply CJK and symbol fontsets once, after the first frame is up."
  (when (and (display-graphic-p) (not my/fontsets-configured-p))
    (setq my/fontsets-configured-p t)
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

(defun my/setup-fonts (&rest _)
  "Apply the Latin face font now and defer the heavier fontsets."
  (when (and (display-graphic-p) (not my/fonts-configured-p))
    ;; Prose, code and the modeline share the same Latin typeface.
    (dolist (face '(default fixed-pitch variable-pitch))
      (set-face-attribute face nil :family "JetBrains Mono"
                          :height (if (eq face 'default) 160 1.0)))
    (setq my/fonts-configured-p t)
    ;; Fontset creation can be slow on the first frame; keep startup snappy.
    (run-with-idle-timer 0.3 nil #'my/setup-fontsets)))

;;; Prose layout

;; Org and Markdown enable these per buffer.
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

;;; Modeline

(use-package nerd-icons
  :ensure t
  :defer t)

;; Loaded by `my/init-ui-activate-modeline'.
(use-package doom-modeline
  :ensure t
  :defer t
  :init
  (setq doom-modeline-height 30
        doom-modeline-bar-width 4
        doom-modeline-icon t
        doom-modeline-major-mode-icon t
        doom-modeline-major-mode-color-icon t
        doom-modeline-buffer-state-icon t
        doom-modeline-buffer-modification-icon t
        doom-modeline-enable-word-count nil
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

  ;; Which keybinding profile is active (see init-profile.el).  Cheap: it
  ;; only reads a variable, so it is safe on every redraw.
  (doom-modeline-def-segment my/keybinding-profile
    "Current keybinding profile: VIM (leader SPC) or EMACS (native keys)."
    (propertize (if (eq my/keybinding-profile 'vim) " VIM " " EMACS ")
                'face (if (eq my/keybinding-profile 'vim)
                          'doom-modeline-info
                        'doom-modeline-warning)
                'help-echo "Keybindings: M-x my/toggle-keybindings to switch"))

  ;; Cached config drift: no file I/O on redisplay.
  (doom-modeline-def-segment my/config-status
    "Show a warning emoji when the running configuration is stale."
    (when my/config--stale-cache
      (propertize " 😭 "
                  'face 'doom-modeline-warning
                  'help-echo
                  (concat "Config stale: "
                          (mapconcat
                           (lambda (file)
                             (file-relative-name file my/config-directory))
                           my/config--stale-cache ", ")))))

  ;; Keep stock main segments, replacing only buffer-info.
  (doom-modeline-def-modeline
   'main
   '(eldoc bar window-state workspace-name window-number modals
           my/keybinding-profile matches follow my/buffer-state-or-name
           remote-host buffer-position parrot selection-info)
   '(compilation objed-state misc-info my/config-status project-name persp-name
                 battery grip irc mu4e gnus github debug repl lsp minor-modes
                 input-method indent-info buffer-encoding major-mode process vcs
                 check time)))

;;; Change indicators

;; Purely decorative, loaded by `my/init-ui-activate-diff-hl'.
(use-package diff-hl
  :ensure t
  :defer t)

;;; Part 3: activation -----------------------------------------------------

;; Each function below loads a package or turns a mode on.  The hook it runs
;; from is given in its docstring and registered at the end of the file.

(defun my/init-ui-activate-display ()
  "Load the theme, the fonts and the display modes.
Runs from `my/window-ready-hook', i.e. after the frame parameters are
applied and before the first redraw.  A GUI start already has its frame
here; TTY and daemon get theirs later, so the per-frame hook stays
registered for them (face and fontset changes are global, so frames created
afterwards inherit them)."
  ;; `modus-operandi' is loaded from early-init.el; this only matters when
  ;; Custom saved a different `custom-enabled-themes' into etc/custom.el.
  (unless (custom-theme-enabled-p 'modus-operandi)
    (load-theme 'modus-operandi t))
  (if (display-graphic-p)
      (my/setup-fonts)
    (add-hook 'after-make-frame-functions #'my/setup-fonts))
  (column-number-mode 1)
  (size-indication-mode 1))

(defun my/init-ui-activate-modeline ()
  "Enable doom-modeline.
Runs from `my/after-init-hook', which is before the first redraw."
  (doom-modeline-mode 1))

(defun my/init-ui--refresh-diff-hl ()
  "Update the change indicators for the current file buffer."
  (when (and buffer-file-name (fboundp 'diff-hl-update)
             (ignore-errors (vc-backend buffer-file-name)))
    (ignore-errors (diff-hl-update))))

(defun my/init-ui-activate-diff-hl ()
  "Enable the fringe change indicators.
Runs from `my/idle-hook': nothing on the first screen depends on them, so
they can arrive a second late."
  (require 'diff-hl)
  (global-diff-hl-mode 1)
  ;; Count/wait for changes on a timer rather than on every keystroke.
  (diff-hl-flydiff-mode 1)
  ;; Marks must be there when a modified file appears on screen.
  (add-hook 'find-file-hook #'my/init-ui--refresh-diff-hl)
  (add-hook 'dired-mode-hook #'diff-hl-dired-mode))

;; Depth 10: before init-env's PATH import at depth 20, which redisplays.
(add-hook 'my/window-ready-hook #'my/init-ui-activate-display 10)
(add-hook 'my/after-init-hook #'my/init-ui-activate-modeline)
(add-hook 'my/idle-hook #'my/init-ui-activate-diff-hl)

(provide 'init-ui)

;;; init-ui.el ends here
