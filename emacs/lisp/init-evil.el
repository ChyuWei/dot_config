;;; init-evil.el --- Evil and its companions -*- lexical-binding: t; -*-

;;; Commentary:

;; Evil is only *declared* here: whether it is enabled depends on the
;; keybinding profile (see init-profile.el).  With the `emacs' profile Evil
;; is never loaded, so none of these packages cost anything at startup.
;; The Vim-specific keys live in init-keys-vim.el, the leader in
;; init-leader.el.

;;; Code:

;;; Part 1: Evil itself ----------------------------------------------------

;; Evil 1.15.0 reads `evil-initializing-p''s `evil-mode-buffers' in
;; `evil-normal-post-command' (post-command hook) but never gives the
;; variable a value, so every normal-state command logs
;; "(void-variable evil-mode-buffers)".  Initialize it here; `defvar'
;; only sets it when unbound, so a fixed Evil release keeps its own
;; value.
(defvar evil-mode-buffers nil)

(use-package evil
  :ensure t
  :defer t
  :init
  ;; These variables must be set before Evil is loaded.
  (setq evil-want-integration t
        ;; evil-collection manages the auxiliary mode keymaps itself.
        evil-want-keybinding nil
        ;; C-u keeps its Emacs meaning (universal-argument), like C-x its
        ;; prefix; C-i stays TAB so Org/Markdown folding and indentation
        ;; work normally.
        evil-want-C-u-scroll nil
        evil-want-C-i-jump nil
        ;; Vim's own Y (yank the whole line); keep the stock meaning.
        evil-want-Y-yank-to-eol nil)
  :config
  (setq evil-undo-system 'undo-redo
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-shift-width 4
        evil-cross-lines t
        evil-ex-search-vim-style-regexp t)
  ;; A quiet modal cursor: box in normal state, bar while inserting.
  (setq evil-normal-state-cursor '(box)
        evil-insert-state-cursor '(bar)
        evil-visual-state-cursor '(box "Orange"))
  ;; Insert-state TAB inserts one tab stop (4 spaces — `tab-width' and
  ;; `indent-tabs-mode' live in init-defaults.el) instead of running
  ;; `indent-for-tab-command', whose line-wide re-indent reads as
  ;; surprising "formatting".  Minor-mode maps win over major maps, so
  ;; this binding reaches every editing mode; normal state keeps Org's
  ;; heading and fold cycling on TAB.
  (define-key evil-insert-state-map (kbd "TAB") #'tab-to-tab-stop))

(use-package evil-collection
  :ensure t
  :after evil
  :init
  ;; Only the modes where Vim-like keys genuinely help; the rest keep
  ;; their Emacs bindings (and the SPC leader) untouched.
  (setq evil-collection-mode-list
        '(dired help ibuffer occur grep compile xref))
  :config
  (evil-collection-init))

;;; Part 2: companions -----------------------------------------------------

;; Declared only: `my/evil-companion-modes' enables them (one second after
;; startup, or immediately when switching profiles at run time).
(use-package evil-surround
  :ensure t
  :defer t)

(use-package evil-matchit
  :ensure t
  :defer t)

(use-package evil-mc
  :ensure t
  :defer t)

(defun my/evil-companion-modes (arg)
  "Enable or disable the Evil companion global modes by ARG.
Surround changes and deletes surroundings, matchit extends %, and mc
provides multiple cursors; all three are autoloaded, so this also loads
them on demand."
  (interactive "p")
  (dolist (mode '(global-evil-surround-mode
                  global-evil-matchit-mode
                  global-evil-mc-mode))
    (when (fboundp mode)
      (funcall mode arg))))

;;; Part 3: packages that also serve the `emacs' profile --------------------

;; A brief flash on the target line after a jump (imenu, consult jumps,
;; xref), so you can see where you landed.  The flash command loads on the
;; first jump; the hooks must be registered before that.
(use-package nav-flash
  :ensure t
  :defer t
  :init
  (dolist (hook '(consult-after-jump-hook xref-after-jump-hook))
    (add-hook hook #'nav-flash-show)))

;; SPC j j — flash-jump to any visible character by typing a few of them;
;; SPC j l — jump to a visible line.  Leader bindings live in init-leader.el.
(use-package avy
  :ensure t
  :defer t
  :custom
  (avy-all-windows nil)
  (avy-case-fold-search t))

;; Unified folding for Org, Markdown and any outline-ish buffer (the
;; package picks the right backend itself).  The z keys are part of the
;; `vim' profile (init-keys-vim.el); in the `emacs' profile outline's own
;; TAB/S-TAB do the job, and this global mode still serves both.
(use-package kirigami
  :ensure t
  :defer t
  :custom
  (kirigami-show-menu-bar nil)
  (kirigami-show-context-menu nil))

;;; Part 4: activation -----------------------------------------------------

(defun my/init-evil-activate ()
  "Enable the folding global mode.
Runs from `my/window-ready-hook' at depth 40, before any key is processed;
the z keys themselves are autoloaded, so nothing else waits for this."
  (require 'kirigami)
  (kirigami-global-mode 1))

(add-hook 'my/window-ready-hook #'my/init-evil-activate 40)

(provide 'init-evil)

;;; init-evil.el ends here
