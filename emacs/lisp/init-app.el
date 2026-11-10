;;; init-app.el --- Emacs applications -*- lexical-binding: t; -*-

;;; Commentary:

;; Applications that happen to be written in Emacs Lisp, kept apart from the
;; editing configuration.  An app may be missing, may fail to download, and must
;; never keep the editor from starting, so every declaration here is deferred
;; and installs on demand: `:vc' for the ones no ELPA archive carries (a
;; checkout in elpa/, ignored by git; update with `M-x package-vc-update'),
;; `:ensure t' for Magit, which is on MELPA.
;;
;;   dsh-emacs  client for a locally running DeepSeek Harness agent server.
;;   magit      Git status, staging, log and blame.

;;; Code:

;; Evil is loaded only when the app is used; this module does not depend on it.
(declare-function evil-emacs-state "evil")

(defun my/dsh-emacs-evil-state ()
  "Give a dsh-emacs buffer Evil's non-modal `emacs' state in the vim profile.
Checked at mode-hook time, so switching profiles at run time also works; the
native profile must not load Evil merely because a dsh buffer opened."
  (when (eq my/keybinding-profile 'vim)
    (require 'evil)
    (evil-emacs-state 1)))

;;; DeepSeek Harness client

;; `dsh web' serves the agent on 127.0.0.1:3080; the CLI is installed outside
;; Emacs with `bun add -g @deepseek-ai/dsh' (bun runs it fine, and its bin
;; directory ends up on the PATH this configuration imports), so the on-demand
;; installer is pointed at bun too instead of its npm default.
;;
;; `:rev :newest' follows the default branch: the project publishes no tags and
;; carries its version in the file header, so `:last-release' would have nothing
;; to find.  Nothing is loaded here -- the app's own autoloads are enough.
;;
;; `:hook' is what adapts it to Evil.  dsh-emacs ships no Evil support, and its
;; buffers (chat, session list, creation draft, plan and job output) are
;; read-only views or plain text fields with their own single-key commands, so
;; in normal state Evil would take `c', `d', `r', `q', `RET' … from the session
;; list, `M-p'/`M-n' from the chat and typing from the draft.  The `emacs'
;; state is Evil's non-modal one: every key keeps its Emacs binding, while ESC
;; still returns to normal, so Vim's keys and the SPC leader stay reachable.
(use-package dsh-emacs
  :vc (:url "https://github.com/vritser/dsh-emacs" :rev :newest)
  :defer t
  :init
  ;; Line numbers are on everywhere (init-defaults.el), but this app is a
  ;; reading surface: chat, session list, plan, job output and the draft
  ;; composer are prose, not code.  Add the hooks here, not with `:hook':
  ;; a lambda there makes use-package require the package at startup.
  ;; Evil is attached only when the vim profile is active; the native profile
  ;; must not load it, which is what a bare `evil-emacs-state' hook would do.
  (dolist (hook '(dsh-emacs-mode-hook dsh-emacs-session-mode-hook
                  dsh-emacs-draft-mode-hook dsh-emacs-plan-mode-hook
                  dsh-emacs-jobs-output-mode-hook))
    (add-hook hook (lambda () (display-line-numbers-mode -1)))
    (add-hook hook #'my/dsh-emacs-evil-state))
  :custom
  (dsh-emacs-default-preset "ptc")
  (dsh-emacs-server-auto-start t)
  (dsh-emacs-server-install-command '("bun" "add" "-g" "@deepseek-ai/dsh")))

;;; Magit

;; Magit is the Git UI: status, staging, log and blame in one buffer.  It is a
;; normal MELPA package, so `:ensure t' rather than `:vc', but it is deferred
;; like the app above: nothing loads until `C-x g' or a leader key asks for it.
(use-package magit
  :ensure t
  :defer t
  :bind ("C-x g" . magit-status)
  :custom
  ;; Status and log use the selected window; diffs and git output open beside
  ;; it, so the file being staged stays visible.
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1)
  :config
  ;; Magit is single-key commands everywhere, and Evil's normal state would
  ;; take them.  evil-collection ships the Vim bindings but init-evil.el only
  ;; enables it for a few modes, so set Magit up here -- only in the profile
  ;; where Evil is actually loaded.
  (when (eq my/keybinding-profile 'vim)
    (evil-collection-require 'magit)
    (evil-collection-magit-setup)))

(provide 'init-app)

;;; init-app.el ends here
