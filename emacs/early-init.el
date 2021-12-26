;;; early-init.el --- Early init file -*- lexical-binding: t; -*-

;; defer gc
(setq gc-cons-threshold most-positive-fixnum)
(defun gc-config/backto-normal-gc ()
  "Set gc setting to normal."
  (setq gc-cons-threshold #x4000000))
(add-hook 'emacs-startup-hook #'gc-config/backto-normal-gc)

;; init package later
(setq package-enable-at-startup nil)

(provide 'early-init)
