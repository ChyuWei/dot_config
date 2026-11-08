;;; init-outline.el --- Outline sidebar and header line -*- lexical-binding: t; -*-

;;; Commentary:

;; Two complementary ways to see where you are in a document:
;;
;;   - header line: the file name plus the current heading (or function,
;;     variable... in code), updated as point moves;
;;   - imenu-list: a persistent outline in a side window, toggled with SPC o.
;;
;; Both are driven by Imenu, so they work in Markdown, Org and programming
;; buffers alike.  Markdown and Org use the heading trees their major modes
;; already build; no extra parser is involved.
;;
;; Three parts: the header line, the sidebar, and the cleanup that hides the
;; bookkeeping entries Markdown and Org add to their Imenu trees.

;;; Code:

;; `imenu' is used directly below (`imenu--subalist-p' and the index warm-up
;; at the end of part 1); `imenu-list' no longer loads it implicitly since it
;; is deferred.
(require 'imenu)
(require 'seq)

;;; Part 1: header line ----------------------------------------------------

;; Built from breadcrumb's public, autoloaded `breadcrumb-imenu-crumbs' rather
;; than by advising its private `breadcrumb--header-line': no advice, and the
;; file name stays short (no project path, which the mode line does not repeat
;; either).  The package's sources spell these names `bc-…' through
;; `read-symbol-shorthands'; the runtime names are the long ones used here.
(use-package breadcrumb
  :ensure t
  :defer t
  :custom
  (breadcrumb-imenu-max-length 0.55)
  (breadcrumb-imenu-crumb-separator " › "))

(defun my/header-line-crumbs ()
  "Return the current heading path, or nil.
The tree-sitter Markdown Imenu puts every heading below a single \"Headings\"
node and keeps the \"#\" level markers in the entry names; both are removed
here so the header reads like the buffer does."
  (let ((crumbs (ignore-errors (breadcrumb-imenu-crumbs))))
    ;; The separator is read only after the call above, which is what loads
    ;; the deferred package (and with it the defcustom).
    (when (and (stringp crumbs) (not (string-empty-p crumbs)))
      (let* ((separator (if (boundp 'breadcrumb-imenu-crumb-separator)
                            breadcrumb-imenu-crumb-separator
                          " › "))
             (parts (split-string crumbs (regexp-quote separator) t "[ \t\n]+"))
             (marked (seq-some (lambda (part)
                                 (string-match-p "\\`#" (string-trim part)))
                               parts)))
        (setq parts (delq nil
                          (mapcar (lambda (part)
                                    (let ((text (string-trim
                                                 (replace-regexp-in-string
                                                  "\\`#+[ \t]*" "" part))))
                                      (unless (or (string-empty-p text)
                                                  (and marked (equal text "Headings")))
                                        text)))
                                  parts)))
        (when parts
          (mapconcat (lambda (part)
                       (propertize part 'face 'breadcrumb-imenu-crumbs-face))
                     parts separator))))))

(defun my/header-line ()
  "Return the header line for this buffer: file name and heading path."
  (let ((name (and buffer-file-name
                   (file-name-nondirectory buffer-file-name)))
        (crumbs (my/header-line-crumbs)))
    (when (or name crumbs)
      (mapconcat #'identity
                 (delq nil (list (and name (propertize name
                                                       'face 'breadcrumb-project-leaf-face))
                                 crumbs))
                 (propertize " : " 'face 'breadcrumb-face)))))

(defun my/header-line-setup ()
  "Show `my/header-line' at the top of the current file buffer."
  (when buffer-file-name
    (unless (member '(:eval (my/header-line)) header-line-format)
      (setq-local header-line-format
                  (append (ensure-list header-line-format)
                          '((:eval (my/header-line))))))))

(add-hook 'find-file-hook #'my/header-line-setup)

;; Breadcrumb builds its Imenu index from an idle timer.  Without this warm-up
;; the heading part of the header line stays empty on freshly opened files
;; that are never edited.
(add-hook 'find-file-hook
          (lambda ()
            (run-with-idle-timer
             1.5 nil
             (lambda (buffer)
               (when (buffer-live-p buffer)
                 (with-current-buffer buffer
                   (ignore-errors
                     (let ((imenu-auto-rescan t))
                       (setq-local imenu--index-alist
                                   (imenu--make-index-alist t)))))))
             (current-buffer))))

(defun my/jump-to-heading ()
  "Jump to a heading, using Org's own heading list when available."
  (interactive)
  (if (derived-mode-p 'org-mode)
      (consult-org-heading)
    (consult-imenu)))

;;; Part 2: outline sidebar ------------------------------------------------

(use-package imenu-list
  :ensure t
  :defer t                        ; loaded by its first command
  :init
  (setq imenu-list-position 'right
        imenu-list-size 26
        imenu-list-auto-update t
        imenu-list-idle-update-delay 0.5))

;;; Part 3: cleaning the Imenu tree ----------------------------------------

;; Markdown and Org both add bookkeeping entries to their Imenu trees:
;; Markdown a "." node holding the parent heading's position (and "-" when
;; levels are skipped), Org a copy of every parent heading next to its
;; sublist.  The positions are useful (the header line builds the path from
;; them); the sidebar and `consult-imenu' would show the duplicates as stray
;; "." lines or repeated headings.  Clean only the copies those two interfaces
;; display; the original index stays untouched.

(defun my/imenu-clean-tree (entries)
  "Return a copy of Imenu ENTRIES without synthetic or duplicate nodes."
  (let (result previous-parent-heading)
    (dolist (entry entries)
      (let ((name (substring-no-properties (car entry))))
        (cond
         ;; Markdown's pseudo headings: "." is the parent's own position,
         ;; "-" fills a gap when heading levels are skipped.  Splice the
         ;; children of "-" into the real parent.
         ((member name '("." "-"))
          (when (imenu--subalist-p entry)
            (dolist (child (my/imenu-clean-tree (cdr entry)))
              (push child result)))
          (setq previous-parent-heading nil))
         ((imenu--subalist-p entry)
          (push (cons (car entry)
                      (my/imenu-clean-tree (cdr entry)))
                result)
          (setq previous-parent-heading name))
         ;; Org emits the parent heading again as a leaf immediately
         ;; after its sublist; skip only that adjacent duplicate.
         ((equal name previous-parent-heading)
          (setq previous-parent-heading nil))
         (t
          (push entry result)
          (setq previous-parent-heading nil)))))
    (nreverse result)))

(defun my/imenu-list-clean-entries (orig &rest args)
  "Clean the Imenu tree shown by `imenu-list' after ORIG collects it."
  (apply orig args)
  (setq imenu-list--imenu-entries
        (my/imenu-clean-tree imenu-list--imenu-entries)))

(advice-add 'imenu-list-collect-entries
            :around #'my/imenu-list-clean-entries)

(defun my/consult-imenu-drop-pseudo (orig &rest args)
  "Remove pseudo Imenu entries from the candidates produced by ORIG.
`consult-imenu' flattens the tree itself, so Markdown's \".\" nodes would
otherwise show up as candidates such as \"Design .\"."
  (seq-remove
   (lambda (candidate)
     (let ((name (substring-no-properties (car candidate))))
       (or (equal name ".")
           (string-suffix-p " ." name))))
   (apply orig args)))

(advice-add 'consult-imenu--compute
            :around #'my/consult-imenu-drop-pseudo)

(provide 'init-outline)

;;; init-outline.el ends here
