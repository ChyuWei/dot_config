;;; build-config.el --- Compile configuration and activation cache -*- lexical-binding: t; -*-

;; Run from the repository root: emacs -Q --batch -l emacs/build-config.el
;; load-prefer-newer keeps edited source usable until the next rebuild.
(setq user-emacs-directory (file-name-directory load-file-name))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))
(require 'bytecomp)
(require 'doom-modeline)                 ; macros used in init-ui.el

;; Normally use-package removes :ensure from compiled output.  Keep runtime
;; installation checks so a missing package still installs as in source mode.
(let ((runtime-ensure
       (lambda (_original name _keyword ensure rest state)
         (cons `(funcall use-package-ensure-function ',name
                         ',(and (not (plist-member rest :vc)) ensure) ',state)
               (use-package-process-keywords name rest state)))))
  (advice-add 'use-package-handler/:ensure :around runtime-ensure)
  (unwind-protect
      (progn
        ;; early-init stays source-only: it sets load-prefer-newer before
        ;; Emacs chooses bytecode versus source for the rest of the config.
        (dolist (file (cons (expand-file-name "init.el" user-emacs-directory)
                            (directory-files (expand-file-name "lisp" user-emacs-directory)
                                             t "\\.el\\'")))
          (unless (byte-compile-file file)
            (error "Compilation failed: %s" file)))
        (package-quickstart-refresh)
        (princ "Built configuration bytecode and package activation cache\n"))
    (advice-remove 'use-package-handler/:ensure runtime-ensure)))
