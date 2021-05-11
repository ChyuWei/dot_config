;;; init-custom.el --- custom define -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;; Code:

(defgroup myself nil
  "myself custom configuration."
  :group 'emacs)

(defvar myself/package-archives
  '(("gnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
    ("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
    ("org" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/org/")))

(defvar myself/use-server nil)

(provide 'init-custom)
;;; init-custom.el ends here
