;;; init-markdown.el --- Markdown reading and editing -*- lexical-binding: t; -*-

;;; Commentary:

;; The default major mode for .md files is the built-in tree-sitter
;; `markdown-ts-mode' (Emacs 31): structural fontification, native code
;; block highlighting (which needs the `python' grammar built into
;; ~/.emacs.d/tree-sitter), display-friendly list markers and checkboxes.
;; The grammars themselves are in ~/.emacs.d/tree-sitter.
;;
;; `markdown-ts-appear' reveals the markup of the element at point and
;; restores its rendered look when the cursor leaves; with Evil the
;; source is revealed while inserting only.  Math and diagram previews
;; stay off (no LaTeX / mermaid on this machine).
;;
;; `markdown-mode' remains available for its commands (browser preview,
;; export) but is no longer the default major mode.

;;; Code:

;; Shared prose styling, applied to both Markdown major modes.  Does not
;; touch markup hiding: each mode provides its own toggling.
(defun my/markdown-setup-core ()
  "Reading-oriented minor modes and modeline for a prose buffer."
  (valign-mode 1)
  (visual-line-mode 1)
  (my/prose-layout))

;; markdown-ts-mode (default) ------------------------------------------------

;; Reveal source only in Evil insert state (package README pattern), so
;; the buffer always looks rendered outside editing.
(defun my/markdown-ts-appear-evil ()
  "Reveal Markdown source only in Evil insert state."
  (if markdown-ts-appear-mode
      (progn
        (add-hook 'evil-insert-state-entry-hook #'markdown-ts-appear-start nil t)
        (add-hook 'evil-insert-state-exit-hook #'markdown-ts-appear-stop nil t)
        (unless (eq (bound-and-true-p evil-state) 'insert)
          (markdown-ts-appear-stop)))
    (remove-hook 'evil-insert-state-entry-hook #'markdown-ts-appear-start t)
    (remove-hook 'evil-insert-state-exit-hook #'markdown-ts-appear-stop t)))

(defun my/markdown-ts-setup ()
  "Tree-sitter Markdown setup: appear plus shared prose styling."
  (require 'markdown-ts-appear)
  (add-hook 'markdown-ts-appear-mode-hook #'my/markdown-ts-appear-evil nil t)
  (markdown-ts-appear-mode 1)
  ;; The image-preview font-lock feature lives in the native mode's
  ;; level-4 feature group, so customizing `markdown-ts-inline-images'
  ;; alone renders nothing: the feature must be recomputed per buffer,
  ;; exactly what the interactive toggle does (see
  ;; `markdown-ts-toggle-inline-images' in markdown-ts-mode.el).
  (when markdown-ts-inline-images
    (markdown-ts--set-inline-images t))
  (my/markdown-setup-core))

(use-package markdown-ts-mode
  :ensure nil                    ; built into Emacs 31
  :custom
  (markdown-ts-inline-images t)
  ;; Plain rendering: the fence keeps raw ``` and gets no frame or
  ;; background slab (this is the decoration the user opted out of).
  (markdown-ts-appear-code-fence-style 'raw)
  (markdown-ts-hard-line-break-backslash nil)
  (markdown-ts-hard-line-break-space nil)
  :mode (("\\.md\\'" . markdown-ts-mode)
         ("\\.markdown\\'" . markdown-ts-mode)
         ("\\.mdown\\'" . markdown-ts-mode))
  :hook (markdown-ts-mode . my/markdown-ts-setup)
  :config
  ;; Keep cream code blocks with raw fences, without a frame or label.
  (dolist (face '(markdown-ts-code-block-markup-hidden markdown-ts-code-block))
    (set-face-attribute face nil :background "#ebdbb2")))

;; markdown-mode utility package ---------------------------------------------

(use-package markdown-mode
  :ensure t
  :defer t
  :custom
  (markdown-header-scaling t)
  (markdown-fontify-code-blocks-natively t)
  (markdown-max-image-size '(800 . 600))
  :hook (markdown-mode . my/markdown-setup-mm))

(defun my/markdown-setup-mm ()
  "markdown-mode path: hide markup and show local images, then shared prose setup."
  (markdown-toggle-markup-hiding 1)
  (when (display-graphic-p)
    (markdown-display-inline-images))
  (my/markdown-setup-core))

(provide 'init-markdown)

;;; init-markdown.el ends here
