;;; init-keys-emacs.el --- Native Emacs keys (Emacs profile) -*- lexical-binding: t; -*-

;;; Commentary:

;; Additions for the non-modal profile only.  They are all supersets of a
;; stock binding or land on keys Emacs leaves free, so nothing native is
;; taken away:
;;
;;   M-g i      imenu -> consult-imenu
;;   M-g g      goto-line -> consult-goto-line
;;   M-s l/r    free -> consult-line / consult-ripgrep
;;   S-<arrow>  free -> windmove
;;
;; This profile has no leader; `C-c' stays available to major modes.

;;; Code:

(require 'windmove)

(defconst my/emacs-keybinding-overrides
  '(("M-g i" consult-imenu imenu)
    ("M-g g" consult-goto-line goto-line)
    ("M-s l" consult-line nil)
    ("M-s r" consult-ripgrep nil))
  "Native-profile overrides as (KEY ENABLED-COMMAND RESTORED-COMMAND).
Keep both sides together so disabling the profile restores every key.")

(defconst my/emacs-windmove-keys
  '("S-<left>" "S-<right>" "S-<up>" "S-<down>")
  "Windmove bindings installed in the `emacs' profile.")

(defun my/apply-emacs-keybinding-overrides (state)
  "Apply native-profile key overrides for STATE `on' or restore with `off'."
  (when (memq state '(on off))
    (dolist (binding my/emacs-keybinding-overrides)
      (let ((key (car binding))
            (command (if (eq state 'on) (nth 1 binding) (nth 2 binding))))
        (define-key (current-global-map) (kbd key) command))))
  (pcase state
    ('on (windmove-default-keybindings))
    ('off
     (dolist (key my/emacs-windmove-keys)
       (define-key (current-global-map) (kbd key) nil)))))

(provide 'init-keys-emacs)

;;; init-keys-emacs.el ends here
