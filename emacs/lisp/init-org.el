;;; init-org.el --- Org reading, capture and agenda -*- lexical-binding: t; -*-

;;; Commentary:

;; Org is set up as a readable document format first: indentation, modern
;; bullets and tags (org-modern), marker hiding (org-appear), centered prose,
;; pixel-aligned tables, inline images.  Capture and agenda use a small ~/org
;; tree.
;;
;; Org plus its ox/ob chain is the heaviest thing in the configuration, so it
;; is `:defer t': visiting an .org file (or `SPC n a' / `SPC n c') loads it.
;; The settings live in its `:config': loading this configuration module
;; only registers declarations and hooks.  Opening the first Org file or
;; using an Org command applies them before the first buffer is set up.
;;
;; Four parts:
;;
;;   1. the shared ~/org path,
;;   2. Org's options and setup (run only when Org loads),
;;   3. the enhancement packages,
;;   4. the per-buffer setup hook.

;;; Code:

(declare-function org-indent-initialize-agent "org-indent")
(declare-function org-modern-indent-mode "org-modern-indent")

;;; Part 1: settings -------------------------------------------------------

(setq org-directory (expand-file-name "~/org"))

;; The path is shared with org-remark below; the directory itself and
;; Org's settings are initialized only when Org is first loaded.

;;; Part 2: the Org declaration -------------------------------------------

(use-package org
  :ensure nil                    ; built into Emacs 31
  :defer t
  :config
  (make-directory org-directory t)
  (setq
   ;; Reading: hide syntax, show pretty entities, keep tags out of the way.
   org-startup-indented t
   org-startup-with-inline-images t
   org-image-actual-width '(800)
   org-hide-emphasis-markers t
   org-pretty-entities t
   org-ellipsis "…"
   org-hide-leading-stars t
   org-auto-align-tags nil
   org-tags-column 0
   org-agenda-tags-column 0
   ;; Imenu (and therefore the header line and the outline sidebar) sees the
   ;; whole heading tree, not just the first two levels.
   org-imenu-depth 8
   org-special-ctrl-a/e t
   org-insert-heading-respect-content t
   org-fold-catch-invisible-edits 'show-and-error
   org-use-sub-superscripts '{}

   ;; Source blocks behave like normal code buffers.
   org-src-fontify-natively t
   org-src-tab-acts-natively t
   org-src-preserve-indentation t
   org-src-content-indentation 0
   org-src-window-setup 'current-window

   ;; Agenda, refile and capture.
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
      "* %U\n%?\n" :empty-lines 1))

   ;; Code blocks.
   org-babel-python-command "python3"     ; macOS ships python3 only
   org-plantuml-exec-mode 'plantuml       ; the Homebrew binary, not java -jar
   org-confirm-babel-evaluate nil)        ; own notes: no prompt per block

  ;; Only reachable executables: what Org is allowed to run.
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t) (shell . t) (python . t)
     (sql . t) (sqlite . t) (org . t)
     (dot . t) (plantuml . t)))
  ;; Rust source blocks highlight through the built-in rust-ts-mode (its
  ;; grammar is installed; see the tree-sitter section of init-defaults.el).
  (add-to-list 'org-src-lang-modes '("rust" . rust-ts))
  ;; Exporters: Markdown (built in), GitHub-flavoured Markdown, Typst.
  (require 'ox)
  (add-to-list 'org-export-backends 'md))

;;; Part 3: enhancements ---------------------------------------------------

;; Auto-generated table of contents: a `TOC' heading tagged `:TOC:' is
;; rewritten on every save.
(use-package toc-org
  :ensure t
  :hook (org-mode . toc-org-mode))

;; Embed content from another file and keep it in sync: `C-c t' adds a
;; #+transclude: line, `C-c M-r' removes it.  (`C-c r' belongs to org-remark.)
(use-package org-transclusion
  :ensure t
  :after org
  :bind (:map org-mode-map
              ("C-c t" . org-transclusion-add)
              ("C-c M-r" . org-transclusion-remove)))

;; Navigate a document like slides: one heading per page, `SPC T' toggles.
(use-package org-tree-slide
  :ensure t
  :defer t
  :config
  (setopt org-tree-slide-skip-outline-level 0
          org-tree-slide-activate-message "Presentation started."
          org-tree-slide-deactivate-message "Presentation finished."))

;; Highlight and annotate while reading; notes and highlights live in
;; ~/org/remark.org.
(use-package org-remark
  :ensure t
  :hook ((org-mode . org-remark-mode)
         (markdown-mode . org-remark-mode)
         ;; .md files open in the built-in tree-sitter mode, not markdown-mode.
         (markdown-ts-mode . org-remark-mode))
  :bind (:map org-remark-mode-map
              ("C-c r m" . org-remark-mark)
              ("C-c r o" . org-remark-open)
              ("C-c r n" . org-remark-next)
              ("C-c r p" . org-remark-prev)
              ("C-c r d" . org-remark-remove))
  :config
  ;; The old name (`org-remark-notes-file-path') is only an obsolete alias;
  ;; setting it before the package loads loses the value, because the
  ;; `defvaralias' then points at `org-remark-notes-file-name' and keeps the
  ;; package default (a "marginalia.org" file in each directory).
  (setopt org-remark-notes-file-name
          (expand-file-name "remark.org" org-directory)))

;; Modern bullets, TODO keywords and timestamps; loaded by `my/org-setup'.
(use-package org-modern
  :ensure t
  :defer t)

;; Shows `*bold*', links and entities as source while point is inside them.
(use-package org-appear
  :ensure t
  :defer t
  :config
  (setopt org-appear-autoemphasis t
          org-appear-autolinks t
          org-appear-autoentities t
          org-appear-autosubmarkers t
          org-appear-delay 0.08))

;; Exporters that register themselves when Org loads.
(use-package ox-gfm
  :ensure t
  :after org
  :config
  (add-to-list 'org-export-backends 'gfm))

;; `typst' binary on PATH; `C-c C-e y p' exports straight to PDF.
(use-package ox-typst
  :ensure t
  :after org
  :config
  (add-to-list 'org-export-backends 'typst))

;; Block "brackets" that also work with org-indent (plain org-modern's fringe
;; borders cannot).  Not on any ELPA archive, so `:vc' fetches it from GitHub.
(use-package org-modern-indent
  :ensure nil
  :vc (:url "https://github.com/jdtsmith/org-modern-indent")
  :defer t)

;;; Part 4: per-buffer setup -----------------------------------------------

;; Depth 90: runs after `my/org-setup' has loaded org-modern.  Registered
;; here rather than from a deferred `:config', because otherwise the first Org
;; buffer of a session misses the brackets (the hook list was snapshotted
;; before org-modern loaded).
(add-hook 'org-mode-hook #'org-modern-indent-mode 90)

;; Kick the standard indentation agent if its own idle timer has not run.
(add-hook 'org-mode-hook
          (lambda ()
            (when (and (boundp 'org-indent-agentized-buffers)
                       (memq (current-buffer) org-indent-agentized-buffers))
              (run-with-idle-timer 0.5 nil #'org-indent-initialize-agent))))

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
