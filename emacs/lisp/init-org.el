;;; init-org.el --- Org reading, capture and agenda -*- lexical-binding: t; -*-

;;; Commentary:

;; Org is set up as a readable document format first: indentation, modern
;; bullets/tags (org-modern), marker hiding with org-appear, proportional
;; prose, aligned tables, inline images.  Capture and agenda are configured
;; with a small ~/org tree.

;;; Code:

(setq org-directory (expand-file-name "~/org"))
(make-directory org-directory t)

(use-package org
  :ensure nil
  ;; Org and its ox/ob exporter chain are the heaviest part of the
  ;; config (~600 ms measured).  It loads on first use instead: visiting
  ;; an .org file, org-mode, agenda (SPC n a), capture (SPC n c) — all are
  ;; autoloaded, and the package's own deferred :config runs then.
  :defer t
  :config
  (setq org-startup-indented t
        org-startup-with-inline-images t
        org-image-actual-width '(800)

        ;; Reading: hide syntax, show pretty entities, keep tags out of the
        ;; way.  org-appear reveals emphasis markers at point.
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-ellipsis "…"
        org-hide-leading-stars t
        org-auto-align-tags nil
        org-tags-column 0
        org-agenda-tags-column 0
        ;; Imenu (and therefore breadcrumb and the outline sidebar) sees
        ;; the whole heading tree, not just the first two levels.
        org-imenu-depth 8
        org-special-ctrl-a/e t
        org-insert-heading-respect-content t
        org-catch-invisible-edits 'show-and-error
        org-use-sub-superscripts '{}

        ;; Source blocks behave like normal code buffers.
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-edit-src-content-indentation 0
        org-src-window-setup 'current-window

        ;; Agenda and capture.
        org-log-done 'time
        org-agenda-files (list org-directory)
        org-agenda-window-setup 'current-window
        org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm
        org-capture-templates
        '(("t" "Task" entry
           (file+headline "~/org/inbox.org" "Tasks")
           "* TODO %?\n%U\n" :empty-lines 1)
          ("n" "Note" entry
           (file+headline "~/org/notes.org" "Notes")
           "* %?\n%U\n" :empty-lines 1)
          ("d" "Diary" entry
           (file+headline "~/org/diary.org" "Diary")
           "* %U\n%?\n" :empty-lines 1)))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t) (shell . t) (python . t)
     (sql . t) (sqlite . t) (org . t)
     (dot . t) (plantuml . t)))

  ;; use the Homebrew plantuml binary, not java -jar
  (setq org-plantuml-exec-mode 'plantuml)

  ;; Rust source blocks highlight through the built-in rust-ts-mode
  ;; (treesit-auto fetches its grammar on first use).
  (add-to-list 'org-src-lang-modes '("rust" . rust-ts))

  ;; macOS ships python3 only; ob-python defaults to "python".
  (setq org-babel-python-command "python3")

  ;; Running your own notes' code blocks without a prompt each time.
  (setq org-confirm-babel-evaluate nil)

  (require 'ox)
  (add-to-list 'org-export-backends 'md))

;; Reading and writing enhancements --------------------------------------

;; Auto-generated table of contents at the top: a `TOC' heading with the
;; :TOC: tag is rewritten on every save.
(use-package toc-org
  :ensure t
  :hook (org-mode . toc-org-mode))

;; Embed content from other files without copying it: #+transclude:
;; C-c t adds it, C-c r removes it.
(use-package org-transclusion
  :ensure t
  :after org
  :bind (:map org-mode-map
              ("C-c t" . org-transclusion-add)
              ("C-c r" . org-transclusion-remove)))

;; Navigate a document like slides: one heading per page, SPC T toggles.
(use-package org-tree-slide
  :ensure t
  :defer t
  :custom
  (org-tree-slide-skip-outline-level 0)
  (org-tree-slide-activate-message "Presentation started.")
  (org-tree-slide-deactivate-message "Presentation finished."))

;; Highlight & annotate while reading; notes and highlights live in
;; ~/org/remark.org and can be listed, followed and removed.
(use-package org-remark
  :ensure t
  :custom
  (org-remark-notes-file-path (expand-file-name "remark.org" org-directory))
  :hook ((org-mode . org-remark-mode)
         (markdown-mode . org-remark-mode))
  :bind (:map org-remark-mode-map
              ("C-c r m" . org-remark-mark)
              ("C-c r o" . org-remark-open)
              ("C-c r n" . org-remark-next)
              ("C-c r p" . org-remark-prev)
              ("C-c r d" . org-remark-remove)))

(use-package org-modern
  ;; Loads with the first Org buffer (org-modern-mode runs from
  ;; `my/org-setup'); plain Org is too heavy to load eagerly.
  :ensure t
  :defer t)

(use-package org-appear
  ;; Loads with the first Org buffer (org-appear-mode runs from
  ;; `my/org-setup'); don't drag Org into startup for it.
  :ensure t
  :defer t
  :custom
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autoentities t)
  (org-appear-autosubmarkers t)
  (org-appear-delay 0.08))

(use-package ox-gfm
  :ensure t
  :after org
  :config
  (add-to-list 'org-export-backends 'gfm))

;; org-modern-indent: block "brackets" that also work when org-indent
;; is enabled (plain org-modern's fringe borders cannot).  Installed
;; from GitHub with package-vc-install; the hook must be added late.
(use-package org-modern-indent
  :ensure nil
  :after (org org-modern)
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

;; Kick the standard indentation agent if its own idle timer has not run.
(add-hook 'org-mode-hook
          (lambda ()
            (when (and (boundp 'org-indent-agentized-buffers)
                       (memq (current-buffer) org-indent-agentized-buffers))
              (run-with-idle-timer 0.5 nil #'org-indent-initialize-agent))))

;; Export Org to Typst (typst binary on PATH; C-c C-e T builds PDF).
(use-package ox-typst
  :ensure t
  :after org
  :config
  (add-to-list 'org-export-backends 'typst))

(defun my/org-setup ()
  "Enable reading-oriented minor modes in the current Org buffer."
  (visual-line-mode 1)
  (org-modern-mode 1)
  (org-appear-mode 1)
  (valign-mode 1)
  (my/prose-layout))

(add-hook 'org-mode-hook #'my/org-setup)

(provide 'init-org)

;;; init-org.el ends here
