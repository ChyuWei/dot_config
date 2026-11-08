;;; init-keys.el --- Install the active keybinding profile -*- lexical-binding: t; -*-

;;; Commentary:

;; The keybinding configuration is split in four parts:
;;
;;   init-profile.el     which profile is active and how to switch;
;;   init-leader.el      the Vim leader bindings and which-key labels;
;;   init-keys-vim.el    keys that only exist in the Vim profile;
;;   init-keys-emacs.el  keys that only exist in the Emacs profile.
;;
;; It also installs the macOS Cmd (super) keys, which are not profile-specific.
;; Nothing in Emacs 31 binds `s-', so Cmd-S / Cmd-C / Cmd-V would do nothing
;; otherwise.  The rest of this file only loads the key definitions;
;; init-profile.el registers profile activation on `my/window-ready-hook'.

;;; Code:

(require 'init-profile)
(require 'init-leader)
(require 'init-keys-vim)
(require 'init-keys-emacs)

;;; macOS Cmd keys ---------------------------------------------------------

;; Global keymap, not Evil's state maps: on macOS Cmd is a modifier that no one
;; else claims, and it has to work in insert state as well.
(dolist (entry '(("s-s" . save-buffer)
                 ("s-c" . kill-ring-save)
                 ("s-v" . clipboard-yank)
                 ("s-x" . kill-region)
                 ("s-a" . mark-whole-buffer)
                 ("s-z" . undo)
                 ("s-Z" . undo-redo)
                 ("s-f" . isearch-forward)))
  (keymap-global-set (car entry) (cdr entry)))

;; Applying the profile (which loads Evil in the vim profile) is an
;; activation step, not a declaration: `init-profile' registers it on
;; `my/window-ready-hook'.

(provide 'init-keys)

;;; init-keys.el ends here
