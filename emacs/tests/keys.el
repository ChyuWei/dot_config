;;; keys.el --- Keybinding profile regression checks -*- lexical-binding: t; -*-

;; Run from the repository root:
;; emacs -Q --batch -l emacs/tests/keys.el
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))
;; The configuration applies the profile from `my/window-ready-hook'; call it
;; directly here so the test does not also run the env import, which may spawn
;; a shell.
(my/apply-keybinding-profile my/keybinding-profile)
(require 'org)
(require 'consult)

(defun my/test-key (key)
  "Return the binding of KEY in a plain fundamental-mode buffer."
  (with-temp-buffer
    (fundamental-mode)
    (key-binding (kbd key))))

(defun my/test-evil-key (key &optional state)
  "Return KEY's binding in an Evil buffer, in STATE or normal state."
  (with-temp-buffer
    (fundamental-mode)
    (evil-local-mode 1)
    (evil-change-state (or state 'normal))
    (key-binding (kbd key))))

;;; Vim profile (the default) ----------------------------------------------

(unless (eq my/keybinding-profile 'vim)
  (error "The default profile should be vim, got %S" my/keybinding-profile))

(dolist (entry my/leader-bindings)
  (let* ((key (car entry))
         (command (cadr entry))
         (label (nth 2 entry))
         (display (which-key--maybe-replace
                   (cons (concat "SPC " key) (symbol-name command)))))
    (unless (and (eq (lookup-key my/leader-map (kbd key)) command)
                 (commandp command)
                 (if label (equal (cdr display) label) (null display)))
      (error "Binding or label mismatch: %S" entry))))

(dolist (entry my/leader-groups)
  (unless (and (keymapp (lookup-key my/leader-map (kbd (car entry))))
               (equal (cdr (which-key--maybe-replace
                            (cons (concat "SPC " (car entry)) "prefix")))
                      (cdr entry)))
    (error "Group mismatch: %S" entry)))

;; SPC is the leader in every Evil state, even where a mode binds SPC itself.
(dolist (mode '(fundamental-mode dired-mode help-mode))
  (with-temp-buffer
    (funcall mode)
    (evil-local-mode 1)
    (dolist (state '(normal visual motion operator))
      (evil-change-state state)
      (dolist (entry my/leader-bindings)
        (unless (eq (key-binding (kbd (concat "SPC " (car entry))) nil t)
                    (cadr entry))
          (error "Shadowed binding in %S/%S: %S" mode state entry))))))

;; Stock Vim keys survive the configuration.
(dolist (pair '(("SPC f f" . find-file) ("SPC SPC" . my/find-project-file)
                ("H" . evil-window-top) ("L" . evil-window-bottom)
                ("C-k" . kill-line) ("K" . evil-lookup)
                ("C-a" . move-beginning-of-line) ("C-u" . universal-argument)
                ("g d" . evil-goto-definition)
                ("C-s" . save-buffer)))
  (unless (eq (my/test-evil-key (car pair)) (cdr pair))
    (error "Vim key %s should be %s, got %S"
           (car pair) (cdr pair) (my/test-evil-key (car pair)))))

;; K keeps Vim's command but its keyword program is ElDoc; g d keeps Evil's
;; own command, whose first handler is xref.
(unless (eq evil-lookup-func #'my/lookup-documentation)
  (error "K should ask ElDoc, got %S" evil-lookup-func))
(unless (eq (car evil-goto-definition-functions) 'evil-goto-definition-xref)
  (error "g d should try xref first, got %S" evil-goto-definition-functions))

;; K on an Emacs Lisp symbol shows its documentation; non-elisp symbols go
;; to ElDoc (LSP hover).  Functional check only: Evil and this config are
;; natively compiled, so stubbing `xref-find-definitions' or `eldoc-doc-buffer'
;; with `cl-letf' would bypass nothing and prove nothing.
(with-temp-buffer
  (fundamental-mode)
  (insert "(car x)")
  (goto-char 2)
  (call-interactively #'evil-lookup)
  (unless (and (get-buffer "*Help*")
               (string-match-p "car" (with-current-buffer "*Help*" (buffer-string))))
    (error "K on an elisp symbol should open its documentation"))
  (when (get-buffer "*Help*") (kill-buffer "*Help*")))

;; g d still jumps inside an elisp buffer (xref backend), and its first
;; handler is xref before imenu.
(with-temp-buffer
  (emacs-lisp-mode)
  (insert "(defun alpha (x)\n  (* x 2))\n\n(alpha 3)\n")
  (goto-char (point-min))
  (search-forward "(alpha 3)")
  (goto-char (match-beginning 0))
  (call-interactively #'evil-goto-definition)
  (let ((line (buffer-substring-no-properties (line-beginning-position)
                                             (line-end-position))))
    (unless (string-prefix-p "(defun alpha" line)
      (error "g d should jump to the definition, landed in %S" line))))

;; g r stays unbound (as in stock Evil); references live on Emacs' M-?.
(unless (null (my/test-evil-key "g r"))
  (error "g r should be unbound, got %S" (my/test-evil-key "g r")))
(unless (eq (my/test-evil-key "M-?") #'xref-find-references)
  (error "M-? should keep xref-find-references, got %S" (my/test-evil-key "M-?")))

;; Ctrl-h/j/k/l are not repurposed: help and the Emacs defaults stay, and
;; windows move with Vim's own C-w (or the SPC w group).
(dolist (pair '(("C-h" . help-command) ("C-h f" . describe-function)
                ("C-j" . electric-newline-and-maybe-indent)
                ("C-k" . kill-line) ("C-l" . recenter-top-bottom)
                ("C-w k" . evil-window-up) ("C-w h" . evil-window-left)))
  (unless (eq (my/test-evil-key (car pair)) (cdr pair))
    (error "%s should be %s, got %S"
           (car pair) (cdr pair) (my/test-evil-key (car pair)))))

;; C-x stays the Emacs prefix, so native file commands keep working.
(unless (eq (my/test-evil-key "C-x") 'Control-X-prefix)
  (error "C-x must remain a prefix in normal state"))
(unless (eq (my/test-evil-key "C-x C-f") #'find-file)
  (error "C-x C-f should still open a file in normal state"))
;; M-. is stock Evil's repeat-pop in normal state; xref lives on g d there.
(unless (eq (my/test-evil-key "M-.") #'evil-repeat-pop-next)
  (error "M-. should keep Evil's repeat-pop, got %S" (my/test-evil-key "M-.")))

(with-temp-buffer
  (evil-local-mode 1)
  (evil-insert-state)
  (unless (eq (key-binding " ") #'self-insert-command)
    (error "Insert-state space is shadowed"))
  (unless (eq (key-binding (kbd "TAB")) #'tab-to-tab-stop)
    (error "Insert-state TAB binding changed")))

;; macOS Cmd keys are global, so both profiles keep them.
(dolist (pair '(("s-s" . save-buffer) ("s-c" . kill-ring-save)
                ("s-v" . clipboard-yank) ("s-z" . undo)
                ("s-f" . isearch-forward)))
  (unless (eq (my/test-key (car pair)) (cdr pair))
    (error "%s should be %s, got %S" (car pair) (cdr pair)
           (my/test-key (car pair)))))

;; Vim's `/`, `?`, `n`, `N` run through isearch here, so the isearch settings
;; in init-defaults.el apply to them (`C-s' is save-buffer, but it only decides
;; how a search starts, not how it behaves).
(unless (eq evil-search-module 'isearch)
  (error "Evil should search through isearch, got %S" evil-search-module))
(unless (eq (key-binding (kbd "/")) #'evil-search-forward)
  (error "/ should search forward, got %S" (key-binding (kbd "/"))))
(unless (eq (key-binding (kbd "n")) #'evil-search-next)
  (error "n should repeat the search, got %S" (key-binding (kbd "n"))))

;; Emacs 31's built-in wgrep replacement: `grep-edit-mode' and `xref-edit-mode'
;; make the result buffer writable and write the edits back with `C-c C-c'.
;; Both are entered with `e', which Evil's normal state would take for
;; `evil-forward-word-end', so the vim profile binds them per keymap.
(require 'grep)
(require 'xref)
(with-temp-buffer
  (grep-mode)
  (evil-local-mode 1)
  (evil-normal-state)
  (unless (eq (key-binding (kbd "e")) #'grep-change-to-grep-edit-mode)
    (error "e in *grep* should enter grep-edit-mode, got %S"
           (key-binding (kbd "e")))))
(with-temp-buffer
  (xref--xref-buffer-mode)
  (evil-local-mode 1)
  (evil-normal-state)
  (unless (eq (key-binding (kbd "e")) #'xref-change-to-xref-edit-mode)
    (error "e in *xref* should enter xref-edit-mode, got %S"
           (key-binding (kbd "e"))))
  ;; `r' batch-replaces the displayed references, writing to the files.
  (unless (eq (key-binding (kbd "r")) #'xref-query-replace-in-results)
    (error "r in *xref* should replace in results, got %S"
           (key-binding (kbd "r")))))

;;; dsh-emacs (an app, see init-app.el) --------------------------------------

;; dsh-emacs has no Evil support, and both of its buffers are read-only views
;; with their own single-key commands, so `:hook ... evil-emacs-state' in
;; init-app.el puts both in Evil's non-modal `emacs' state.  Load the two
;; libraries first: the app is only pulled in when it is used.
(require 'dsh-emacs)
(require 'dsh-emacs-session)

(with-temp-buffer
  (dsh-emacs-session-mode)
  (unless (eq evil-state 'emacs)
    (error "The dsh session list should use Evil's emacs state, got %S" evil-state))
  (dolist (pair '(("c" . dsh-emacs-new-session)
                  ("d" . dsh-emacs-archive-session-at-point)
                  ("r" . dsh-emacs-rename-session-at-point)
                  ("q" . quit-window)
                  ("RET" . dsh-emacs-open-session-at-point)))
    (unless (eq (key-binding (kbd (car pair))) (cdr pair))
      (error "%s should be %s in the dsh session list, got %S"
             (car pair) (cdr pair) (key-binding (kbd (car pair)))))))

(with-temp-buffer
  (dsh-emacs-mode)
  (unless (eq evil-state 'emacs)
    (error "The dsh chat buffer should use Evil's emacs state, got %S" evil-state))
  ;; Typing inserts, `C-c C-c' still sends, and ESC gets Vim back.
  (unless (eq (key-binding "a") #'self-insert-command)
    (error "Typing in the dsh chat should insert, got %S" (key-binding "a")))
  (unless (eq (key-binding (kbd "C-c C-c")) #'dsh-emacs-send-or-stop)
    (error "C-c C-c should send in the dsh chat, got %S"
           (key-binding (kbd "C-c C-c"))))
  (unless (eq (key-binding (kbd "M-p")) #'dsh-emacs-input-history-back)
    (error "M-p should recall input history, got %S" (key-binding (kbd "M-p"))))
  (evil-normal-state)
  (unless (eq (key-binding "c") #'evil-change)
    (error "ESC should hand the keys back to Vim, got %S" (key-binding "c"))))

;;; Emacs profile ----------------------------------------------------------

(defun my/snapshot-vim ()
  "Keybinding snapshot of the Vim profile."
  (list (my/test-evil-key "SPC f f") (my/test-evil-key "SPC b i")
        (my/test-evil-key "C-x C-f") (my/test-evil-key "H")
        (my/test-evil-key "C-a") (my/test-evil-key "C-s")))

(defun my/snapshot-emacs ()
  "Keybinding snapshot of the Emacs profile."
  (list (my/test-key "C-x C-f") (my/test-key "C-a") (my/test-key "C-h f")
        (my/test-key "M-.") (my/test-key "M-s r") (my/test-key "S-<left>")))

(defun my/cc-letter-bindings ()
  "Return the `C-c' + letter bindings visible in a plain buffer.
The Emacs profile installs none of its own, so this should be empty
outside major modes that use them."
  (with-temp-buffer
    (fundamental-mode)
    (let (found)
      (dolist (char (string-to-list "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"))
        (let* ((key (kbd (format "C-c %c" char)))
               (binding (key-binding key)))
          (when binding (push (cons (key-description key) binding) found))))
      (nreverse found))))

(let ((before (my/snapshot-vim))
      (which-key-before (length my/which-key-entries)))
  (my/apply-keybinding-profile 'emacs)
  (unless (eq my/keybinding-profile 'emacs) (error "Profile did not switch"))
  (unless (null (bound-and-true-p evil-mode)) (error "Evil should be off"))
  ;; No leader: the leader's commands are reachable only through
  ;; `my/leader-map', which this profile never installs.
  (dolist (command '(my/find-project-file my/switch-other-buffer))
    (when (where-is-internal command (list (current-global-map)) t)
      (error "%S is still bound in the Emacs profile" command)))

  ;; No leader at all: C-c is left entirely to the user and the modes.
  (unless (null (my/cc-letter-bindings))
    (error "C-c letters should stay free, found %S" (my/cc-letter-bindings)))
  (dolist (key '("C-c f f" "C-c b b" "C-c SPC" "C-c q q"
                 "C-c /" "C-c ." "C-c ;" "C-c -" "C-c |" "C-c `"))
    (when (my/test-key key)
      (error "%s should not be bound in the Emacs profile (%S)"
             key (my/test-key key))))

  ;; Native Emacs keys are untouched or improved, never removed.
  (dolist (pair '(("C-x C-f" . find-file) ("C-x C-s" . save-buffer)
                  ("C-x b" . switch-to-buffer)
                  ("C-a" . move-beginning-of-line) ("C-e" . move-end-of-line)
                  ("C-h f" . describe-function) ("M-." . xref-find-definitions)
                  ("M-s r" . consult-ripgrep) ("M-g i" . consult-imenu)
                  ("M-g g" . consult-goto-line) ("M-s l" . consult-line)
                  ("S-<left>" . windmove-left)
                  ("SPC" . self-insert-command)))
    (unless (eq (my/test-key (car pair)) (cdr pair))
      (error "%s should be %s, got %S" (car pair) (cdr pair) (my/test-key (car pair)))))

  ;; Major modes keep their C-c maps untouched, and Org's own keys work.
  (with-temp-buffer
    (org-mode)
    (dolist (pair '(("C-c C-e" . org-export-dispatch)
                    ("C-c ." . org-timestamp)
                    ("C-c ;" . org-toggle-comment)
                    ("C-c '" . org-edit-special)
                    ("C-c C-a" . org-attach)
                    ("C-c C-c" . org-ctrl-c-ctrl-c)
                    ("C-c C-t" . org-todo)
                    ("C-c t" . org-transclusion-add)
                    ("C-c r m" . org-remark-mark)))
      (unless (eq (key-binding (kbd (car pair))) (cdr pair))
        (error "Org key %s should be %s, got %S"
               (car pair) (cdr pair) (key-binding (kbd (car pair)))))))

  ;; which-key no longer advertises the Vim leader.
  (unless (null (my/leader-which-key-specs))
    (error "The Emacs profile should not register leader labels"))

  ;; Round trips must not duplicate keys or which-key entries.
  (let ((emacs-snapshot (my/snapshot-emacs)))
    (dotimes (_ 3)
      (my/apply-keybinding-profile 'vim)
      (my/apply-keybinding-profile 'emacs))
    (unless (equal emacs-snapshot (my/snapshot-emacs))
      (error "Emacs profile is not idempotent"))
    (unless (null (my/cc-letter-bindings))
      (error "C-c letters leaked after round trips: %S" (my/cc-letter-bindings)))
    (my/apply-keybinding-profile 'vim)
    (unless (equal before (my/snapshot-vim))
      (error "Vim profile is not idempotent"))
    (unless (= which-key-before (length my/which-key-entries))
      (error "which-key entries leak when returning to vim: %d -> %d"
             which-key-before (length my/which-key-entries)))))

;;; Consult ----------------------------------------------------------------

;; Consult constructs this map when SPC SPC falls back to fd outside a
;; project.  Checking only commandp does not catch invalid preview key syntax.
(with-temp-buffer
  (use-local-map minibuffer-local-map)
  (consult--setup-keymap nil t nil consult-preview-key)
  (unless (eq (lookup-key (current-local-map) (kbd "M-.")) #'ignore)
    (error "Consult preview key is missing")))

(princ "PASS: both keybinding profiles, native/Vim keys, which-key and idempotency\n")
