;;; init.el --- Init file -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:


(add-to-list 'load-path (expand-file-name "config" user-emacs-directory))

(require 'init-core)
(require 'init-ui)


(provide 'init)
;;; init.el ends here
