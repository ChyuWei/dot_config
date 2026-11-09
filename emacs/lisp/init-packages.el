;;; init-packages.el --- Package management -*- lexical-binding: t; -*-

;;; Commentary:

;; package.el is enough here: it is built in, handles dependencies, and
;; keeps the configuration free of a bootstrap script.  Third-party packages
;; are declared with use-package in the other modules.

;;; Code:

(require 'package)

;;; Package archives ------------------------------------------------------

;; Domestic package mirrors.  TUNA mirrors GNU ELPA, NonGNU ELPA and MELPA;
;; USTC is a good alternative.  Change `my/elpa-mirror' to "ustc" to switch.
(defvar my/elpa-mirror "tuna"
  "Package archive mirror used for `package-archives'.")

(let* ((mirrors '(("tuna" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/")
                  ("ustc" . "https://mirrors.ustc.edu.cn/elpa/")))
       (base (or (cdr (assoc my/elpa-mirror mirrors))
                 (cdr (assoc "tuna" mirrors)))))
  (setq package-archives
        `(("gnu"    . ,(concat base "gnu/"))
          ("nongnu" . ,(concat base "nongnu/"))
          ("melpa"  . ,(concat base "melpa/")))))

;; Prefer GNU ELPA, then NonGNU, then MELPA when a package is duplicated.
(setq package-archive-priorities
      '(("gnu" . 30) ("nongnu" . 20) ("melpa" . 10)))

;; package.el refreshes this cache after its own install/delete operations.
;; A missing cache falls back to normal activation; build-config.el creates it.
(setq package-quickstart t
      package-quickstart-file
      (expand-file-name "var/package-quickstart.el" user-emacs-directory))
(make-directory (file-name-directory package-quickstart-file) t)
(if (or (file-readable-p package-quickstart-file)
        (file-readable-p (concat package-quickstart-file "c")))
    ;; Native quickstart activation does not need package/archive metadata.
    (package-activate-all)
  (package-initialize))

;; On the uncached path, retain first-run archive setup.  The cached path
;; reads metadata only when package management actually needs it.
(when (and package--initialized (not package-archive-contents))
  (condition-case err
      (package-refresh-contents)
    (error
     (message "Package archive refresh failed: %s"
              (error-message-string err)))))

;;; Package installation --------------------------------------------------

(require 'use-package)
(require 'use-package-ensure)

;; A failing download should not abort the whole init file.  Missing
;; packages produce a message and the rest of the configuration still loads.
(setq use-package-ensure-function
      (lambda (name args state &optional no-refresh)
        (condition-case err
            (progn
              (when (and (not package--initialized)
                         (not (package-installed-p name)))
                (package-initialize t))
              (use-package-ensure-elpa name args state no-refresh))
          (error
           (message "Could not install %s: %s"
                    name (error-message-string err))))))

;;; Generated files -------------------------------------------------------

;; Keep backups, history and other generated state under etc/ and var/.
(use-package no-littering
  :ensure t
  :demand t
  :config
  ;; Backups (file~) and auto-saves (#file#) go under var/ as well;
  ;; files in temporary directories keep their copies beside them.
  (no-littering-theme-backups))

(setq custom-file
      (if (fboundp 'no-littering-expand-etc-file-name)
          (no-littering-expand-etc-file-name "custom.el")
        (expand-file-name "custom.el" user-emacs-directory)))
(load custom-file :noerror)

;;; Autoremove safety ------------------------------------------------------

;; `package-autoremove' trusts `package-selected-packages', which Custom keeps
;; in etc/custom.el and only updates for packages installed or deleted
;; interactively.  Everything installed here through `use-package ... :ensure'
;; looks unselected, so autoremove would offer to delete most of the tree.
;; Instead of maintaining a second list by hand, derive it from what is
;; actually installed, at the moment autoremove runs: no startup cost, nothing
;; to keep in sync.  The price is that the command can no longer find
;; anything to remove -- every installed package counts as selected, leftovers
;; included -- so cleaning up an unused package means deleting its directory
;; from elpa/ by hand.  That is the safe direction: the failure mode of the
;; opposite is a deleted package the configuration still needs.
(defun my/package-select-installed ()
  "Mark every installed package as selected, so nothing can be autoremoved.
Runs before `package-autoremove', which then has nothing to offer: the
configuration never risks losing a package it still uses.  Remove an unused
package by deleting its directory from `package-user-dir' instead."
  (require 'package)
  (package-load-all-descriptors)
  (setq package-selected-packages (mapcar #'car package-alist)))

(advice-add 'package-autoremove :before #'my/package-select-installed)

(provide 'init-packages)

;;; init-packages.el ends here
