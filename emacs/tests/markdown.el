;;; markdown.el --- Markdown reading, footnotes and editing -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/markdown.el
;; The companion of lisp/init-markdown.el.  Org reading, the outline sidebar
;; and the completion stack are checked in tests/modes.el.
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))
;; The configuration applies the profile from `my/window-ready-hook'; call it
;; directly here so the test does not also run the env import, which may spawn
;; a shell.
(my/apply-keybinding-profile my/keybinding-profile)

;; Footnotes live in init-markdown.el, but the libraries they use must still
;; load with the first Markdown buffer, not with the configuration.  Asserted
;; before the buffer below loads markdown-ts-mode (and with it treesit).
(cl-assert (fboundp 'my/markdown-footnotes-setup))
(cl-assert (not (featurep 'treesit)))
(cl-assert (not (featurep 'xref)))

;;; Mode setup -------------------------------------------------------------

(with-temp-buffer
  (insert "# Parent\nBody\n## Child\nText\n")
  (markdown-ts-mode)
  (font-lock-ensure)
  ;; Check actual fontification and face heights, not only enabled modes.
  (cl-loop for height in '(2.0 1.7 1.4 1.1 1.0 1.0)
           for level from 1
           do (cl-assert (= (face-attribute
                             (intern (format "markdown-ts-heading-%d" level))
                             :height)
                            height)))
  (goto-char (point-min))
  (search-forward "Parent")
  (cl-assert (memq 'markdown-ts-heading-1
                   (ensure-list (get-text-property (1- (point)) 'face))))
  (cl-assert (not (bound-and-true-p indent-bars-mode)))
  (cl-assert (not (bound-and-true-p rainbow-delimiters-mode)))
  (cl-assert visual-line-mode)
  (cl-assert olivetti-mode)
  (cl-assert valign-mode)
  (cl-assert (not word-wrap))
  (cl-assert (not display-line-numbers-mode))
  (cl-assert (memq 'cape-dabbrev completion-at-point-functions))
  ;; The header line is installed by `my/header-line-setup' for files;
  ;; a temp buffer has none, so exercise the installer directly.
  (setq buffer-file-name (expand-file-name "probe.md" temporary-file-directory))
  (my/header-line-setup)
  (cl-assert (member '(:eval (my/header-line)) header-line-format))
  (cl-assert (= (cl-count '(:eval (my/reading-progress)) mode-line-misc-info :test #'equal) 1))
  (cl-assert markdown-ts-inline-images)
  (cl-assert (eq markdown-ts-appear-code-fence-style 'raw))
  (cl-assert markdown-ts-appear-mode)
  (evil-local-mode 1)
  (evil-normal-state)
  (evil-insert-state)
  (evil-normal-state))

;;; Footnotes -------------------------------------------------------------

(defun my/test-footnote-position (text)
  "Find TEXT from the start of the current buffer and return its start."
  (goto-char (point-min))
  (search-forward text)
  (match-beginning 0))

(with-temp-buffer
  (let ((source (concat
                 "# Heading\n\nReferences[^1] and [^long-note], again[^1].\n\n"
                 "`[^inline]` and \\[^escaped].\n\n"
                 "[ordinary](https://example.com/[^path]) and ![^alt](image.png).\n\n"
                 "```text\n[^fenced]: literal\n```\n\n"
                 "    [^indented]: literal\n\n"
                 "[^1]: 中文解释。\n\n"
                 "[^long-note]: English explanation with **bold** and [link](https://example.com).\n"
                 "    Continuation text.\n\n"
                 "    Another note paragraph.\n\n"
                 "Normal final paragraph.\n")))
    (insert source)
    (markdown-ts-mode)
    (evil-normal-state)
    (set-buffer-modified-p nil)
    (font-lock-ensure)
    (cl-assert (equal source (buffer-substring-no-properties (point-min) (point-max))))
    (cl-assert (not (buffer-modified-p)))

    (let* ((reference (my/test-footnote-position "[^1]"))
           (definition (my/test-footnote-position "[^1]:"))
           (display (get-text-property reference 'display)))
      (cl-assert (equal (substring-no-properties display) "1"))
      (cl-assert (eq (get-text-property 0 'face display) 'my/markdown-footnote-reference))
      (cl-assert (equal (get-text-property 0 'display display) '(raise 0.3)))
      (cl-assert (equal (substring-no-properties (get-text-property definition 'display)) "[1]"))
      (dolist (overlay (overlays-in reference (+ reference 4)))
        (cl-assert (not (overlay-get overlay 'markdown-ts-appear--link-icon))))
      ;; The existing appear copy filter must strip only presentation.
      (let ((copied (filter-buffer-substring reference (+ reference 4))))
        (cl-assert (equal copied "[^1]"))
        (cl-assert (not (get-text-property 0 'display copied))))
      (goto-char reference)
      (push-button)
      (cl-assert (= (point) definition))
      (xref-go-back)
      (cl-assert (= (point) reference))
      ;; Reveal while editing; restore the compact reference on leaving.
      (goto-char (+ reference 2))
      (evil-insert-state)
      (markdown-ts-appear-start)
      (font-lock-ensure reference (+ reference 4))
      (cl-assert (not (get-text-property reference 'display)))
      (evil-normal-state)
      (markdown-ts-appear-stop)
      (font-lock-ensure reference (+ reference 4))
      (cl-assert (stringp (get-text-property reference 'display))))

    (dolist (text '("中文解释" "English explanation" "Continuation text" "Another note paragraph"))
      (let ((position (my/test-footnote-position text)))
        (cl-assert (not (invisible-p position)))
        (cl-assert (memq 'my/markdown-footnote-text
                         (ensure-list (get-text-property position 'face))))))
    (let ((position (my/test-footnote-position "Normal final paragraph")))
      (cl-assert (not (memq 'my/markdown-footnote-text
                             (ensure-list (get-text-property position 'face))))))
    (dolist (text '("[^inline]" "[^escaped]" "[^path]" "[^alt]" "[^fenced]" "[^indented]"))
      (let ((position (my/test-footnote-position text)))
        (cl-assert (not (get-text-property position 'markdown-ts-appear--decoration)))))

    ;; Switching to source view must remove the presentation, not the text.
    (markdown-ts-appear-mode -1)
    (font-lock-ensure)
    (let ((position (my/test-footnote-position "[^1]")))
      (cl-assert (not (get-text-property position 'display))))
    (cl-assert (equal source (buffer-substring-no-properties (point-min) (point-max))))))

(with-temp-buffer
  (insert "Reference[^1].\n\n[^1]: Note.\n    Continuation.\n")
  (markdown-ts-mode)
  (font-lock-ensure)
  ;; Incremental repaint must not keep superscripts on ordinary links.
  (goto-char (my/test-footnote-position "[^1]"))
  (forward-char 1)
  (delete-char 1)
  (font-lock-ensure)
  (let ((position (my/test-footnote-position "[1]")))
    (cl-assert (not (get-text-property position 'markdown-ts-appear--decoration))))
  ;; Removing a definition must also remove its small-text styling.
  (goto-char (my/test-footnote-position "[^1]:"))
  (delete-char 5)
  (font-lock-ensure)
  (let ((position (my/test-footnote-position "Continuation")))
    (cl-assert (not (memq 'my/markdown-footnote-text
                           (ensure-list (get-text-property position 'face)))))))

(princ "PASS: Markdown mode setup, prose layout, footnotes and source reveal\n")
