;;; init-langs.el --- langs config -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(use-package company
  :ensure t
  :diminish 
  :hook (after-init . global-company-mode)
  :bind (("M-/" . company-complete)
         :map company-active-map
         ("C-p" . company-select-previous)
         ("C-n" . company-select-next)
         ("<tab>" . company-complete-common-or-cycle)
         :map company-search-map
         ("C-p" . company-select-previous)
         ("C-n" . company-select-next))
  :init
  (setq company-tooltip-align-annotations t
        company-tooltip-limit 12
        company-idle-delay 0.1
        company-echo-delay 0.1
        company-minimum-prefix-length 1
        company-require-match nil
        company-dabbrev-ignore-case nil
        company-dabbrev-downcase nil
        company-global-modes '(not erc-mode message-mode help-mode
                                   gud-mode eshell-mode shell-mode)))

(use-package flycheck
  :ensure t
  :diminish
  :commands flycheck-redefine-standard-error-levels
  :hook (after-init . global-flycheck-mode)
  :init (setq flycheck-global-modes
              '(not text-mode outline-mode fundamental-mode lisp-interaction-mode
                    org-mode diff-mode shell-mode eshell-mode term-mode vterm-mode)
              flycheck-emacs-lisp-load-path 'inherit
              flycheck-check-syntax-automatically '(save mode-enabled)))

(require 'init-org)

(provide 'init-langs)