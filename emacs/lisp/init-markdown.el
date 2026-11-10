;;; init-markdown.el --- Markdown reading and editing -*- lexical-binding: t; -*-

;;; Commentary:

;; `.md' files open in the built-in tree-sitter `markdown-ts-mode' (Emacs 31):
;; structural fontification, native code block highlighting (which needs the
;; `python' grammar in var/treesit/ beside this configuration), display-friendly list markers
;; and checkboxes.
;;
;; `markdown-ts-appear' reveals the markup of the element at point and
;; restores its rendered look when the cursor leaves; with Evil the source is
;; revealed while inserting only.  Math and diagram previews stay off (no
;; LaTeX / mermaid on this machine).
;;
;; Footnotes (`[^id]') are rendered by this file's own font-lock advice: the
;; grammar sees them as reference links or plain paragraphs, so the marker is
;; replaced after normal fontification.  Only the requested region is
;; touched -- no polling, no whole-buffer index, no text changes -- and the
;; `treesit' and `xref' libraries it needs load with the first Markdown
;; buffer, not at startup.
;;
;; Traditional `markdown-mode' is not managed here; compatibility commands
;; below remain available if it is installed separately.
;;
;; There is no activation step: every package here is reached through a mode
;; hook or an autoload, so this file is all settings and definitions.  The
;; setup functions come first and the `use-package' declarations that hook
;; them follow, which keeps the byte compiler quiet about the forward
;; references.

;;; Code:

;; Keep the byte compiler quiet about names that only exist once a package or
;; a built-in library loads.  Nothing here loads them.
(declare-function markdown-toggle-inline-images "markdown-mode")
(declare-function markdown-ts-toggle-inline-images "markdown-ts-mode")
(declare-function markdown-toggle-markup-hiding "markdown-mode")
(declare-function markdown-ts-appear-start "markdown-ts-appear")
(declare-function markdown-ts-appear-stop "markdown-ts-appear")
(declare-function markdown-ts-appear--region-visible-p "markdown-ts-appear")
(declare-function markdown-ts--set-inline-images "markdown-ts-mode")
(declare-function treesit-node-at "treesit" (pos &optional parser-or-lang named))
(declare-function treesit-node-type "treesit" (node))
(declare-function treesit-parent-until "treesit" (node pred &optional include-node))
(declare-function xref-push-marker-stack "xref" (&optional marker))
(defvar markdown-ts-appear-mode)
(defvar markdown-ts-inline-images)
(defvar treesit-primary-parser)

;;; Footnotes -------------------------------------------------------------

(defface my/markdown-footnote-reference
  '((t (:inherit link :height 0.8)))
  "Small superscript footnote references."
  :group 'markdown-ts)

(defface my/markdown-footnote-text
  '((t (:height 0.9)))
  "Slightly smaller footnote definitions, without raising the baseline."
  :group 'markdown-ts)

(defconst my/markdown-footnote-regexp "\\[\\^\\([^][[:space:]]+\\)\\]"
  "A Markdown footnote marker, with its identifier in group 1.")

(defun my/markdown-footnote-ignored-context-p (position)
  "Return non-nil when a marker at POSITION is code or other literal text.
Image descriptions and link destinations are not footnote references."
  (or (treesit-parent-until
       (treesit-node-at position treesit-primary-parser)
       (lambda (node)
         (member (treesit-node-type node)
                 '("fenced_code_block" "indented_code_block" "html_block"))) t)
      (treesit-parent-until
       (treesit-node-at position 'markdown-inline)
       (lambda (node)
         (member (treesit-node-type node)
                 '("code_span" "backslash_escape" "html_tag" "image"
                   "inline_link" "full_reference_link" "collapsed_reference_link"))) t)))

(defun my/markdown-footnote-definition-p (position)
  "Return non-nil if the marker at POSITION starts a definition."
  (save-excursion
    (goto-char position)
    (and (string-match-p "\\` \\{0,3\\}\\'"
                         (buffer-substring-no-properties (pos-bol) position))
         (looking-at (concat my/markdown-footnote-regexp ":")))))

(defun my/markdown-footnote-definition-end (position)
  "Return the end of the definition at POSITION, including continuations.
Indented lines belong to the definition; blank lines only do if followed
by an indented continuation.  The next unindented paragraph stays normal."
  (save-excursion
    (goto-char position)
    (forward-line 1)
    (while (and (not (eobp))
                (or (>= (current-indentation) 4)
                    (and (looking-at-p "[ \t]*$")
                         (save-excursion
                           (skip-chars-forward " \t\n")
                           (and (not (eobp)) (>= (current-indentation) 4))))))
      (forward-line 1))
    (point)))

(defun my/markdown-footnote-jump (identifier definition)
  "Jump to IDENTIFIER's definition, or its first reference if DEFINITION.
Only search when invoked.  Save the exact origin on Xref's return stack."
  (let ((origin (point)) target)
    (save-excursion
      (goto-char (point-min))
      (while (and (not target) (re-search-forward my/markdown-footnote-regexp nil t))
        (let ((position (match-beginning 0))
              (label (match-string-no-properties 1)))
          (when (and (equal identifier label)
                     (not (my/markdown-footnote-ignored-context-p position))
                     (if definition
                         (not (my/markdown-footnote-definition-p position))
                       (my/markdown-footnote-definition-p position)))
            (setq target position)))))
    (unless target
      (user-error "找不到脚注 %s 的%s" identifier (if definition "引用" "解释")))
    (goto-char origin)
    (xref-push-marker-stack)
    (goto-char target)))

(defun my/markdown-footnote-render (begin end identifier definition)
  "Render the marker BEGIN..END for IDENTIFIER, respecting source reveal.
DEFINITION means this marker labels a footnote definition."
  (let* ((definition-end (and definition (my/markdown-footnote-definition-end begin)))
         (visible (markdown-ts-appear--region-visible-p begin (or definition-end end))))
    ;; Native link rendering adds an icon and a file/URL action to [^id].
    ;; Remove only that marker's icon; links inside the note keep theirs.
    (dolist (overlay (overlays-in begin end))
      (when (overlay-get overlay 'markdown-ts-appear--link-icon)
        (delete-overlay overlay)))
    (when definition
      ;; A single-token definition is parsed as a link reference and its
      ;; body hidden as a URL.  Ordinary paragraph notes need no such reset.
      (when (treesit-parent-until
             (treesit-node-at begin treesit-primary-parser)
             (lambda (node) (equal (treesit-node-type node) "link_reference_definition")) t)
        (remove-list-of-text-properties begin definition-end
                                       '(face invisible display button category action help-echo)))
      (unless visible
        (font-lock-prepend-text-property begin definition-end
                                         'face 'my/markdown-footnote-text)))
    (remove-text-properties begin end '(invisible nil display nil))
    (make-text-button begin end
                      'follow-link t
                      'help-echo (format "脚注 %s：点击查看%s；M-, 返回"
                                         identifier (if definition "引用" "解释"))
                      'action (lambda (_button)
                                (my/markdown-footnote-jump identifier definition)))
    (unless visible
      ;; Reuse appear's copy filter: copied Markdown keeps its source text,
      ;; without carrying the display replacement into another buffer.
      (put-text-property begin end 'markdown-ts-appear--decoration t)
      (put-text-property
       begin end 'display
       (if definition
           (propertize (concat "[" identifier "]") 'face 'my/markdown-footnote-text)
         (propertize identifier 'face 'my/markdown-footnote-reference
                     'display '(raise 0.3)))))))

(defun my/markdown-fontify-footnotes (original begin end &optional verbose)
  "Call ORIGINAL for BEGIN..END with VERBOSE, then render its footnotes."
  (let ((result (funcall original begin end verbose)))
    (when (bound-and-true-p markdown-ts-appear-mode)
      (pcase result
        (`(jit-lock-bounds ,start . ,finish) (setq begin start end finish)))
      (save-excursion
        (goto-char begin)
        (with-silent-modifications
          (while (re-search-forward my/markdown-footnote-regexp end t)
            (let ((start (match-beginning 0))
                  (finish (match-end 0))
                  (identifier (match-string-no-properties 1)))
              (unless (my/markdown-footnote-ignored-context-p start)
                (my/markdown-footnote-render
                 start finish identifier (my/markdown-footnote-definition-p start))))))))
    result))

(defun my/markdown-footnotes-setup ()
  "Add compact footnotes to this Markdown buffer's normal fontification."
  ;; Only a buffer that is already rendering needs these; loading them here
  ;; rather than at the top keeps them out of startup.
  (require 'button)
  (require 'treesit)
  (require 'xref)
  (dolist (property '(display invisible button category action follow-link help-echo))
    (add-to-list 'font-lock-extra-managed-props property))
  (unless (advice-function-member-p #'my/markdown-fontify-footnotes
                                     font-lock-fontify-region-function)
    (add-function :around (local 'font-lock-fontify-region-function)
                  #'my/markdown-fontify-footnotes))
  (font-lock-flush))

;;; Interactive commands ---------------------------------------------------

(defun my/markdown-toggle-markup ()
  "Toggle Markdown markup display in the current buffer."
  (interactive)
  (cond
   ((derived-mode-p 'markdown-ts-mode)
    (require 'markdown-ts-appear)
    ;; appear renders the buffer; turning it off shows the raw source.
    (markdown-ts-appear-mode (if markdown-ts-appear-mode -1 1)))
   ((derived-mode-p 'markdown-mode)
    (require 'markdown-mode)
    (markdown-toggle-markup-hiding))
   (t (user-error "Not a Markdown buffer"))))

(defun my/markdown-toggle-images ()
  "Toggle inline image display in the current Markdown buffer."
  (interactive)
  (cond
   ((derived-mode-p 'markdown-ts-mode)
    (markdown-ts-toggle-inline-images))
   ((derived-mode-p 'markdown-mode)
    (require 'markdown-mode)
    (markdown-toggle-inline-images))
   (t (user-error "Not a Markdown buffer"))))

;;; Setup functions --------------------------------------------------------

;; Shared prose styling for both Markdown major modes.  Does not touch markup
;; hiding: each mode provides its own toggling.
(defun my/markdown-apply-reading-layout ()
  "Reading-oriented minor modes and modeline for a prose buffer."
  (valign-mode 1)
  (visual-line-mode 1)
  (my/prose-layout))

;; Reveal source only in Evil insert state (the pattern from the package's
;; README), so the buffer always looks rendered outside editing.
(defun my/markdown-ts-setup-evil-source-reveal ()
  "Reveal Markdown source only in Evil insert state."
  (if markdown-ts-appear-mode
      (progn
        (add-hook 'evil-insert-state-entry-hook #'markdown-ts-appear-start nil t)
        (add-hook 'evil-insert-state-exit-hook #'markdown-ts-appear-stop nil t)
        (unless (eq (bound-and-true-p evil-state) 'insert)
          (markdown-ts-appear-stop)))
    (remove-hook 'evil-insert-state-entry-hook #'markdown-ts-appear-start t)
    (remove-hook 'evil-insert-state-exit-hook #'markdown-ts-appear-stop t)))

(defun my/markdown-ts-mode-setup ()
  "Tree-sitter Markdown setup: appear plus shared prose styling."
  (require 'markdown-ts-appear)
  (add-hook 'markdown-ts-appear-mode-hook #'my/markdown-ts-setup-evil-source-reveal nil t)
  (markdown-ts-appear-mode 1)
  ;; The image-preview font-lock feature lives in the native mode's level-4
  ;; feature group, so customizing `markdown-ts-inline-images' alone renders
  ;; nothing: the feature must be recomputed per buffer, exactly what the
  ;; interactive toggle does (see `markdown-ts-toggle-inline-images').
  (when markdown-ts-inline-images
    (markdown-ts--set-inline-images t))
  (my/markdown-footnotes-setup)
  (my/markdown-apply-reading-layout))

;;; Declarations -----------------------------------------------------------

;; Keep file associations and hooks available at startup, but apply options
;; only after their library loads, before the first mode hook is run.
;; :ensure remains here so first-use autoloads also work on a fresh install.

;;; The default mode

;; Source/markup reveal on point.  Available from NonGNU ELPA (and MELPA), so
;; it is declared rather than only required at runtime: a machine without it
;; must install it, not fail to open .md.
(use-package markdown-ts-appear
  :ensure t
  :defer t
  :config
  ;; Plain rendering: the fence keeps raw ``` and gets no frame, label or
  ;; background slab.
  (setopt markdown-ts-appear-code-fence-style 'raw))

(use-package markdown-ts-mode
  :ensure nil                    ; built into Emacs 31
  :mode (("\\.md\\'" . markdown-ts-mode)
         ("\\.markdown\\'" . markdown-ts-mode)
         ("\\.mdown\\'" . markdown-ts-mode))
  :hook (markdown-ts-mode . my/markdown-ts-mode-setup)
  :config
  (setopt markdown-ts-inline-images t
          markdown-ts-hard-line-break-backslash nil
          markdown-ts-hard-line-break-space nil
          ;; Match org-modern's list glyphs (see init-ui.el for the faces).
          markdown-ts-unordered-list-marker
          '(("◦ " . "- ") ("– " . "- ") ("• " . "- "))
          markdown-ts-unchecked-checkbox '("□" . "-")))

(provide 'init-markdown)

;;; init-markdown.el ends here
