;;; early-init.el --- Startup defaults for Emacs 31 -*- lexical-binding: t; -*-

;;; Commentary:

;; Prepare startup performance and the initial frame.
;; Shell paths are imported after window setup by init-env.el.
;; Packages, the named startup hooks and the remaining UI settings belong
;; to init.el and lisp/.  This file deliberately loads nothing.

;;; Code:

;;; Startup and runtime performance ---------------------------------------

;; Use a larger GC budget while loading, then restore the interactive budget.
(setq gc-cons-threshold (* 128 1024 1024)
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1)))

(setq read-process-output-max (* 4 1024 1024)
      ;; init-packages.el activates packages after configuring the archives.
      package-enable-at-startup nil
      native-comp-async-report-warnings-errors 'silent
      native-comp-jit-compilation t
      ;; Prefer edited source over stale bytecode.
      load-prefer-newer t
      ;; Avoid rebuilding large CJK/emoji fontsets.
      inhibit-compacting-font-caches t)

;;; Faster `load' lookups -----------------------------------------------

;; `load' walks the whole `load-path' (78 entries here) for every file it has
;; to find, and a full miss costs ~1.2ms.  Remembering the directory a file was
;; found in lets the next lookup try it first; the rest of the path stays
;; behind it, so a stale entry can only cost time, never break a load.
;; Measured on this machine: see the note in README (startup is dominated by
;; other work, so the gain is small -- the point is that it is never a loss).
(defvar my/load-path--directories (make-hash-table :test #'equal)
  "Map of file name to the directory `load' last found it in.")

(defun my/load-path-filter (path file suffixes)
  "Return PATH with the directory that served FILE last time moved up front."
  (let* ((base (file-name-sans-extension file))
         (dir (or (gethash file my/load-path--directories)
                  (catch 'found
                    (dolist (suffix suffixes)
                      (when-let* ((hit (gethash (concat base suffix)
                                                my/load-path--directories)))
                        (throw 'found hit)))))))
    (if (and dir (member dir path))
        (cons dir (delete dir (copy-sequence path)))
      path)))

(defun my/load-path--remember (file)
  "Record the directory FILE was loaded from, for `my/load-path-filter'."
  (when (and (stringp file) (file-name-absolute-p file))
    (puthash (file-name-nondirectory file) (file-name-directory file)
             my/load-path--directories)))

;; Emacs 31: `load-path-filter-function' is consulted by `load' itself.
(setq load-path-filter-function #'my/load-path-filter)
(add-hook 'after-load-functions #'my/load-path--remember)

;;; Initial frame ---------------------------------------------------------

(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t
      inhibit-startup-screen t)
(add-to-list 'default-frame-alist '(font . "JetBrains Mono-16"))
(add-to-list 'default-frame-alist '(width . 120))
(add-to-list 'default-frame-alist '(height . 40))
;; `initial-frame-alist' is separate from `default-frame-alist'; use the
;; correct font from the very first frame so there is no small-to-large flash.
(add-to-list 'initial-frame-alist '(font . "JetBrains Mono-16"))

;; Keep the menu bar available while learning Emacs.
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; A built-in theme, loaded here so the very first frame is drawn with it.
;; Built-in themes live in etc/themes and are on `custom-theme-load-path'
;; already; package themes would need the package system, which starts later.
(load-theme 'modus-operandi t)

(provide 'early-init)

;;; early-init.el ends here
