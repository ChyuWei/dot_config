;;; init.el --- Init file -*- lexical-binding: t; -*-

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.5)
(add-hook 'emacs-startup-hook
          (lambda ()
            "Recover GC"
            (setq gc-cons-threshold #x4000000
                  gc-cons-percentage 0.1)))

(push (expand-file-name "lisp" user-emacs-directory) load-path)

(require 'init-funcs)
(proxy-http-enable)

(require 'init-package)
(require 'init-core)
(require 'init-ui)

(require 'init-edit)

(provide 'init)








