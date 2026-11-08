;;; init-keys-vim.el --- Vim-specific keys (Evil profile) -*- lexical-binding: t; -*-

;;; Commentary:

;; Everything here is additive on top of stock Vim/Evil: Evil's own normal,
;; insert, visual and operator state maps are left alone except for the
;; entries listed below.  One group is different in kind: `e' in Emacs 31's
;; *grep*/*xref* result buffers has to be taken *back* from Evil's normal
;; state (see `my/vim-result-buffer-keys'), because those buffers' own `e'
;; command is more useful than `evil-forward-word-end' there.  Nothing in this
;; file applies to the `emacs' profile, and
;; `my/apply-vim-keybinding-overrides' can turn the whole set off again.

;;; Code:

(declare-function evil-global-set-key "evil")
(declare-function evil-local-set-key "evil")

(defconst my/vim-normal-state-keys
  '(;; Buffer and diagnostic cycling, unimpaired style.  H and L keep their
    ;; Vim meaning (top/bottom of the window) on purpose, and C-h stays the
    ;; Emacs help prefix (windows move with Vim's own C-w h/j/k/l).
    ("[ b" . previous-buffer)
    ("] b" . next-buffer)
    ("[ d" . flymake-goto-prev-error)
    ("] d" . flymake-goto-next-error)
    ("[ q" . previous-error)
    ("] q" . next-error))
  ;; g d keeps Evil's own `evil-goto-definition' (which calls xref, see
  ;; `my/apply-vim-lookup-overrides'); g r is left unbound like stock Evil, and
  ;; references stay on Emacs' own M-? (`xref-find-references').
  "Extra normal-state bindings of the `vim' profile.")

(defconst my/vim-fold-keys
  '(("zo" . kirigami-open-fold)
    ("zO" . kirigami-open-fold-rec)
    ("zc" . kirigami-close-fold)
    ("za" . kirigami-toggle-fold)
    ("zr" . kirigami-open-folds)
    ("zm" . kirigami-close-folds))
  "Vim-style folding keys, mapped onto kirigami.")

(defconst my/vim-result-buffer-keys
  '((grep grep-mode-map "e" grep-change-to-grep-edit-mode)
    (xref xref--xref-buffer-mode-map "e" xref-change-to-xref-edit-mode))
  "Emacs 31's edit-capable result buffers, keyed for the Vim profile.
`grep-edit-mode' and `xref-edit-mode' do what wgrep did: the *grep*/*xref*
buffer becomes writable, and `C-c C-c' writes the edits back to the files.
Both are entered with `e', which Evil's normal state takes for
`evil-forward-word-end' -- emulation maps outrank the major mode map -- so the
binding goes into normal state's auxiliary map for these keymaps instead.
Each entry is (FEATURE KEYMAP KEY COMMAND); nothing is loaded here, the
binding is installed when the library shows up.")

(defconst my/vim-save-states '(normal insert visual)
  "Evil states where C-s saves the buffer.")

(defconst my/vim-goto-definition-functions
  '(evil-goto-definition-xref
    evil-goto-definition-imenu
    evil-goto-definition-search)
  "Order used by `evil-goto-definition' (Vim's g d).
Evil's default tries imenu first, which in a long document can win over a
real LSP answer, so xref goes first here; `evil-goto-definition-search'
keeps g d useful in buffers without any index.")

(defconst my/vim-goto-definition-default
  '(evil-goto-definition-imenu
    evil-goto-definition-semantic
    evil-goto-definition-xref
    evil-goto-definition-search)
  "Evil's stock `evil-goto-definition-functions', restored when leaving vim.")

(defun my/lookup-documentation ()
  "Show documentation for the symbol at point (Vim's K).
Emacs Lisp symbols get their `describe-symbol' buffer; everything else is
asked of ElDoc, which under Eglot contains the LSP hover text."
  (interactive)
  (let* ((name (thing-at-point 'symbol t))
         (symbol (and name (intern-soft name))))
    (cond
     ((and symbol (or (fboundp symbol) (boundp symbol) (facep symbol)))
      (describe-symbol symbol))
     ((and (fboundp 'eldoc-doc-buffer)
           (progn (ignore-errors (eldoc-print-current-symbol-info)) t)
           (ignore-errors (eldoc-doc-buffer)))
      nil)
     (name (message "没有 %s 的文档" name))
     (t (user-error "光标处没有符号")))))

(defun my/apply-vim-lookup-overrides (state)
  "Point Evil's K at ElDoc and order g d around xref; undo with STATE off."
  (pcase state
    ('on
     (setq evil-lookup-func #'my/lookup-documentation
           evil-goto-definition-functions my/vim-goto-definition-functions))
    ('off
     (setq evil-lookup-func #'woman
           evil-goto-definition-functions my/vim-goto-definition-default))))

(defun my/vim-bind-result-buffer-key (enabled keymap key command)
  "In KEYMAP's normal state, bind KEY to COMMAND, or unbind it when not ENABLED.
KEYMAP is a symbol: it is resolved here because `evil-define-key' is a macro
that only recognises a keymap symbol written literally, and `evil-define-key*'
wants the keymap object.  A separate function, because `eval-after-load' is
given a form to evaluate later, which cannot see the caller's lexical
variables."
  (when (and (symbolp keymap) (boundp keymap))
    (evil-define-key* 'normal (symbol-value keymap) (kbd key)
                      (and enabled command))))

(defun my/apply-vim-result-buffer-keys (state)
  "Install (STATE `on') or remove (`off') `my/vim-result-buffer-keys'.
Deferred with `eval-after-load', so neither grep nor xref is pulled in at
startup; the native profile needs none of this, its major mode map already
carries the `e' binding."
  (let ((enabled (eq state 'on)))
    (dolist (entry my/vim-result-buffer-keys)
      (eval-after-load (nth 0 entry)
        `(my/vim-bind-result-buffer-key ,enabled ',(nth 1 entry)
                                        ,(nth 2 entry) ',(nth 3 entry))))))

(defun my/apply-vim-keybinding-overrides (state)
  "Apply Vim key overrides for STATE `on' or restore with `off'."
  (pcase state
    ('on
     (require 'evil)
     (dolist (entry my/vim-normal-state-keys)
       (define-key evil-normal-state-map (kbd (car entry)) (cdr entry)))
     (dolist (entry my/vim-fold-keys)
       (define-key evil-normal-state-map (kbd (car entry)) (cdr entry)))
     ;; C-a / C-u / C-x keep their Emacs meanings; no numeric-increment
     ;; keys are installed.
     (dolist (evil-state my/vim-save-states)
       (evil-global-set-key evil-state (kbd "C-s") #'save-buffer))
     (my/apply-vim-lookup-overrides 'on))
    ('off
     (when (featurep 'evil)
       (dolist (entry (append my/vim-normal-state-keys my/vim-fold-keys))
         (define-key evil-normal-state-map (kbd (car entry)) nil))
       (dolist (evil-state my/vim-save-states)
         (evil-global-set-key evil-state (kbd "C-s") nil))
       (my/apply-vim-lookup-overrides 'off))))
  (my/apply-vim-result-buffer-keys state))

(provide 'init-keys-vim)

;;; init-keys-vim.el ends here
