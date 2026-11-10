;;; init-hooks.el --- Named startup hook checks -*- lexical-binding: t; -*-

;; Run from the repository root:
;; emacs -Q --batch -l emacs/tests/init-hooks.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))

;; The framework is loaded from init.el (not early-init: the only hook that
;; would need to be earlier, `my/before-init-hook', is deliberately unwired).
(unless (featurep 'init-hooks)
  (error "init-hooks.el was not loaded by init.el"))

(defconst my/test-hooks
  '(my/before-init-hook my/after-init-hook my/first-file-hook
    my/startup-hook my/window-ready-hook my/idle-hook)
  "All hook variables, including the unwired `my/before-init-hook'.")

(defconst my/test-wired
  '(my/after-init-hook my/first-file-hook my/startup-hook
    my/window-ready-hook my/idle-hook)
  "Hooks that actually run, in order.")

;; Every hook exists and holds a list; what is attached to it is checked
;; below.
(dolist (hook my/test-hooks)
  (unless (and (boundp hook) (listp (symbol-value hook)))
    (error "%S is not a defined hook variable" hook)))
(unless (equal my/init--hook-order my/test-wired)
  (error "Hook order changed: %S" my/init--hook-order))

;; Everything registered on our hooks must be a real function, and the
;; current consumers must be there.  Add to this list when another module
;; starts using the layer.
(dolist (hook my/test-hooks)
  (dolist (fn (symbol-value hook))
    (unless (functionp fn)
      (error "%S holds %S, which is not a function" hook fn))))
(dolist (pair '((my/after-init-hook . my/init-defaults-activate-display)
                (my/after-init-hook . my/init-defaults-activate-treesit)
                (my/after-init-hook . my/init-defaults-activate-files)
                (my/after-init-hook . my/init-defaults-activate-editing)
                (my/after-init-hook . my/init-defaults-activate-formatting)
                (my/after-init-hook . my/init-ui-activate-modeline)
                (my/window-ready-hook . my/init-profile-activate)
                (my/window-ready-hook . my/init-ui-activate-display)
                (my/window-ready-hook . my/init-env-activate)
                (my/window-ready-hook . my/eglot-shell-path-setup)
                (my/window-ready-hook . my/init-completion-activate)
                (my/window-ready-hook . my/init-evil-activate)
                (my/idle-hook . my/init-defaults-activate-session)
                (my/idle-hook . my/init-defaults-activate-cjk)
                (my/idle-hook . my/init-ui-activate-diff-hl)))
  (unless (memq (cdr pair) (symbol-value (car pair)))
    (error "%S is missing %S" (car pair) (cdr pair))))

;; Each Emacs trigger has our relay.  `before-init-hook' is deliberately
;; unwired (see init-hooks.el); the idle hook has no Emacs hook, its timer
;; is scheduled by the after-init relay.
(dolist (pair '((after-init-hook    . my/init--on-after-init)
                (find-file-hook     . my/init--on-first-file)
                (emacs-startup-hook . my/init--on-startup)
                (window-setup-hook  . my/init--on-window-ready)))
  (unless (memq (cdr pair) (symbol-value (car pair)))
    (error "%S is missing relay %S" (car pair) (cdr pair))))

;; In batch mode Emacs does not run the startup hooks for us.
(unless (null my/init--completed-hooks)
  (error "Startup hooks ran unexpectedly in batch mode: %S" my/init--completed-hooks))

;; `my/init-run-all' walks the documented order, once.
(let ((fired nil)
      (hooks my/test-wired)
      (saved nil))
  (unwind-protect
      (progn
        (dolist (hook hooks)
          (push (cons hook (symbol-value hook)) saved)
          (add-hook hook (let ((name hook))
                           (lambda () (push name fired)))))
        (my/init-run-all)
        (unless (equal (reverse fired) my/init--hook-order)
          (error "Hooks fired in the wrong order: %S" (reverse fired)))
        (my/init-run-all)
        (unless (equal (reverse fired) my/init--hook-order)
          (error "Hooks are not one-shot: %S" (reverse fired)))
        (unless (equal (reverse my/init--completed-hooks) my/init--hook-order)
          (error "State is inconsistent: %S" my/init--completed-hooks)))
    (dolist (pair saved)
      (set (car pair) (cdr pair)))
    (when (timerp my/init--idle-timer)
      (cancel-timer my/init--idle-timer)
      (setq my/init--idle-timer nil))))

;; `find-file-hook' is one-shot at our layer: the forwarder removes itself
;; after the first file, so later files do not re-run the hook.  Reset the
;; framework state first: `my/init-run-all' above already fired everything.
(setq my/init--completed-hooks nil)
(let ((count 0))
  (add-hook 'my/first-file-hook (lambda () (cl-incf count)))
  (add-hook 'find-file-hook #'my/init--on-first-file)
  (run-hooks 'find-file-hook)
  (run-hooks 'find-file-hook)
  (unless (= count 1)
    (error "my/first-file-hook ran %d times, expected 1" count))
  (add-hook 'find-file-hook #'my/init--on-first-file))

;; `my/reload-config' clears the one-shot state, reloads init.el and re-runs
;; the hooks; nothing is really loaded here.  A failing module must abort
;; before the hooks run.
(let ((loaded nil) (ran 0))
  (cl-letf (((symbol-function 'load)
             (lambda (file &rest _) (push file loaded)))
            ((symbol-function 'my/init-run-all)
             (lambda () (cl-incf ran))))
    (setq my/init--completed-hooks '(my/after-init-hook my/window-ready-hook))
    (my/reload-config)
    (unless (equal loaded (list (expand-file-name "init.el" user-emacs-directory)))
      (error "Reload should load init.el only, got %S" loaded))
    (unless (and (= ran 1) (null my/init--completed-hooks))
      (error "Reload should reset the one-shot state and re-run the hooks"))
    ;; Failure path: hooks must not run.
    (setq loaded nil my/init--completed-hooks nil)
    (cl-letf (((symbol-function 'load)
               (lambda (&rest _) (error "Simulated broken module"))))
      (my/reload-config))
    (unless (and (= ran 1) (null my/init--completed-hooks))
      (error "A failed reload must not run the startup hooks"))))

(princ "PASS: startup hook definitions, Emacs mapping, order, one-shot behaviour and reload\n")
