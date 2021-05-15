;;; init.el --- Init file -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(defvar lisp-dirs '("core" "editor" "langs" "tool"))
(dolist (dir lisp-dirs)
  (push (expand-file-name dir user-emacs-directory) load-path))

(require 'init-core)
(require 'init-editor)
(require 'init-langs)
(require 'init-tool)

(provide 'init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(rime smartparens use-package toc-org magit ivy highlight-numbers highlight-escape-sequences flycheck exec-path-from-shell evil-surround evil-commentary evil-collection doom-themes doom-modeline diminish default-text-scale company)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
