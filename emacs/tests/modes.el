;;; modes.el --- Org, outline and completion checks -*- lexical-binding: t; -*-

;; emacs -Q --batch -l emacs/tests/modes.el
;; EMACS_MODE_SNAPSHOT=/tmp/modes.el also writes a behavior snapshot.
;; Markdown (init-markdown.el) has its own test, tests/markdown.el.
(require 'cl-lib)
(setq user-emacs-directory
      (file-name-directory
       (directory-file-name (file-name-directory load-file-name))))
(load (expand-file-name "early-init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))
;; The configuration applies the profile from `my/window-ready-hook'; call it
;; directly here so the test does not also run the env import, which may spawn
;; a shell.
(my/apply-keybinding-profile my/keybinding-profile)

(let (snapshot)
  (with-temp-buffer
    (insert "* Parent\nBody\n** Child\nText\n")
    (org-mode)
    (font-lock-ensure)
    ;; Check actual fontification and face heights, not only enabled modes.
    (cl-loop for height in '(2.0 1.7 1.4 1.1 1.0 1.0)
             for level from 1
             do (cl-assert (= (face-attribute
                               (intern (format "org-level-%d" level)) :height)
                              height)))
    (goto-char (point-min))
    (search-forward "Parent")
    (cl-assert (memq 'org-level-1
                     (ensure-list (get-text-property (1- (point)) 'face))))
    (cl-assert (not (bound-and-true-p indent-bars-mode)))
    (cl-assert (not (bound-and-true-p rainbow-delimiters-mode)))
    (cl-assert visual-line-mode)
    (cl-assert olivetti-mode)
    (cl-assert valign-mode)
    (cl-assert (not word-wrap))
    (cl-assert (not display-line-numbers-mode))
    (cl-assert (memq 'cape-dabbrev completion-at-point-functions))
    ;; The header line is installed by `my/header-line-setup' for files;
    ;; a temp buffer has none, so exercise the installer directly.
    (setq buffer-file-name (expand-file-name "probe.org" temporary-file-directory))
    (my/header-line-setup)
    (cl-assert (member '(:eval (my/header-line)) header-line-format))
    (cl-assert (= (cl-count '(:eval (my/reading-progress)) mode-line-misc-info :test #'equal) 1))
    (cl-assert (= org-imenu-depth 8))
    (cl-assert (= org-appear-delay 0.08))
    (cl-assert (equal (mapcar #'car org-capture-templates) '("t" "n" "d")))
    (cl-assert org-modern-mode)
    (cl-assert org-appear-mode)
    (cl-assert (equal org-remark-notes-file-name
                      (expand-file-name "remark.org" org-directory)))
    (push (list 'org-mode
                (mapcar (lambda (variable)
                          (cons variable (and (boundp variable) (symbol-value variable))))
                        '(visual-line-mode olivetti-mode valign-mode word-wrap
                          display-line-numbers-mode
                          org-modern-mode org-appear-mode completion-at-point-functions)))
          snapshot))
  (with-temp-buffer
    (insert "(defun probe ()\n  (when t\n    (message \"ok\")))\n")
    (emacs-lisp-mode)
    (cl-assert electric-pair-mode)
    (cl-assert hl-line-mode)
    (cl-assert (memq 'cape-dabbrev completion-at-point-functions))
    (cl-assert indent-bars-mode)
    (cl-assert rainbow-delimiters-mode)
    (let ((source (buffer-substring-no-properties (point-min) (point-max))))
      (set-buffer-modified-p nil)
      (font-lock-ensure)
      (goto-char (point-min))
      (cl-assert (memq 'rainbow-delimiters-depth-1-face
                       (ensure-list (get-text-property (point) 'face))))
      (search-forward "(when")
      (cl-assert (memq 'rainbow-delimiters-depth-2-face
                       (ensure-list (get-text-property (- (point) 5) 'face))))
      (cl-assert (text-property-not-all (point-min) (point-max)
                                        'indent-bars-display nil))
      (cl-assert (equal source (buffer-substring-no-properties (point-min) (point-max))))
      (cl-assert (not (buffer-modified-p)))
      (indent-bars-mode -1)
      (cl-assert (not (text-property-not-all (point-min) (point-max)
                                              'indent-bars-display nil)))))
  ;; Code folding: `prog-mode-hook' turns on `hs-minor-mode', kirigami routes
  ;; the z keys to it, and the closing brace keeps its own line.
  (with-temp-buffer
    (insert "int f(void) {\n  if (1) {\n    a();\n  } else {\n    b();\n  }\n}\n")
    (c-mode)
    (cl-assert (bound-and-true-p hs-minor-mode))
    (cl-assert hs-adjust-block-end-function)
    (goto-char (point-min))
    (search-forward "if (1)")
    (kirigami-toggle-fold)          ; must not error: the hs backend is live
    (let ((ov (seq-find (lambda (o) (overlay-get o 'hs))
                        (overlays-in (point-min) (point-max)))))
      (cl-assert ov)
      ;; The hidden region stops on `a();', so `}' and `} else {' stay apart.
      (cl-assert (= 3 (line-number-at-pos (overlay-end ov))))
      (cl-assert (equal "a();"
                        (save-excursion
                          (goto-char (overlay-end ov))
                          (string-trim (buffer-substring-no-properties
                                        (line-beginning-position)
                                        (line-end-position))))))
      (cl-assert (equal "} else {"
                        (save-excursion
                          (goto-char (point-min))
                          (forward-line 3)
                          (string-trim (buffer-substring-no-properties
                                        (line-beginning-position)
                                        (line-end-position)))))))
    (kirigami-toggle-fold)
    (cl-assert (null (seq-find (lambda (o) (overlay-get o 'hs))
                               (overlays-in (point-min) (point-max))))))

  ;; separedit: comment block into a markdown buffer and back, prefix and all.
  ;; It locates the block through the font-lock face, hence `font-lock-ensure'
  ;; here (a displayed buffer is always fontified).
  (with-temp-buffer
    (insert "// alpha\n// beta\nint x;\n")
    (c-mode)
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "alpha")
    (let ((source (current-buffer)))
      (separedit)
      (cl-assert (derived-mode-p 'markdown-mode))
      (cl-assert (equal "alpha\nbeta" (string-trim (buffer-string))))
      (goto-char (point-max))
      (insert "\n- gamma")            ; a markdown list, no comment prefix typed
      (separedit-commit)
      ;; In batch the commit lands in *scratch* (there is no window to show
      ;; the source buffer again), so check the source buffer directly.
      (with-current-buffer source
        (cl-assert (string-match-p "^// - gamma$" (buffer-string)))
        (cl-assert (string-match-p "^// alpha$" (buffer-string)))
        (cl-assert (string-match-p "^int x;$" (buffer-string))))))

  ;; Manual symbol marks navigate actual occurrences without stealing Evil keys.
  (with-temp-buffer
    (emacs-lisp-mode)
    (evil-normal-state)
    (insert "(let ((value 1))\n  (+ value value))\n")
    (goto-char (point-min))
    (search-forward "value")
    (backward-char 5)
    (let ((insert-key (key-binding (kbd "i")))
          (next-key (key-binding (kbd "n"))))
      (call-interactively #'symbol-overlay-put)
      (cl-assert (not (bound-and-true-p symbol-overlay-mode)))
      (cl-assert (= (length (symbol-overlay-get-list 0)) 3))
      (cl-assert (seq-every-p (lambda (overlay) (not (overlay-get overlay 'keymap)))
                             (symbol-overlay-get-list 0)))
      (cl-assert (eq (key-binding (kbd "i")) insert-key))
      (cl-assert (eq (key-binding (kbd "n")) next-key))
      (let ((start (point)))
        (call-interactively #'symbol-overlay-jump-next)
        (cl-assert (> (point) start))
        (call-interactively #'symbol-overlay-jump-prev)
        (cl-assert (= (point) start)))
      (call-interactively #'symbol-overlay-remove-all)
      (cl-assert (null (symbol-overlay-get-list 0)))
      (cl-assert (null symbol-overlay-keywords-alist))))

  ;; Synthetic Imenu bookkeeping must disappear without mutating the input.
  (let* ((input '(("Parent" ("." . 1) ("Child" . 2))
                  ("Parent" . 1) ("-" ("Leaf" . 3)) ("End" . 4)))
         (copy (copy-tree input))
         (clean (my/imenu-clean-tree input)))
    (cl-assert (equal clean '(("Parent" ("Child" . 2)) ("Leaf" . 3) ("End" . 4))))
    (cl-assert (equal input copy))
    (push clean snapshot))
  (cl-assert
   (equal (my/consult-imenu-drop-pseudo
           (lambda () '(("Parent ." . 1) ("." . 2) ("Child" . 3))))
          '(("Child" . 3))))
  ;; These packages are `:defer t' in the configuration, so the test loads the
  ;; ones whose `:custom' values it snapshots below.
  (dolist (feature '(corfu corfu-popupinfo corfu-auto consult embark
                     imenu-list breadcrumb vertico marginalia))
    (require feature))
  (dolist (variable '(completion-styles completion-category-overrides consult-preview-key
                     consult-narrow-key prefix-help-command corfu-auto corfu-auto-delay
                     corfu-auto-prefix corfu-cycle corfu-preselect corfu-on-exact-match
                     corfu-quit-no-match corfu-popupinfo-delay org-capture-templates
                     org-babel-load-languages org-refile-targets org-export-backends
                     org-imenu-depth org-confirm-babel-evaluate org-babel-python-command
                     imenu-list-position imenu-list-size imenu-list-auto-update
                     breadcrumb-imenu-max-length breadcrumb-imenu-crumb-separator))
    (push (cons variable (symbol-value variable)) snapshot))
  (dolist (key '("zo" "zO" "zc" "za" "zr" "zm" "C-a"))
    (push (cons key (lookup-key evil-normal-state-map key)) snapshot))
  ;; Popup-only keys added by `my/init-completion-activate'.  `C-d' and `M-.'
  ;; are unbound in `corfu-map' upstream; the orderless separator (`M-SPC')
  ;; and `corfu-quit-at-boundary' are Corfu 2.x defaults, so they must stay.
  (cl-assert (eq (lookup-key corfu-map (kbd "C-d")) #'corfu-info-documentation))
  (cl-assert (eq (lookup-key corfu-map (kbd "M-.")) #'corfu-info-location))
  (cl-assert (eq (lookup-key corfu-map (kbd "M-SPC")) #'corfu-insert-separator))
  (cl-assert (eq corfu-quit-at-boundary 'separator))
  (when-let* ((file (getenv "EMACS_MODE_SNAPSHOT")))
    (with-temp-file file
      (let ((print-length nil) (print-level nil))
        (prin1 snapshot (current-buffer))))))
;; Exercise the actual right outline window and heading navigation.
(let ((buffer (generate-new-buffer "outline-regression.org")))
  (unwind-protect
      (progn
        (switch-to-buffer buffer)
        (insert "* Parent\nBody\n** Child\nText\n")
        (org-mode)
        (goto-char (point-min))
        (imenu-list-smart-toggle)
        (imenu-list-update t)
        (let ((window (get-buffer-window imenu-list-buffer-name)))
          (cl-assert (window-live-p window))
          (select-window window)
          (goto-char (point-min))
          (search-forward "Child")
          (imenu-list-goto-entry)
          (cl-assert (eq (current-buffer) buffer))
          (cl-assert (looking-at "\\*\\* Child")))
        (imenu-list-smart-toggle)
        (cl-assert (null (get-buffer-window imenu-list-buffer-name))))
    (imenu-list-minor-mode -1)
    (with-current-buffer buffer (set-buffer-modified-p nil))
    (kill-buffer buffer)))
(princ "PASS: Org reading, completion, outline navigation and Evil bindings\n")
