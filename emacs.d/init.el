;;; init.el --- Init file -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(add-to-list 'load-path (expand-file-name "core" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "editor" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "langs" user-emacs-directory))

(require 'init-core)
(require 'init-ui)
(require 'init-editor)
(require 'init-langs)

(provide 'init)