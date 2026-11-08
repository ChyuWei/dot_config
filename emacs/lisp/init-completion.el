;;; init-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Commentary:

;; The small, composable completion stack:
;;   vertico + orderless + marginalia + consult + embark
;; for the minibuffer, and corfu + cape for in-buffer completion.
;;
;; Three parts, in this order:
;;
;;   1. Settings    -- completion styles and `defcustom's.  Load time.
;;   2. Definitions -- the `use-package' declarations; every package is
;;                     `:defer t' and only keys/autoloads are registered.
;;   3. Activation  -- `my/init-completion-activate' loads the four modes that
;;                     must be on before the first completion.  It runs from
;;                     `my/window-ready-hook', i.e. before Emacs processes any
;;                     key, so the first `M-x' or `SPC' already uses it.

;;; Code:

;;; Part 1: settings -------------------------------------------------------

;; Orderless matches space-separated fragments in any order; file names keep
;; the familiar partial-completion behaviour.
(use-package orderless
  :ensure t
  :defer t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles basic partial-completion)))))

;;; Part 2: definitions ----------------------------------------------------

;;; Minibuffer completion

;; `M-SPC' (insert a `corfu-separator') and `corfu-quit-at-boundary 'separator'
;; ship with Corfu 2.x, which is what makes orderless multi-word filtering work
;; with automatic completion -- no extra binding needed.  `C-d' / `M-.' are
;; bound on `corfu-map' in the declaration below.

(use-package vertico
  :ensure t
  :defer t
  :custom
  (vertico-cycle t)
  (vertico-count 12)
  (vertico-resize t))

(use-package marginalia
  :ensure t
  :defer t
  :custom
  (marginalia-align 'right))

(use-package consult
  :ensure t
  :bind (("M-y" . consult-yank-pop))
  :custom
  ;; Preview files, buffers and grep hits only on demand, with M-.
  (consult-preview-key "M-.")
  ;; "<" narrows a multi-source search (buffers, files, bookmarks, ...).
  (consult-narrow-key "<"))

(use-package embark
  :ensure t
  :bind (:map minibuffer-local-map
              ;; The leader key cannot work in the minibuffer, where
              ;; SPC must insert a space; keep the conventional keys
              ;; there only.
              ("C-." . embark-act)
              ("C-;" . embark-dwim))
  :config
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :ensure t
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;; In-buffer completion

(use-package corfu
  :ensure t
  :defer t
  ;; Documentation and definition of the selected candidate, in their own
  ;; buffers instead of the inline popupinfo; active only while the popup is
  ;; shown.  `bind-keys :package' keeps them deferred until corfu loads.
  :bind (:map corfu-map
              ("C-d" . corfu-info-documentation)
              ("M-." . corfu-info-location))
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  (corfu-quit-no-match 'separator)
  (corfu-popupinfo-delay '(0.4 . 0.2)))

;; Add word completion locally in prose and code, including Chinese text.
;; `cape-dabbrev' is autoloaded, so this registers nothing heavy.
(use-package cape
  :ensure t
  :init
  (dolist (hook '(text-mode-hook prog-mode-hook))
    (add-hook hook
              (lambda ()
                (add-hook 'completion-at-point-functions
                          #'cape-dabbrev nil t)))))

;;; Templates

(defun my/tempel-setup-completion ()
  "Offer exact template-name matches before ordinary buffer completion.
Only register the autoloaded Capf here; Tempel and its template collection
load when completion first needs them.  A negative depth keeps this ahead
of Eglot even when its server connects after the mode hook has run."
  (add-hook 'completion-at-point-functions #'tempel-expand -90 t))

(use-package tempel
  :ensure t
  :commands (tempel-expand tempel-complete tempel-insert)
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert))
  :hook ((prog-mode text-mode conf-mode) . my/tempel-setup-completion))

;; Use the maintained template collection; no local template corpus to sync.
(use-package tempel-collection
  :ensure t
  :after tempel)

;;; Directory jumping

;; `zoxide' remembers directories by frecency, which covers the ones that are
;; not projects at all (`project-switch-project' cannot see those).  The list
;; is read with `zoxide query --list' on demand, so nothing runs at startup.
(use-package consult-zoxide
  :ensure t
  :defer t)

;;; Key discovery

(use-package which-key
  :ensure nil
  :defer t
  :custom
  (which-key-idle-delay 0.4)
  (which-key-idle-secondary-delay 0.05)
  (which-key-popup-type 'side-window)
  (which-key-side-window-location 'bottom)
  (which-key-side-window-max-height 0.35)
  (which-key-show-prefix 'top)
  (which-key-sort-order 'which-key-prefix-then-key-order)
  (which-key-sort-uppercase-first nil)
  (which-key-max-description-length 28)
  (which-key-separator "  ")
  (which-key-add-column-padding 3))

;;; Part 3: activation -----------------------------------------------------

(defun my/init-completion-activate ()
  "Load and enable the completion modes.
Runs from `my/window-ready-hook': the first minibuffer or `SPC' press comes
after that, so nothing has to be loaded earlier."
  (require 'vertico)
  (vertico-mode 1)
  (require 'marginalia)
  (marginalia-mode 1)
  (require 'corfu)
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1)
  (which-key-mode 1))

(add-hook 'my/window-ready-hook #'my/init-completion-activate 40)

(provide 'init-completion)

;;; init-completion.el ends here
