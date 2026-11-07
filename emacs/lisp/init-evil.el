;;; init-evil.el --- Modal editing with Evil -*- lexical-binding: t; -*-

;;; Commentary:

;; Vim-style modal editing for every buffer.  The leader key is SPC: it
;; is bound in normal, visual, motion and operator states, and the
;; bindings themselves live in init-keys.el next to the other personal
;; keys.  evil-collection gives Dired, help, ibuffer, grep, compile and
;; xref their usual Vim-like keys as well.

;;; Code:

;;; Modal editing ---------------------------------------------------------

;; Evil 1.15.0 reads `evil-initializing-p''s `evil-mode-buffers' in
;; `evil-normal-post-command' (post-command hook) but never gives the
;; variable a value, so every normal-state command logs
;; "(void-variable evil-mode-buffers)".  Initialize it here; `defvar'
;; only sets it when unbound, so a fixed Evil release keeps its own
;; value.
(defvar evil-mode-buffers nil)

(use-package evil
  :ensure t
  :init
  ;; These variables must be set before Evil is loaded.
  (setq evil-want-integration t
        ;; evil-collection manages the auxiliary mode keymaps itself.
        evil-want-keybinding nil
        ;; C-u scrolls like Vim; C-i stays TAB so Org/Markdown folding
        ;; and indentation work normally.
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-want-Y-yank-to-eol t)
  (when (fboundp 'evil-mode)
    (evil-mode 1))
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

;;; Jumping and text objects ---------------------------------------------

;; SPC j j — flash-jump to any visible character by typing a few of them;
;; SPC j l — jump to a visible line.  Leader bindings live in init-keys.el.
(use-package avy
  :ensure t
  :init
  (setq avy-all-windows nil
        avy-case-fold-search t))

;; Change and delete surroundings like Vim's surround plugin: ysiw(,
;; cs", ds( ...  It works on text objects in every buffer.
(use-package evil-surround
  :ensure t
  :init (global-evil-surround-mode 1))

;; % jumps between pairs of fences, tags and blocks (Markdown code
;; fences, HTML tags, org environments, parentheses...).
;; Loads one second after startup goes idle: the global mode is only
;; needed once you actually press %, and loading it also drags in
;; sh-script/semantic, which nothing else wants at launch.
(use-package evil-matchit
  :ensure t
  :defer t
  :init
  (run-with-idle-timer 1 nil #'global-evil-matchit-mode 1))

;; Multiple cursors load after one idle second, like evil-matchit.
;; Normal-state gr performs reference lookup; use M-x evil-mc-… for
;; cursor commands.  C-n/C-p/M-n/M-p retain the package's cursor navigation.
(use-package evil-mc
  :ensure t
  :defer t
  :init
  (run-with-idle-timer 1 nil #'global-evil-mc-mode 1))

;; A brief flash on the target line after a jump (imenu, consult jumps,
;; xref), so you can see where you landed.  No flash when the jump
;; stays on screen.  The flash command loads on the first jump; the
;; hooks must be registered before that.
(use-package nav-flash
  :ensure t
  :defer t
  :init
  (dolist (hook '(consult-after-jump-hook xref-after-jump-hook))
    (add-hook hook #'nav-flash-show)))

;; Vim's C-a (and C-x): numbers at point.  C-u -1 C-a decrements; 5 C-a
;; adds 5.
(use-package evil-numbers
  :ensure t
  :config
  (dolist (map (list evil-normal-state-map evil-visual-state-map))
    (define-key map (kbd "C-a") #'evil-numbers/inc-at-pt)))

;; Unified folding for Org, Markdown and any outline-ish buffer (the
;; package picks the right backend itself): Vim's usual z keys work the
;; same everywhere.
(use-package kirigami
  :ensure t
  :custom
  (kirigami-show-menu-bar nil)
  (kirigami-show-context-menu nil)
  :init
  (kirigami-global-mode 1)
  :config
  (dolist (binding '(("zo" . kirigami-open-fold)
                     ("zO" . kirigami-open-fold-rec)
                     ("zc" . kirigami-close-fold)
                     ("za" . kirigami-toggle-fold)
                     ("zr" . kirigami-open-folds)
                     ("zm" . kirigami-close-folds)))
    (define-key evil-normal-state-map (car binding) (cdr binding))))

(provide 'init-evil)

;;; init-evil.el ends here
