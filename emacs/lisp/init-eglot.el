;;; init-eglot.el --- Local language servers via Eglot -*- lexical-binding: t; -*-

;;; Commentary:

;; Use Emacs' built-in server mappings and installed executables only.
;; Eglot supplies Corfu completion, Xref navigation, Eldoc and Flymake.
;; No server installers, download commands or format-on-save hooks.
;;
;; The "is the server installed?" check reads `eglot-server-programs', which
;; is public data.  It deliberately avoids Eglot's private helpers
;; (`eglot--guess-contact' and friends): those have changed shape between
;; releases.
;;
;; Three parts: settings, the definitions that decide whether to connect, and
;; one activation step that runs once the shell PATH is in place.

;;; Code:

;;; Part 1: settings -------------------------------------------------------

(require 'seq)

(declare-function eglot-managed-p "eglot")
(declare-function eglot-ensure "eglot")

(use-package eglot
  :ensure nil                    ; built into Emacs 31
  :defer t
  :custom
  (eglot-autoshutdown t)
  (eglot-sync-connect 0)
  (eglot-extend-to-xref t))

(defvar-local my/eglot-missing-server nil
  "Non-nil when automatic connection was skipped because no server was found.
Set per buffer; kept so that the connection can be retried once the shell
PATH is available (see part 3).")

;;; Part 2: definitions ----------------------------------------------------

(defun my/eglot-entry-modes (spec)
  "Return the major modes named by an `eglot-server-programs' SPEC.
SPEC is a mode symbol, a single (MODE :language-id \"…\") pair, or a list
mixing plain modes with such pairs."
  (cond ((null spec) nil)
        ((symbolp spec) (list spec))
        ((keywordp (cadr spec)) (list (car spec)))
        (t (mapcar (lambda (entry) (if (consp entry) (car entry) entry))
                   spec))))

(defun my/eglot-entry-program (contact)
  "Return the executable named by an `eglot-server-programs' CONTACT.
CONTACT is a string, a (PROGRAM . ARGS) list, or a function returning such a
list (`eglot-alternatives' produces one).  A function is called with
INTERACTIVE nil, exactly as Eglot does when it resolves a contact for an
automatic connection."
  (cond ((stringp contact) contact)
        ((and (consp contact) (stringp (car contact))) (car contact))
        ((functionp contact)
         (let ((resolved (condition-case nil (funcall contact nil) (error nil))))
           (and (consp resolved) (stringp (car resolved)) (car resolved))))))

(defun my/eglot-contact ()
  "Return (MAPPED . PROGRAM) for the current buffer.
MAPPED is non-nil when an `eglot-server-programs' entry covers the current
major mode; PROGRAM is that entry's executable name when the entry spells it
out as a string."
  (let ((entry (and major-mode
                    (seq-find
                     (lambda (candidate)
                       (seq-some (lambda (mode)
                                   (provided-mode-derived-p major-mode mode))
                                 (my/eglot-entry-modes (car candidate))))
                     eglot-server-programs))))
    (cons entry (and entry (my/eglot-entry-program (cdr entry))))))

(defun my/eglot-ensure ()
  "Connect a local file buffer only when its language server is installed."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name)))
    (require 'eglot)
    (unless (eglot-managed-p)
      (setq my/eglot-missing-server nil)
      (pcase-let ((`(,mapped . ,program) (my/eglot-contact)))
        (when mapped
          (cond
           ;; A named program that is not on PATH: report it once and skip.
           ((and program (not (executable-find program)))
            (setq my/eglot-missing-server t)
            (message "[Eglot] 未启动：找不到 %s，请手动安装语言服务器" program))
           ;; Either the program exists, or Eglot computes the contact
           ;; itself; let Eglot decide and report its own failures.
           (t
            (condition-case err
                (eglot-ensure)
              (error
               (message "[Eglot] 未启动：%s" (error-message-string err)))))))))))

(add-hook 'prog-mode-hook #'my/eglot-ensure)

;;; Part 3: activation -----------------------------------------------------

;; PATH is imported by init-env.el at depth 20.  Two things are only needed
;; once it is there, and both are Eglot-specific, so they live here:
;;
;;   - the shell's PATH does not include ~/go/bin, where gopls lives on this
;;     machine;
;;   - a file named on the command line is visited before the import runs, so
;;     its automatic connection already failed and must be retried.

(defun my/eglot--add-go-bin ()
  "Append ~/go/bin to `exec-path' and PATH when the directory exists."
  (let ((go-bin (expand-file-name "~/go/bin")))
    (when (and (file-directory-p go-bin) (not (member go-bin exec-path)))
      (setq exec-path (append exec-path (list go-bin)))
      (setenv "PATH" (concat (or (getenv "PATH") "") path-separator go-bin)))))

(defun my/eglot--retry-missing-server-buffers ()
  "Re-run the installed-server check for buffers that skipped it."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and (bound-and-true-p my/eglot-missing-server)
                 buffer-file-name (derived-mode-p 'prog-mode))
        (my/eglot-ensure)))))

(defun my/eglot-shell-path-setup ()
  "Run the PATH-dependent Eglot fixups.
Runs from `my/window-ready-hook' at depth 30, i.e. after init-env's import."
  (my/eglot--add-go-bin)
  (my/eglot--retry-missing-server-buffers))

(add-hook 'my/window-ready-hook #'my/eglot-shell-path-setup 30)

(provide 'init-eglot)

;;; init-eglot.el ends here
