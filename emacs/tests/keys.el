;;; keys.el --- Leader key regression checks -*- lexical-binding: t; -*-

;; Run from the repository root:
;; emacs -Q --batch -l emacs/tests/keys.el
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))

(dolist (entry my/leader-bindings)
  (let* ((key (car entry))
         (command (cadr entry))
         (label (nth 2 entry))
         (display (which-key--maybe-replace
                   (cons (concat "SPC " key) (symbol-name command)))))
    (unless (and (eq (lookup-key my/leader-map (kbd key)) command)
                 (commandp command)
                 (if label (equal (cdr display) label) (null display)))
      (error "Binding or label mismatch: %S" entry))))

(dolist (entry my/leader-groups)
  (unless (and (keymapp (lookup-key my/leader-map (kbd (car entry))))
               (equal (cdr (which-key--maybe-replace
                            (cons (concat "SPC " (car entry)) "prefix")))
                      (cdr entry)))
    (error "Group mismatch: %S" entry)))

(evil-mode 1)
(dolist (mode '(fundamental-mode dired-mode help-mode))
  (with-temp-buffer
    (funcall mode)
    (evil-local-mode 1)
    (dolist (state '(normal visual motion operator))
      (evil-change-state state)
      (dolist (entry my/leader-bindings)
        (unless (eq (key-binding (kbd (concat "SPC " (car entry))) nil t)
                    (cadr entry))
          (error "Shadowed binding in %S/%S: %S" mode state entry))))))

(with-temp-buffer
  (evil-local-mode 1)
  (dolist (state '(normal insert visual))
    (evil-change-state state)
    (unless (eq (key-binding (kbd "C-s")) #'save-buffer)
      (error "Save binding mismatch in %S" state)))
  (evil-insert-state)
  (unless (eq (key-binding " ") #'self-insert-command)
    (error "Insert-state space is shadowed")))

;; Consult constructs this map when SPC SPC falls back to fd outside a
;; project.  Checking only commandp does not catch invalid preview key syntax.
(require 'consult)
(with-temp-buffer
  (use-local-map minibuffer-local-map)
  (consult--setup-keymap nil t nil consult-preview-key)
  (unless (eq (lookup-key (current-local-map) (kbd "M-.")) #'ignore)
    (error "Consult preview key is missing")))

(princ "PASS: leader bindings, menu labels, Evil states and Consult search setup\n")
