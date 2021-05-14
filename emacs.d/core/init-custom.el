;;; init-custom.el --- custom define -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

;; core flags
(defvar myself/package-archives
  '(("gnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
    ("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
    ("org" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/org/")))

(defvar myself/use-server nil)
(defvar myself/use-doom-modeline nil)

;; editor flags
(defvar myself/use-evil nil)

(provide 'init-custom)
;;; init-custom.el ends here
