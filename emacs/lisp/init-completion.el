;;; init-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Commentary:

;; The small, composable completion stack:
;;   vertico + orderless + marginalia + consult + embark
;; for the minibuffer, and corfu + cape for in-buffer completion.

;;; Code:

;;; Minibuffer completion -------------------------------------------------

(use-package vertico
  :ensure t
  :init (vertico-mode 1)
  :custom
  (vertico-cycle t)
  (vertico-count 12)
  (vertico-resize t))

(use-package orderless
  :ensure t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        ;; File names keep the familiar partial-completion behaviour;
        ;; everything else uses orderless.
        completion-category-overrides
        '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :init (marginalia-mode 1)
  :custom
  (marginalia-align 'right))

(use-package consult
  :ensure t
  :bind (("M-y" . consult-yank-pop))
  :config
  ;; Preview files, buffers and grep hits only on demand, with M-.
  (setq consult-preview-key "M-.")
  ;; "<" narrows a multi-source search (buffers, files, bookmarks, ...).
  (setq consult-narrow-key "<"))

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

;;; In-buffer completion --------------------------------------------------

(use-package corfu
  :ensure t
  :init (global-corfu-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  (corfu-quit-no-match 'separator)
  (corfu-popupinfo-delay '(0.4 . 0.2))
  :config
  (corfu-popupinfo-mode 1))

;; Add word completion locally in prose and code, including Chinese text.
(use-package cape
  :ensure t
  :init
  (dolist (hook '(text-mode-hook prog-mode-hook))
    (add-hook hook
              (lambda ()
                (add-hook 'completion-at-point-functions
                          #'cape-dabbrev nil t)))))

;;; Key discovery ---------------------------------------------------------

(use-package which-key
  :ensure nil
  :init (which-key-mode 1)
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

(provide 'init-completion)

;;; init-completion.el ends here
