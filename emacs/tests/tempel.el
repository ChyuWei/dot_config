;;; tempel.el --- Packaged templates and completion integration -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/tempel.el
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))
(cl-assert (not (featurep 'tempel)))
(cl-assert (not (featurep 'tempel-collection)))
(my/apply-keybinding-profile 'vim)
(with-temp-buffer
  (emacs-lisp-mode)
  (evil-local-mode 1)
  (evil-insert-state)
  (cl-assert (eq (key-binding (kbd "M-+")) #'tempel-complete))
  (cl-assert (eq (key-binding (kbd "M-*")) #'tempel-insert))
  (cl-assert (eq (key-binding (kbd "TAB")) #'tab-to-tab-stop))
  (cl-assert (eq (car completion-at-point-functions) #'tempel-expand))
  (cl-assert (not (featurep 'tempel)))
  (insert "pt")
  (completion-at-point)
  (cl-assert (equal (buffer-string) "(point)"))
  (cl-assert (featurep 'tempel-collection))
  (erase-buffer)
  (tempel-insert 'fn)
  (insert "probe")
  (tempel-next)
  (insert "arg")
  (tempel-done t)
  (cl-assert (string-prefix-p "(defun probe (arg)" (buffer-string)))
  (erase-buffer)
  (insert "no_such_template_probe")
  (cl-assert (null (tempel-expand)))
  (my/tempel-setup-completion)
  (cl-assert (= (cl-count #'tempel-expand completion-at-point-functions) 1))
  (princ "PASS: lazy loading, completion expansion, fields and fallback\n"))
(my/apply-keybinding-profile 'emacs)
(with-temp-buffer
  (text-mode)
  (cl-assert (memq #'tempel-expand completion-at-point-functions))
  (cl-assert (eq (key-binding (kbd "M-*")) #'tempel-insert)))

;; Check packaged Go mode dispatch without requiring a Go parser or server.
(with-temp-buffer
  (setq major-mode 'go-ts-mode)
  (my/tempel-setup-completion)
  (cl-assert (assq 'ifen (tempel-collection)))
  (tempel-insert 'ifen)
  (cl-assert (string-prefix-p "if err != nil {" (buffer-string)))
  (princ "PASS: packaged Go templates available to go-ts-mode\n"))
