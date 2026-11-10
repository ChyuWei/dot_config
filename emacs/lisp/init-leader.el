;;; init-leader.el --- Leader key and its commands -*- lexical-binding: t; -*-

;;; Commentary:

;; `my/leader-bindings' is the feature table of the `vim' profile: SPC in
;; Evil's normal, visual, motion and operator state (`my/leader-map').
;;
;; The `emacs' profile deliberately has no leader.  Mirroring this table
;; under `C-c' produced very un-native Emacs -- three-key chords duplicating
;; what `C-x', `M-g', `M-s' and the major modes already do -- so that
;; profile uses native Emacs keys only, and feature commands live on `M-x'.
;; Hidden compatibility aliases (nil label) are Vim-only.

;;; Code:

;;; Bindings and menu labels --------------------------------------------------------------

;; LazyVim-style keys: each entry declares its command and menu label once.
;; A nil label keeps a compatibility alias usable but hidden in which-key.
;; https://www.lazyvim.org/keymaps
(defconst my/leader-bindings
  '(("SPC" my/find-project-file "Find project file")
    ("," consult-buffer "Switch buffer")
    ("/" consult-ripgrep "Search project")
    (":" execute-extended-command "Execute command")
    ("." scratch-buffer "Open scratch")
    ("e" my/dirvish-side "Toggle file sidebar")
    ("E" dired-jump "Open file's directory")
    ("-" split-window-below "Split below")
    ("|" split-window-right "Split right")
    ("`" my/switch-other-buffer nil)
    ("b b" my/switch-other-buffer "Previous buffer")
    ("b s" scratch-buffer "Open scratch")
    ("b i" ibuffer "List buffers")
    ("b d" kill-current-buffer "Kill buffer")
    ("b D" kill-buffer-and-window "Kill buffer and window")
    ("b j" consult-buffer "Select buffer")
    ("f f" find-file "Open file (like C-x C-f)")
    ("f F" consult-fd "Find files in directory")
    ("f d" my/dirvish-fd "fd results (editable dired)")
    ("f b" consult-buffer "Switch buffer")
    ("f c" my/open-init-file "Open Emacs config")
    ("f e" my/dirvish-side "Toggle file sidebar")
    ("f z" consult-zoxide "Jump to recent directory")
    ("f E" dired-jump "Open file's directory")
    ("f n" my/new-file "New file")
    ("f r" consult-recent-file "Recent files")
    ("f p" project-switch-project "Switch project")
    ("f s" save-buffer "Save file")
    ("f t" project-shell "Open project shell")
    ("f T" shell "Open shell")
    ("s b" consult-line "Search current buffer")
    ("s g" consult-ripgrep "Search project")
    ("s G" my/grep-directory "Search directory")
    ("s s" my/jump-to-heading "Jump to heading / symbol")
    ("s r" query-replace "Find and replace")
    ("s c" consult-history "Input history")
    ("s C" execute-extended-command "Execute command")
    ("s h" apropos-command "Search help")
    ("s k" describe-bindings "Show key bindings")
    ("s m" consult-mark "Jump to mark")
    ("s d" consult-flymake "Search diagnostics")
    ("s H" symbol-overlay-put "Mark / unmark symbol")
    ("s n" symbol-overlay-jump-next "Next same symbol")
    ("s p" symbol-overlay-jump-prev "Previous same symbol")
    ("s u" symbol-overlay-remove-all "Clear symbol marks")
    ("w h" windmove-left "Window left")
    ("w j" windmove-down "Window down")
    ("w k" windmove-up "Window up")
    ("w l" windmove-right "Window right")
    ("w w" other-window "Next window")
    ("w d" delete-window "Close window")
    ("w m" delete-other-windows "Only this window")
    ("w -" split-window-below "Split below")
    ("w |" split-window-right "Split right")
    ("c a" eglot-code-actions "Code actions")
    ("c r" eglot-rename "Rename symbol")
    ("c f" eglot-format "Format code")
    ("c l" eglot "Connect LSP")
    ("c q" eglot-shutdown "Disconnect LSP")
    ("c R" eglot-reconnect "Reconnect LSP")
    ("c d" flymake-show-buffer-diagnostics "Buffer diagnostics")
    ("c g" evil-goto-definition "Go to definition")
    ("c G" xref-find-references "Find references")
    ("c b" xref-go-back "Go back")
    ("c s" imenu-list-smart-toggle "Toggle symbol outline")
    ("g g" magit-status "Git status")
    ("g s" magit-status "Git status")
    ("g d" magit-diff-working-tree "Working tree diff")
    ("g b" magit-blame "Blame")
    ("g f" magit-log-buffer-file "File history")
    ("g l" magit-log-current "Repo history")
    ("u w" visual-line-mode "Toggle word wrap")
    ("u l" display-line-numbers-mode "Toggle line numbers")
    ("u d" flymake-mode "Toggle diagnostics")
    ("u z" olivetti-mode "Toggle centered writing")
    ("u c" my/markdown-toggle-markup "Toggle Markdown markup")
    ("u m" mode-line-invisible-mode "Toggle mode line")
    ("q q" save-buffers-kill-emacs "Quit Emacs (prompt save)")
    ("n a" org-agenda "Open agenda")
    ("n c" org-capture "Capture note")
    ("n l" org-store-link "Store link")
    ("i" consult-imenu nil)
    ("o" imenu-list-smart-toggle nil)
    ("h" my/jump-to-heading nil)
    ("a" org-agenda nil)
    ("l" org-store-link nil)
    ("r" consult-ripgrep nil)
    (";" embark-dwim "Embark DWIM")
    ("T" org-tree-slide-mode "Toggle outline slides")
    ("A d" dsh-emacs "AI session (DeepSeek Harness)")
    ("j j" avy-goto-char-timer "Jump to char")
    ("j l" avy-goto-line "Jump to line")
    ("m h" my/markdown-toggle-markup "Toggle markup")
    ("m i" my/markdown-toggle-images "Toggle inline images")
    ("m ." embark-act "Act on object"))
  "Leader bindings as (KEY COMMAND LABEL); nil LABEL hides the entry.")

(defconst my/leader-macos-bindings
  (when (eq system-type 'darwin)
    '(("A a" appine "Appine (Browser / PDF)")
      ("A u" appine-open-url "Open URL in Appine")
      ("A o" appine-open-file "Open file in Appine")))
  "Leader bindings for macOS-only applications.")

(defconst my/leader-groups
  '(("b" . "+Buffers")
    ("f" . "+Files / Projects")
    ("s" . "+Search / Jump")
    ("w" . "+Windows")
    ("c" . "+Code")
    ("g" . "+Git")
    ("u" . "+Display / Toggles")
    ("q" . "+Quit")
    ("n" . "+Org Notes")
    ("m" . "+Markdown / Actions")
    ("j" . "+On-screen Jumps")
    ("A" . "+Apps"))
  "Leader prefix keys and their which-key labels.")

;;; The Vim-side map -------------------------------------------------------

(defvar my/leader-map (make-sparse-keymap)
  "Prefix map bound to SPC in the `vim' profile.")

(defvar my/leader-jump-map (make-sparse-keymap)
  "`j' group: on-screen jumps.")

(defvar my/leader-markdown-map (make-sparse-keymap)
  "`m' group: Markdown and object actions.")

(dolist (group my/leader-groups)
  (define-key my/leader-map (kbd (car group))
              (pcase (car group)
                ("j" my/leader-jump-map)
                ("m" my/leader-markdown-map)
                (_ (make-sparse-keymap)))))

(dolist (binding (append my/leader-bindings my/leader-macos-bindings))
  (define-key my/leader-map (kbd (car binding)) (cadr binding)))

;; Most built-in commands already have autoloads.  Add only the missing
;; interactive entry points; binding a key must not load Eglot/Org at startup.
(dolist (entry '((eglot-code-actions . "eglot")
                 (eglot-format . "eglot")
                 (eglot-rename . "eglot")
                 (eglot-shutdown . "eglot")
                 (eglot-reconnect . "eglot")
                 (flymake-goto-prev-error . "flymake")
                 (flymake-goto-next-error . "flymake")
                 (flymake-show-buffer-diagnostics . "flymake")
                 (org-store-link . "ol")))
  (autoload (car entry) (cdr entry) nil t))

;;; Install / uninstall ----------------------------------------------------

(defun my/leader-evil-local-setup ()
  "Make SPC the leader in the current buffer's Evil state maps.
Several major modes (Dired and everything derived from `special-mode',
such as help, grep and the outline sidebar) bind SPC in their local map,
which would shadow the global leader; a buffer-local Evil binding has
higher precedence than the major mode map."
  (when (and (eq my/keybinding-profile 'vim)
             (bound-and-true-p evil-local-mode))
    (dolist (state '(normal visual motion operator))
      (evil-local-set-key state (kbd "SPC") my/leader-map))))

(defun my/leader-install-vim ()
  "Bind `my/leader-map' to SPC in Evil's states."
  (require 'evil)
  (dolist (state '(normal visual motion operator))
    (evil-global-set-key state (kbd "SPC") my/leader-map))
  (add-hook 'evil-local-mode-hook #'my/leader-evil-local-setup)
  ;; Buffers that already exist will not run the hook again.
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (my/leader-evil-local-setup))))

(defun my/leader-uninstall-vim ()
  "Remove the SPC leader from Evil's global and local state maps."
  (remove-hook 'evil-local-mode-hook #'my/leader-evil-local-setup)
  (when (featurep 'evil)
    (dolist (state '(normal visual motion operator))
      (evil-global-set-key state (kbd "SPC") nil))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (bound-and-true-p evil-local-mode)
          (dolist (state '(normal visual motion operator))
            (evil-local-set-key state (kbd "SPC") nil)))))))

(defun my/leader-install ()
  "Install the leader when the `vim' profile is active."
  (if (eq my/keybinding-profile 'vim)
      (my/leader-install-vim)
    (my/leader-uninstall-vim)))

(defun my/leader-uninstall ()
  "Remove the leader, leaving no stale keys behind."
  (my/leader-uninstall-vim))

;;; Which-key --------------------------------------------------------------

(defvar my/which-key-entries nil
  "which-key entries pushed by this configuration, for later removal.")

(defun my/leader-which-key-specs ()
  "Return (KEY . LABEL) which-key entries for the Vim leader.
A nil LABEL hides the key.  The `emacs' profile has no leader, so the
list is empty there."
  (when (eq my/keybinding-profile 'vim)
    (let ((prefix "SPC")
          specs)
      (push (cons prefix "Quick menu") specs)
      (dolist (group my/leader-groups)
        (push (cons (concat prefix " " (car group)) (cdr group)) specs))
      (dolist (entry (append my/leader-bindings my/leader-macos-bindings))
        (push (cons (concat prefix " " (car entry)) (nth 2 entry)) specs))
      (nreverse specs))))

(defun my/which-key-refresh ()
  "Re-register this configuration's which-key labels for the active profile."
  (require 'which-key nil t)
  (when (boundp 'which-key-replacement-alist)
    (setq which-key-replacement-alist
          (seq-difference which-key-replacement-alist my/which-key-entries))
    (setq my/which-key-entries nil)
    (dolist (spec (my/leader-which-key-specs))
      (let* ((key (car spec))
             (label (cdr spec))
             (regexp (concat "\\`" (regexp-quote (key-description (kbd key))) "\\'")))
        (cond
         (label
          (which-key-add-key-based-replacements key label)
          (push (cons (cons regexp nil) (cons nil label)) my/which-key-entries))
         (t
          ;; A non-cons replacement makes which-key ignore the binding.
          (let ((entry (cons (cons regexp nil) t)))
            (push entry which-key-replacement-alist)
            (push entry my/which-key-entries))))))))

(provide 'init-leader)

;;; init-leader.el ends here
