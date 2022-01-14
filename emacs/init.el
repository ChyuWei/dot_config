;;; init.el --- Init file -*- lexical-binding: t; -*-

(push (expand-file-name "lisp" user-emacs-directory) load-path)

(require 'init-core)
(require 'init-ui)
(require 'init-edit)
(require 'init-util)

(provide 'init)








(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(use-package)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
