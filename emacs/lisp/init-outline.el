;;; init-outline.el --- Outline sidebar and breadcrumbs -*- lexical-binding: t; -*-

;;; Commentary:

;; Two complementary ways to see where you are in a document:
;;
;;   - breadcrumb: a header line with the file name and the current
;;     heading (or function/macro in code), updated as point moves;
;;   - imenu-list: a persistent outline in a side window, toggled with
;;     SPC o.
;;
;; Both are driven by Imenu, so they work in Markdown, Org, and
;; programming buffers alike.  Markdown and Org use the heading trees
;; their major modes already build; no extra parser is involved.

;;; Code:

(use-package breadcrumb
  :ensure t
  :init
  ;; The global mode adds the header line to file buffers.  The first
  ;; crumb is the plain file name (see below), the rest is the current
  ;; heading (or function/macro in code); the leaf is never
  ;; abbreviated, so the current section stays readable.  The package
  ;; reads `bc-…' in its source but keeps `breadcrumb-…' at runtime.
  (setq breadcrumb-imenu-max-length 0.55
        breadcrumb-imenu-crumb-separator " › ")
  (breadcrumb-mode 1)
  :config
  ;; The header line shows "file name : heading › subheading" — no
  ;; project/directory path, which would duplicate the mode line.
  (defun my/breadcrumb-header-line ()
    "Header line like `breadcrumb--header-line', but file name only."
    (mapconcat #'identity
               (cl-remove-if
                #'seq-empty-p
                (list
                 (propertize
                  (or (and buffer-file-name
                           (file-name-nondirectory buffer-file-name))
                      (buffer-name))
                  'face 'breadcrumb-project-leaf-face)
                 (breadcrumb-imenu-crumbs)))
               (propertize " : " 'face 'breadcrumb-face)))
  (advice-add #'breadcrumb--header-line :override #'my/breadcrumb-header-line)

  ;; `breadcrumb-mode' only turns on its buffer-local mode where it can
  ;; find a project.  Notes in ~/org and loose Markdown files are often
  ;; outside one, so enable it explicitly in prose buffers.
  (dolist (hook '(markdown-mode-hook markdown-ts-mode-hook org-mode-hook))
    (add-hook hook #'breadcrumb-local-mode)))

;; Breadcrumb builds its Imenu index from an idle timer (and observes
;; the index again after every buffer edit).  Without the warm-up below
;; the heading part of the header line stays empty on freshly opened
;; files that are never edited.
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

(use-package imenu-list
  :ensure t
  :init
  (setq imenu-list-position 'right
        imenu-list-size 26
        imenu-list-auto-update t
        imenu-list-idle-update-delay 0.5))

;; Both Markdown and Org put bookkeeping entries into their Imenu tree:
;; Markdown adds a "." node holding the parent heading's position, and
;; Org repeats every parent heading as a plain leaf next to its sublist.
;; The positions are useful (breadcrumb uses them to build the path), but
;; `imenu-list' and `consult-imenu' would also show the duplicates as
;; stray "." lines or repeated headings.  Clean only the tree copies
;; those two interfaces display; the original index stays untouched.
(require 'seq)

(defun my/imenu-clean-tree (entries)
  "Return a copy of Imenu ENTRIES without synthetic or duplicate nodes."
  (let (result prev-parent)
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
          (setq prev-parent nil))
         ((imenu--subalist-p entry)
          (push (cons (car entry)
                      (my/imenu-clean-tree (cdr entry)))
                result)
          (setq prev-parent name))
         ;; Org emits the parent heading again as a leaf immediately
         ;; after its sublist; skip only that adjacent duplicate.
         ((equal name prev-parent)
          (setq prev-parent nil))
         (t
          (push entry result)
          (setq prev-parent nil)))))
    (nreverse result)))

(defun my/imenu-list-clean-entries (orig &rest args)
  "Clean the Imenu tree shown by `imenu-list' after ORIG collects it."
  (apply orig args)
  (setq imenu-list--imenu-entries
        (my/imenu-clean-tree imenu-list--imenu-entries)))

(advice-add 'imenu-list-collect-entries
            :around #'my/imenu-list-clean-entries)

;; `consult-imenu' flattens the tree itself.  Markdown's "." nodes would
;; otherwise show up as completion candidates such as "Design .".
(defun my/consult-imenu-drop-pseudo (orig &rest args)
  "Remove pseudo Imenu entries from the candidates produced by ORIG."
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
