;;; init-hooks.el --- Named startup hooks -*- lexical-binding: t; -*-

;;; Commentary:

;; A thin layer over Emacs' own startup hooks.  Each variable below is a
;; normal hook: use `add-hook' on it like any other.  Only the definitions
;; and their one-shot relays live here.
;;
;; | Our hook             | Emacs trigger         | Fires                 | When |
;; |----------------------+-----------------------+-----------------------+------|
;; | my/before-init-hook  | `before-init-hook'    | (not wired)           | after early-init, BEFORE init.el |
;; | my/after-init-hook   | `after-init-hook'     | always                | after init.el, before command-line files |
;; | my/first-file-hook   | `find-file-hook'      | if a file is visited  | first file buffer (position moves) |
;; | my/startup-hook      | `emacs-startup-hook'  | always                | after command-line arguments handled |
;; | my/window-ready-hook | `window-setup-hook'   | always                | after frame parameters/fonts applied |
;; | my/idle-hook         | `run-with-idle-timer' | if Emacs goes idle    | `my/init-idle-delay' seconds of idle |
;;
;; Every wired hook runs at most once: `my/init-run-hook-once' records it
;; in `my/init--completed-hooks' before dispatching its functions.
;; In `--batch' Emacs triggers none of them, so call `my/init-run-all'.
;; `my/reload-config' (M-x) does the same for a live session: it clears that
;; state, re-reads init.el and re-runs the hooks.
;;
;; Beyond the table:
;; - `my/before-init-hook' is reserved and unused.  `before-init-hook' runs
;;   before init.el, and this file is loaded from init.el, so wiring it means
;;   moving both the relay and this file's load back into early-init.el (see
;;   the commented block at the bottom).
;; - `my/first-file-hook' fires at the first file visit: between
;;   `after-init-hook' and `emacs-startup-hook' when a command-line file is
;;   given, after everything else when a file is opened later (or by
;;   emacsclient), and never in a session that visits no file.
;;   `my/init--hook-order' places it at its earliest position so
;;   `my/init-run-all' stays deterministic.
;; - Emacs runs `find-file-hook' on every file and on `revert-buffer'; our
;;   relay removes itself after the first one.
;;
;; Measured native event order in the three start modes (Emacs 31.1, macOS NS;
;; GUI and TTY with a command-line file, daemon with a file opened by
;; emacsclient).  Our hooks fire from the matching native event:
;;
;;   GUI    : before-init -> (initial frame) -> init.el -> after-init
;;            -> find-file -> startup -> term-setup -> window-setup -> idle
;;   TTY    : before-init -> init.el -> after-init -> (tty-setup)
;;            -> find-file -> startup -> term-setup -> window-setup -> idle
;;   daemon : before-init -> init.el -> after-init -> startup -> term-setup
;;            -> window-setup -> (client) find-file -> idle

;;; Code:

(defgroup my/init-hooks nil
  "Named startup hooks for this configuration."
  :group 'initialization)

;;; The hooks --------------------------------------------------------------

(defvar my/before-init-hook nil
  "Reserved: would run just before Emacs loads init.el.
Currently NOT wired (see the commentary).  Using it requires moving this
file's load, and a relay, back into early-init.el.")

(defvar my/after-init-hook nil
  "Hook run just after init.el has been loaded.
Forwarded from `after-init-hook', before command-line files are opened.")

(defvar my/first-file-hook nil
  "Hook run when the session's first file buffer is visited, at most once.
Emacs runs `find-file-hook' for every file and for `revert-buffer'; this
layer's relay removes itself after the first one.  A session that visits no
file (bare `emacs', only *scratch*) leaves it unrun.  See the commentary for
how its position moves between start modes.")

(defvar my/startup-hook nil
  "Hook run after Emacs has handled the command line.
Forwarded from `emacs-startup-hook'.")

(defvar my/window-ready-hook nil
  "Hook run after frame parameters and fonts have been applied.
Forwarded from `window-setup-hook'.")

(defvar my/idle-hook nil
  "Hook run once, when Emacs has been idle for `my/init-idle-delay'.
Forwarded from an idle timer scheduled by `my/after-init-hook'.")

;;; State and forwarders ---------------------------------------------------

;; Static list, not state: the order `my/init-run-all' walks.  The "--" marks
;; it as internal.
(defconst my/init--hook-order
  '(;; my/before-init-hook           ; not wired, see the commentary
    my/after-init-hook
    my/first-file-hook
    my/startup-hook
    my/window-ready-hook
    my/idle-hook)
  "Internal: order in which `my/init-run-all' fills in missing hooks.
`my/first-file-hook' sits at its EARLIEST possible position; in a session
without command-line files it fires much later, or not at all (see the
commentary).  `my/init-run-all' still runs it, so batch mode is complete.")

;; Oneshot bookkeeping.  These two belong together and are the only state
;; the framework keeps; the "--" in the name marks it as internal.
(defvar my/init--completed-hooks nil
  "Internal: startup hooks that have already run, most recent first.
Written and read only by `my/init-run-hook-once'.")

(defun my/init-run-hook-once (hook)
  "Run HOOK with `my/init--completed-hooks' as the guard, so it runs only once.
Every Emacs -> our-hook relay calls this, and so does `my/init-run-all';
a second call (repeated Emacs hook, timer, or an extra `my/init-run-all')
is a no-op."
  (unless (memq hook my/init--completed-hooks)
    ;; Record before running, so a function that triggers another relay
    ;; cannot re-enter the same hook.
    (push hook my/init--completed-hooks)
    (run-hooks hook)))

(defun my/init-run-all ()
  "Run all not-yet-run startup hooks, in `my/init--hook-order'.
Meant for batch mode and tests, where Emacs does not run the startup
hooks by itself.  Interactive use is harmless: hooks already run are
skipped."
  (interactive)
  (dolist (hook my/init--hook-order)
    (my/init-run-hook-once hook)))

;;; Config drift ----------------------------------------------------------

(require 'filenotify)

(defconst my/config-directory
  (file-name-as-directory
   (file-truename (file-name-directory (or load-file-name (buffer-file-name)))))
  "Root directory of this configuration.")

(defvar my/config--stale-cache nil
  "Files changed since the running configuration was loaded, or nil.")

(defvar my/config--watches nil
  "File notification watches for this configuration.")

(defun my/config--source-file-p (file)
  "Return non-nil when FILE is one of the configuration source files."
  (and (stringp file)
       (let ((true (file-truename (expand-file-name file))))
         (and (string-suffix-p ".el" true)
              (not (string-prefix-p ".#" (file-name-nondirectory true)))
              (or (member (file-name-nondirectory true)
                          '("init.el" "early-init.el" "init-hooks.el"))
                  (string= (file-name-directory true)
                           (file-name-as-directory
                            (file-truename
                             (expand-file-name "lisp" my/config-directory)))))))))

(defun my/config--file-changed (event)
  "Record a watched config file change from EVENT."
  (let ((file (nth 2 event)))
    (when (my/config--source-file-p file)
      (let ((true (file-truename (expand-file-name file))))
        (unless (member true my/config--stale-cache)
          (push true my/config--stale-cache))
        (force-mode-line-update t)))))

(defun my/config--watch-file (file)
  "Add a file notification watch for FILE, if supported."
  (ignore-errors
    (file-notify-add-watch file '(change attribute-change)
                           #'my/config--file-changed)))

(defun my/config-watch-files ()
  "Watch lisp/ and the main configuration files for changes."
  (dolist (watch my/config--watches)
    (ignore-errors (file-notify-rm-watch watch)))
  (setq my/config--watches nil)
  (let ((lisp-dir (expand-file-name "lisp" my/config-directory))
        (root-files '("init.el" "early-init.el" "init-hooks.el")))
    ;; Watch each source file: kqueue does not recurse.
    (dolist (file root-files)
      (let ((full (expand-file-name file my/config-directory)))
        (when (file-exists-p full)
          (push (my/config--watch-file full) my/config--watches))))
    (dolist (file (directory-files lisp-dir t "\\.el\\'"))
      (when (file-regular-p file)
        (push (my/config--watch-file file) my/config--watches)))
    ;; The directory watch notices new and removed files.
    (when (file-directory-p lisp-dir)
      (push (my/config--watch-file lisp-dir) my/config--watches))))

(defun my/config-stale-p ()
  "Return non-nil when a watched configuration file has changed."
  (and my/config--stale-cache t))

(defun my/config-status ()
  "Report whether the running configuration matches the files on disk."
  (interactive)
  (if my/config--stale-cache
      (message "Config is stale (not loaded): %s"
               (mapconcat (lambda (file)
                            (file-relative-name file my/config-directory))
                          my/config--stale-cache ", "))
    (message "Config matches the code on disk")))

;; Watch installation is deferred to idle; startup stays cheap.
(add-hook 'my/idle-hook #'my/config-watch-files)

;;; Reloading -------------------------------------------------------------

(defun my/reload-config ()
  "Re-read init.el and re-run the startup hooks.
Only init.el is loaded; modules that are already provided are not
re-evaluated.  `my/config-status' reports files changed since they were
loaded, so a stale module is visible instead of silently ignored.
early-init.el sets the GC budget and the initial frame for the whole
session, so running it a second time would reset the grown-up GC thresholds.

The one-shot state is cleared first.  Everything the modules *do* (keybinding
profile, completion stack, PATH import, format-on-save) is attached to the
startup hooks, so a reload that leaves `my/init--completed-hooks' alone would
redefine functions but apply nothing.

A module that fails to load aborts the reload before any hook runs: editing a
file halfway then reloading reports the error instead of leaving the session
half configured."
  (interactive)
  (setq my/init--completed-hooks nil)
  (let ((start (float-time)))
    (condition-case err
        (progn
          (load (expand-file-name "init.el" user-emacs-directory) nil t)
          (my/init-run-all)
          ;; init.el itself is now current; other changed modules are not.
          (setq my/config--stale-cache
                (delete (file-truename
                         (expand-file-name "init.el" user-emacs-directory))
                        my/config--stale-cache))
          (let ((stale my/config--stale-cache))
            (message "Config reloaded (%d ms)%s"
                     (round (* 1000 (- (float-time) start)))
                     (if stale
                         (format "; not reloaded: %s"
                                 (mapconcat
                                  (lambda (file)
                                    (file-relative-name
                                     file my/config-directory))
                                  stale ", "))
                       ""))))
      (error
       (message "Reload failed; startup hooks not rerun: %s" (error-message-string err))))))

(defcustom my/init-idle-delay 1
  "Seconds of idle time before `my/idle-hook' runs."
  :type 'number
  :group 'my/init-hooks)

;; Idle timer: internal, because `cancel-timer' needs the object.
(defvar my/init--idle-timer nil
  "Internal: timer that fires `my/idle-hook' after an idle period.")

(defun my/init--schedule-idle-hook ()
  "Arrange for `my/idle-hook' to run after Emacs becomes idle."
  (when (timerp my/init--idle-timer)
    (cancel-timer my/init--idle-timer))
  (setq my/init--idle-timer
        (run-with-idle-timer
         my/init-idle-delay nil #'my/init-run-hook-once 'my/idle-hook)))

;; Not wired: `before-init-hook' runs before init.el loads this file.
;; (defun my/init--on-before-init () (my/init-run-hook-once 'my/before-init-hook))
(defun my/init--on-after-init ()
  "Run after-init work, then schedule the idle work."
  (my/init-run-hook-once 'my/after-init-hook)
  (my/init--schedule-idle-hook))
(defun my/init--on-first-file ()
  "Stop listening for file visits and run the first-file hook once."
  ;; `find-file-hook' runs for every file; our hook is one-shot.
  (remove-hook 'find-file-hook #'my/init--on-first-file)
  (my/init-run-hook-once 'my/first-file-hook))
(defun my/init--on-startup ()
  "Forward Emacs startup to the one-shot startup hook."
  (my/init-run-hook-once 'my/startup-hook))

(defun my/init--on-window-ready ()
  "Forward window setup to the one-shot window-ready hook."
  (my/init-run-hook-once 'my/window-ready-hook))

;;; Wiring -----------------------------------------------------------------

;; This file is loaded from init.el, which is early enough for every relay
;; below: they all fire after init.el.  `before-init-hook' is the exception;
;; to wire it, uncomment its relay above and the add-hook below, and load
;; this file from early-init.el as well.
;; (add-hook 'before-init-hook #'my/init--on-before-init)
(add-hook 'after-init-hook      #'my/init--on-after-init)
(add-hook 'find-file-hook       #'my/init--on-first-file)
(add-hook 'emacs-startup-hook   #'my/init--on-startup)
(add-hook 'window-setup-hook    #'my/init--on-window-ready)

(provide 'init-hooks)

;;; init-hooks.el ends here
