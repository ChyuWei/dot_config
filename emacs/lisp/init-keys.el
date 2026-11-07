;;; init-keys.el --- Leader key and personal bindings -*- lexical-binding: t; -*-

;;; Commentary:

;; Every personal shortcut lives on the Evil leader key, SPC.  The leader
;; is active in normal, visual, motion and operator states; in insert
;; state SPC is still an ordinary space.  Press SPC and pause to see the
;; available keys in which-key.

;;; Code:

(defvar my/leader-map (make-sparse-keymap)
  "Prefix map bound to the SPC leader key.")

(defvar my/leader-markdown-map (make-sparse-keymap)
  "Markdown commands under the leader key.")

(defvar my/jump-map (make-sparse-keymap)
  "Jumping commands under the leader key.")

(defun my/open-init-file ()
  "Open this Emacs configuration."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(defun my/jump-to-heading ()
  "Jump to a heading, using Org's own heading list when available."
  (interactive)
  (if (derived-mode-p 'org-mode)
      (consult-org-heading)
    (consult-imenu)))

(defun my/markdown-toggle-markup ()
  "Toggle Markdown markup display in the current buffer."
  (interactive)
  (cond
   ((derived-mode-p 'markdown-ts-mode)
    (require 'markdown-ts-appear)
    ;; appear renders the buffer; turning it off shows the raw source.
    (markdown-ts-appear-mode (if markdown-ts-appear-mode -1 1)))
   ((derived-mode-p 'markdown-mode)
    (require 'markdown-mode)
    (markdown-toggle-markup-hiding))
   (t (user-error "Not a Markdown buffer"))))

(defun my/markdown-toggle-images ()
  "Toggle inline image display in the current Markdown buffer."
  (interactive)
  (cond
   ((derived-mode-p 'markdown-ts-mode)
    (markdown-ts-toggle-inline-images))
   ((derived-mode-p 'markdown-mode)
    (require 'markdown-mode)
    (markdown-toggle-inline-images))
   (t (user-error "Not a Markdown buffer"))))

;;; The leader map --------------------------------------------------------

(defun my/find-project-file ()
  "Find a project file, falling back to the current directory."
  (interactive)
  (if (project-current)
      (project-find-file)
    (consult-fd default-directory)))

(defun my/new-file ()
  "Create a new unnamed buffer."
  (interactive)
  (switch-to-buffer (generate-new-buffer "untitled")))

(defun my/switch-other-buffer ()
  "Switch to the previously used buffer."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) t)))

(defun my/grep-directory ()
  "Search the current directory rather than the project root."
  (interactive)
  (consult-ripgrep default-directory))

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
    ("b d" kill-current-buffer "关闭缓冲区")
    ("b D" kill-buffer-and-window "关闭缓冲区及窗口")
    ("b j" consult-buffer "选择缓冲区")
    ("f f" my/find-project-file "查找项目文件")
    ("f F" consult-fd "查找当前目录文件")
    ("f b" consult-buffer "切换缓冲区")
    ("f c" my/open-init-file "打开 Emacs 配置")
    ("f e" my/dirvish-side "切换文件侧栏")
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
    ("g g" vc-dir "仓库状态")
    ("g s" vc-dir "仓库状态")
    ("g d" vc-diff "查看差异")
    ("g b" vc-annotate "逐行追溯")
    ("g f" vc-print-log "当前文件历史")
    ("g l" vc-print-root-log "仓库提交历史")
    ("u w" visual-line-mode "切换自动折行")
    ("u l" display-line-numbers-mode "切换行号")
    ("u s" flyspell-mode "切换拼写检查")
    ("u d" flymake-mode "切换诊断")
    ("u z" olivetti-mode "切换居中写作")
    ("u c" my/markdown-toggle-markup "切换 Markdown 标记")
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
    ("j j" avy-goto-char-timer "按字符跳转")
    ("j l" avy-goto-line "按行跳转")
    ("m h" my/markdown-toggle-markup "切换标记显示")
    ("m i" my/markdown-toggle-images "切换内联图片")
    ("m ." embark-act "对当前对象执行操作"))
  "Leader bindings as (KEY COMMAND LABEL); nil LABEL hides the entry.")

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
    ("j" . "+屏内跳转"))
  "Leader prefix keys and their which-key labels.")

(dolist (group my/leader-groups)
  (define-key my/leader-map (kbd (car group))
              (pcase (car group)
                ("j" my/jump-map)
                ("m" my/leader-markdown-map)
                (_ (make-sparse-keymap)))))

(dolist (binding my/leader-bindings)
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

;;; Bind the leader in the Evil states ------------------------------------

(with-eval-after-load 'evil
  (dolist (binding '(("H" . previous-buffer) ("L" . next-buffer)
                     ("[ b" . previous-buffer) ("] b" . next-buffer)
                     ("[ d" . flymake-goto-prev-error)
                     ("] d" . flymake-goto-next-error)
                     ("[ q" . previous-error) ("] q" . next-error)
                     ("g d" . xref-find-definitions)
                     ("g r" . xref-find-references)
                     ("K" . eldoc-doc-buffer)
                     ("C-h" . windmove-left) ("C-j" . windmove-down)
                     ("C-k" . windmove-up) ("C-l" . windmove-right)))
    (define-key evil-normal-state-map (kbd (car binding)) (cdr binding)))
  (dolist (state '(normal insert visual))
    (evil-global-set-key state (kbd "C-s") #'save-buffer))
  (dolist (map (list evil-normal-state-map
                     evil-visual-state-map
                     evil-motion-state-map
                     evil-operator-state-map))
    (define-key map (kbd "SPC") my/leader-map)))

;; Several major modes (Dired and everything derived from `special-mode',
;; such as help, grep and the outline sidebar) bind SPC in their local
;; map, which would shadow the global leader.  A buffer-local Evil
;; binding has higher precedence than the major mode map, so install it
;; in every buffer where Evil is active.
(defun my/evil-leader-local-setup ()
  "Make SPC the leader in the current buffer's Evil state maps."
  (when (bound-and-true-p evil-local-mode)
    (dolist (state '(normal visual motion operator))
      (evil-local-set-key state (kbd "SPC") my/leader-map))))

(add-hook 'evil-local-mode-hook #'my/evil-leader-local-setup)

;; Buffers that already existed when this file was loaded do not run the
;; hook again.
(with-eval-after-load 'evil
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (my/evil-leader-local-setup))))

;;; Which-key presentation ------------------------------------------------

(with-eval-after-load 'which-key
  ;; Scope labels to SPC; native Emacs prefixes keep their descriptions.
  (which-key-add-key-based-replacements "SPC" "快捷菜单")
  (dolist (group my/leader-groups)
    (which-key-add-key-based-replacements
      (concat "SPC " (car group)) (cdr group)))
  (dolist (binding my/leader-bindings)
    (let ((key (concat "SPC " (car binding)))
          (label (nth 2 binding)))
      (if label
          (which-key-add-key-based-replacements key label)
        (push (cons (cons (concat "\\`" (regexp-quote key) "\\'") nil) t)
              which-key-replacement-alist)))))

(provide 'init-keys)

;;; init-keys.el ends here
