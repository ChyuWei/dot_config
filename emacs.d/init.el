;;; init.el --- Init file -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(defvar lisp-dirs '("core" "editor" "langs" "tool"))
(dolist (dir lisp-dirs)
  (push (expand-file-name dir user-emacs-directory) load-path))

(require 'init-core)
(require 'init-ui)
(require 'init-editor)
(require 'init-langs)
(require 'init-tool)

(provide 'init)