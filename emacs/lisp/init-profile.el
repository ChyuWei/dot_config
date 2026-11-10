;;; init-profile.el --- Keybinding profile: Vim or Emacs -*- lexical-binding: t; -*-

;;; Commentary:

;; Two keybinding profiles for the same configuration:
;;
;;   vim    Evil modal editing with SPC as the leader (see init-leader.el).
;;          Vim's own keys stay untouched.
;;   emacs  Native Emacs editing: Evil is not loaded and no leader is
;;          installed, so `C-c' + letter stays free for the user and the
;;          major modes keep their `C-c' keymaps.  The only additions are
;;          native-style ones in init-keys-emacs.el.
;;
;; `my/switch-keybindings' applies a profile immediately and saves the
;; choice, so the next startup uses it.  Under the `emacs' profile Evil is
;; never loaded, which also makes startup cheaper.

;;; Code:

;;; Part 1: settings -------------------------------------------------------

(defgroup my nil
  "Personal configuration."
  :group 'convenience)

(defcustom my/keybinding-profile 'vim
  "Keybinding profile used at startup.
`vim' uses Evil modal editing with SPC as the leader.
`emacs' uses native Emacs keys only: no Evil, no leader."
  :type '(choice (const :tag "Vim (Evil, SPC leader)" vim)
                 (const :tag "Emacs (native keys, no leader)" emacs))
  :group 'my)

(defconst my/keybinding-profiles '(vim emacs)
  "Supported values of `my/keybinding-profile'.")

;; Try a profile without changing the saved choice:
;;   MY_KEYBINDINGS_PROFILE=emacs emacs
;; This runs after init-packages, so it wins over `etc/custom.el'.
(let ((override (getenv "MY_KEYBINDINGS_PROFILE")))
  (when (and override (memq (intern override) my/keybinding-profiles))
    (setq my/keybinding-profile (intern override))))

(declare-function my/leader-install "init-leader")
(declare-function my/leader-uninstall "init-leader")
(declare-function my/which-key-refresh "init-leader")
(declare-function my/apply-vim-keybinding-overrides "init-keys-vim")
(declare-function my/apply-emacs-keybinding-overrides "init-keys-emacs")
(declare-function my/evil-companion-modes "init-evil")

;;; Part 2: definitions ----------------------------------------------------

(defvar my/evil-companion-modes-timer nil
  "Idle timer that enables the Evil companion global modes.")

(defun my/schedule-evil-companion-modes ()
  "Enable the Evil companion global modes once startup settles."
  (when (timerp my/evil-companion-modes-timer) (cancel-timer my/evil-companion-modes-timer))
  (setq my/evil-companion-modes-timer
        (run-with-idle-timer 1 nil #'my/evil-companion-modes 1)))

(defun my/cancel-evil-companion-modes-timer ()
  "Cancel the pending Evil companion mode timer."
  (when (timerp my/evil-companion-modes-timer)
    (cancel-timer my/evil-companion-modes-timer)
    (setq my/evil-companion-modes-timer nil)))

(defun my/apply-keybinding-profile (profile)
  "Apply keybinding PROFILE (`vim' or `emacs') to the running session.
Idempotent: applying the same profile twice leaves the keymaps unchanged."
  (unless (memq profile my/keybinding-profiles)
    (user-error "Unknown keybinding profile: %S" profile))
  (setq my/keybinding-profile profile)
  (my/leader-uninstall)
  (pcase profile
    ('vim
     (my/apply-emacs-keybinding-overrides 'off)
     (require 'evil)
     (evil-mode 1)
     (my/apply-vim-keybinding-overrides 'on)
     (if (daemonp)
         (my/evil-companion-modes 1)
       (my/schedule-evil-companion-modes)))
    ('emacs
     (my/cancel-evil-companion-modes-timer)
     (my/apply-vim-keybinding-overrides 'off)
     (when (featurep 'evil)
       (my/evil-companion-modes -1)
       (evil-mode -1))
     (my/apply-emacs-keybinding-overrides 'on)))
  (my/leader-install)
  (my/which-key-refresh)
  (force-mode-line-update t)
  (message "Keybindings: %s %s" profile
           (if (eq profile 'vim) "(leader: SPC)" "(native keys, no leader)")))

;;;###autoload
(defun my/switch-keybindings (profile)
  "Switch to keybinding PROFILE and remember it for the next session."
  (interactive
   (list (intern (completing-read
                  "Keybinding profile: " (mapcar #'symbol-name my/keybinding-profiles)
                  nil t nil nil (symbol-name my/keybinding-profile)))))
  (my/apply-keybinding-profile profile)
  (customize-save-variable 'my/keybinding-profile profile)
  (message "Keybindings: %s %s, saved" profile
           (if (eq profile 'vim) "(leader: SPC)" "(native keys, no leader)")))

;;;###autoload
(defun my/toggle-keybindings ()
  "Switch between the `vim' and `emacs' keybinding profiles."
  (interactive)
  (my/switch-keybindings (if (eq my/keybinding-profile 'vim) 'emacs 'vim)))

;;; Part 3: activation -----------------------------------------------------

(defun my/init-profile-activate ()
  "Apply the saved keybinding profile.
Runs from `my/window-ready-hook' at depth 5, i.e. before the first redraw and
long before Emacs processes any key: whatever mode maps the profile installs
must exist by then, or the first keystroke would be read with the wrong maps.
Depth 5 also keeps it ahead of init-ui's display setup (10) and init-env's
`redisplay' (20), so the mode line is complete at the first paint."
  (my/apply-keybinding-profile my/keybinding-profile))

(add-hook 'my/window-ready-hook #'my/init-profile-activate 5)

(provide 'init-profile)

;;; init-profile.el ends here
