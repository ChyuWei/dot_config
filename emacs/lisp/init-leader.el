;;; init-leader.el --- Leader key and its commands -*- lexical-binding: t; -*-

;;; Commentary:

;; `my/leader-bindings' is the feature table of the `vim' profile: SPC in
;; Evil's normal, visual, motion and operator state (`my/leader-map').
;;
;; The `emacs' profile deliberately has no leader.  Mirroring this table
;; under `C-c' produced very un-native Emacs -- three-key chords duplicating
;; what `C-x', `M-g', `M-s' and the major modes already do -- so that
;; profile uses native Emacs keys only, and feature commands live on `M-x'.
;; Hidden compatibility aliases (nil label) are Vim-only.

;;; Code:

;;; Bindings and menu labels --------------------------------------------------------------

;; LazyVim-style keys: each entry declares its command and menu label once.
;; A nil label keeps a compatibility alias usable but hidden in which-key.
;; https://www.lazyvim.org/keymaps
(defconst my/leader-bindings
  '(("SPC" my/find-project-file "查找项目文件")
    ("," consult-buffer "切换缓冲区")
    ("/" consult-ripgrep "搜索项目内容")
    (":" execute-extended-command "执行命令")
    ("." scratch-buffer "打开草稿")
    ("e" my/dirvish-side "切换文件侧栏")
    ("E" dired-jump "打开文件所在目录")
    ("-" split-window-below "上下分屏")
    ("|" split-window-right "左右分屏")
    ("`" my/switch-other-buffer nil)
    ("b b" my/switch-other-buffer "切回上一缓冲区")
    ("b s" scratch-buffer "打开草稿")
    ("b i" ibuffer "列出所有缓冲区")
    ("b d" kill-current-buffer "关闭缓冲区")
    ("b D" kill-buffer-and-window "关闭缓冲区及窗口")
    ("b j" consult-buffer "选择缓冲区")
    ("f f" find-file "打开文件（同 C-x C-f）")
    ("f F" consult-fd "查找当前目录文件")
    ("f d" my/dirvish-fd "fd 搜索结果（可编辑 dired）")
    ("f b" consult-buffer "切换缓冲区")
    ("f c" my/open-init-file "打开 Emacs 配置")
    ("f e" my/dirvish-side "切换文件侧栏")
    ("f z" consult-zoxide "跳到最近用过的目录")
    ("f E" dired-jump "打开文件所在目录")
    ("f n" my/new-file "新建文件")
    ("f r" consult-recent-file "最近文件")
    ("f p" project-switch-project "切换项目")
    ("f s" save-buffer "保存文件")
    ("f t" project-shell "打开项目 Shell")
    ("f T" shell "打开 Shell")
    ("s b" consult-line "搜索当前缓冲区")
    ("s g" consult-ripgrep "搜索项目内容")
    ("s G" my/grep-directory "搜索当前目录")
    ("s s" my/jump-to-heading "跳转标题 / 符号")
    ("s r" query-replace "查找并替换")
    ("s c" consult-history "输入历史")
    ("s C" execute-extended-command "执行命令")
    ("s h" apropos-command "搜索帮助")
    ("s k" describe-bindings "查看按键绑定")
    ("s m" consult-mark "跳转标记")
    ("s d" consult-flymake "搜索诊断")
    ("s H" symbol-overlay-put "标记 / 取消当前符号")
    ("s n" symbol-overlay-jump-next "下一个同名符号")
    ("s p" symbol-overlay-jump-prev "上一个同名符号")
    ("s u" symbol-overlay-remove-all "清除符号标记")
    ("w h" windmove-left "切到左侧窗口")
    ("w j" windmove-down "切到下方窗口")
    ("w k" windmove-up "切到上方窗口")
    ("w l" windmove-right "切到右侧窗口")
    ("w w" other-window "切到下一窗口")
    ("w d" delete-window "关闭当前窗口")
    ("w m" delete-other-windows "仅保留当前窗口")
    ("w -" split-window-below "上下分屏")
    ("w |" split-window-right "左右分屏")
    ("c a" eglot-code-actions "代码操作")
    ("c r" eglot-rename "重命名符号")
    ("c f" eglot-format "格式化代码")
    ("c l" eglot "连接语言服务器")
    ("c q" eglot-shutdown "断开语言服务器")
    ("c R" eglot-reconnect "重连语言服务器")
    ("c d" flymake-show-buffer-diagnostics "查看当前文件诊断")
    ("c s" imenu-list-smart-toggle "切换符号大纲")
    ("g g" magit-status "仓库状态")
    ("g s" magit-status "仓库状态")
    ("g d" magit-diff-working-tree "工作区差异")
    ("g b" magit-blame "逐行追溯")
    ("g f" magit-log-buffer-file "当前文件历史")
    ("g l" magit-log-current "仓库提交历史")
    ("u w" visual-line-mode "切换自动折行")
    ("u l" display-line-numbers-mode "切换行号")
    ("u d" flymake-mode "切换诊断")
    ("u z" olivetti-mode "切换居中写作")
    ("u c" my/markdown-toggle-markup "切换 Markdown 标记")
    ("u m" mode-line-invisible-mode "切换模式行显示")
    ("q q" save-buffers-kill-emacs "退出 Emacs（询问保存）")
    ("n a" org-agenda "打开议程")
    ("n c" org-capture "捕获笔记")
    ("n l" org-store-link "存储当前位置链接")
    ("i" consult-imenu nil)
    ("o" imenu-list-smart-toggle nil)
    ("h" my/jump-to-heading nil)
    ("a" org-agenda nil)
    ("l" org-store-link nil)
    ("r" consult-ripgrep nil)
    (";" embark-dwim "执行对象默认操作")
    ("T" org-tree-slide-mode "切换大纲演示")
    ("A d" dsh-emacs "AI 会话（DeepSeek Harness）")
    ("j j" avy-goto-char-timer "按字符跳转")
    ("j l" avy-goto-line "按行跳转")
    ("m h" my/markdown-toggle-markup "切换标记显示")
    ("m i" my/markdown-toggle-images "切换内联图片")
    ("m ." embark-act "对当前对象执行操作"))
  "Leader bindings as (KEY COMMAND LABEL); nil LABEL hides the entry.")

(defconst my/leader-macos-bindings
  (when (eq system-type 'darwin)
    '(("A a" appine "Appine（浏览器 / PDF）")
      ("A u" appine-open-url "用 Appine 打开 URL")
      ("A o" appine-open-file "用 Appine 打开文件")))
  "Leader bindings for macOS-only applications.")

(defconst my/leader-groups
  '(("b" . "+缓冲区")
    ("f" . "+文件 / 项目")
    ("s" . "+搜索 / 跳转")
    ("w" . "+窗口")
    ("c" . "+代码")
    ("g" . "+Git")
    ("u" . "+显示 / 开关")
    ("q" . "+退出")
    ("n" . "+Org 笔记")
    ("m" . "+Markdown / 操作")
    ("j" . "+屏内跳转")
    ("A" . "+应用"))
  "Leader prefix keys and their which-key labels.")

;;; The Vim-side map -------------------------------------------------------

(defvar my/leader-map (make-sparse-keymap)
  "Prefix map bound to SPC in the `vim' profile.")

(defvar my/leader-jump-map (make-sparse-keymap)
  "`j' group: on-screen jumps.")

(defvar my/leader-markdown-map (make-sparse-keymap)
  "`m' group: Markdown and object actions.")

(dolist (group my/leader-groups)
  (define-key my/leader-map (kbd (car group))
              (pcase (car group)
                ("j" my/leader-jump-map)
                ("m" my/leader-markdown-map)
                (_ (make-sparse-keymap)))))

(dolist (binding (append my/leader-bindings my/leader-macos-bindings))
  (define-key my/leader-map (kbd (car binding)) (cadr binding)))

;; Most built-in commands already have autoloads.  Add only the missing
;; interactive entry points; binding a key must not load Eglot/Org at startup.
(dolist (entry '((eglot-code-actions . "eglot")
                 (eglot-format . "eglot")
                 (eglot-rename . "eglot")
                 (eglot-shutdown . "eglot")
                 (eglot-reconnect . "eglot")
                 (flymake-goto-prev-error . "flymake")
                 (flymake-goto-next-error . "flymake")
                 (flymake-show-buffer-diagnostics . "flymake")
                 (org-store-link . "ol")))
  (autoload (car entry) (cdr entry) nil t))

;;; Install / uninstall ----------------------------------------------------

(defun my/leader-evil-local-setup ()
  "Make SPC the leader in the current buffer's Evil state maps.
Several major modes (Dired and everything derived from `special-mode',
such as help, grep and the outline sidebar) bind SPC in their local map,
which would shadow the global leader; a buffer-local Evil binding has
higher precedence than the major mode map."
  (when (and (eq my/keybinding-profile 'vim)
             (bound-and-true-p evil-local-mode))
    (dolist (state '(normal visual motion operator))
      (evil-local-set-key state (kbd "SPC") my/leader-map))))

(defun my/leader-install-vim ()
  "Bind `my/leader-map' to SPC in Evil's states."
  (require 'evil)
  (dolist (state '(normal visual motion operator))
    (evil-global-set-key state (kbd "SPC") my/leader-map))
  (add-hook 'evil-local-mode-hook #'my/leader-evil-local-setup)
  ;; Buffers that already exist will not run the hook again.
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (my/leader-evil-local-setup))))

(defun my/leader-uninstall-vim ()
  "Remove the SPC leader from Evil's global and local state maps."
  (remove-hook 'evil-local-mode-hook #'my/leader-evil-local-setup)
  (when (featurep 'evil)
    (dolist (state '(normal visual motion operator))
      (evil-global-set-key state (kbd "SPC") nil))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (bound-and-true-p evil-local-mode)
          (dolist (state '(normal visual motion operator))
            (evil-local-set-key state (kbd "SPC") nil)))))))

(defun my/leader-install ()
  "Install the leader when the `vim' profile is active."
  (if (eq my/keybinding-profile 'vim)
      (my/leader-install-vim)
    (my/leader-uninstall-vim)))

(defun my/leader-uninstall ()
  "Remove the leader, leaving no stale keys behind."
  (my/leader-uninstall-vim))

;;; Which-key --------------------------------------------------------------

(defvar my/which-key-entries nil
  "which-key entries pushed by this configuration, for later removal.")

(defun my/leader-which-key-specs ()
  "Return (KEY . LABEL) which-key entries for the Vim leader.
A nil LABEL hides the key.  The `emacs' profile has no leader, so the
list is empty there."
  (when (eq my/keybinding-profile 'vim)
    (let ((prefix "SPC")
          specs)
      (push (cons prefix "快捷菜单") specs)
      (dolist (group my/leader-groups)
        (push (cons (concat prefix " " (car group)) (cdr group)) specs))
      (dolist (entry (append my/leader-bindings my/leader-macos-bindings))
        (push (cons (concat prefix " " (car entry)) (nth 2 entry)) specs))
      (nreverse specs))))

(defun my/which-key-refresh ()
  "Re-register this configuration's which-key labels for the active profile."
  (require 'which-key nil t)
  (when (boundp 'which-key-replacement-alist)
    (setq which-key-replacement-alist
          (seq-difference which-key-replacement-alist my/which-key-entries))
    (setq my/which-key-entries nil)
    (dolist (spec (my/leader-which-key-specs))
      (let* ((key (car spec))
             (label (cdr spec))
             (regexp (concat "\\`" (regexp-quote (key-description (kbd key))) "\\'")))
        (cond
         (label
          (which-key-add-key-based-replacements key label)
          (push (cons (cons regexp nil) (cons nil label)) my/which-key-entries))
         (t
          ;; A non-cons replacement makes which-key ignore the binding.
          (let ((entry (cons (cons regexp nil) t)))
            (push entry which-key-replacement-alist)
            (push entry my/which-key-entries))))))))

(provide 'init-leader)

;;; init-leader.el ends here
