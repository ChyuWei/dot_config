;;; init-defaults.el --- Editing and session defaults -*- lexical-binding: t; -*-

;;; Commentary:

;; Sensible built-in behaviour: files, history, scrolling, mouse, prose
;; wrapping, programming niceties, formatting on save, plus the Dirvish
;; integrations.  Search backends (ripgrep for xref, fd for file names) are set
;; here too; the tree-sitter mode list lives here as well.
;;
;; The file has three parts, in this order:
;;
;;   1. Settings    -- `setq'/`setq-default' only.  Run while the file loads.
;;   2. Definitions -- hooks that run per buffer, functions, and `use-package'
;;                     declarations whose packages stay deferred.
;;   3. Activation  -- global minor modes and package loading, registered at
;;                     the end.  Almost all of it runs from
;;                     `my/after-init-hook', because command-line files are
;;                     opened right after that hook: they need line numbers
;;                     and tree-sitter remapping, they must land in recentf,
;;                     and `save-place' has to restore their position (that
;;                     mode only adds a `find-file-hook').  Formatting on save
;;                     is registered last, since saving comes much later.
;;                     Only savehist, auto-revert and winner-mode wait for
;;                     `my/idle-hook'.

;;; Code:

;;; Part 1: settings -------------------------------------------------------

;;; Files and persistence

(setq backup-by-copying t
      version-control t
      delete-old-versions t
      kept-new-versions 5
      kept-old-versions 2
      create-lockfiles nil
      require-final-newline t
      vc-follow-symlinks t
      large-file-warning-threshold (* 50 1024 1024))

;; recentf itself is loaded by `my/init-defaults-activate-files', which
;; also adds the package directories to `recentf-exclude' after the library
;; (and its defaults) are in place.
(setq recentf-max-saved-items 200
      recentf-max-menu-items 25)

(setq history-length 1000
      history-delete-duplicates t)
(setq global-auto-revert-non-file-buffers t)

;;; Typing and editing

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80
              sentence-end-double-space nil)

(setq use-short-answers t
      enable-recursive-minibuffers t
      read-extended-command-predicate #'command-completion-default-include-p
      completion-ignore-case t
      read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t)

(setq select-enable-clipboard t
      save-interprogram-paste-before-kill t
      mouse-yank-at-point t
      kill-do-not-save-duplicates t)

(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))

;;; Mouse and trackpad

;; `C-x C-=' style scrolling keeps point where it is on screen; without this a
;; trackpad flick drags point off the visible area and forces a recenter.
;; Dragging a selection to another window or to another app is the macOS habit.
;; `context-menu-mode' (turned on after init, with the other global modes)
;; replaces the default right-click, which is `mouse-save-then-kill' -- on a
;; Mac that reads as "right click deletes my selection".
(setq scroll-preserve-screen-position t
      mouse-drag-and-drop-region t)

;; Isearch settings apply to Vim-style searching too: `evil-search-module' is
;; `isearch', so `/`, `?`, `n` and `N` all run through isearch -- `C-s` being
;; bound to save-buffer changes how a search is *started*, not what it does.
;; Nothing here is about speed (isearch is already in-process: a match is
;; microseconds, and lazy highlighting only scans what is on screen); these are
;; feel.
(setq isearch-wrap-pause 'no                  ; wrap silently, no pause at the end
      isearch-repeat-on-direction-change t    ; C-r after C-s moves to the next match
      isearch-allow-scroll t                  ; C-v / M-v / C-l work while searching
      ;; Shows 3/17.  This is the only setting with a cost: the count walks the
      ;; whole buffer (~14ms per MB, in slices).  Set it to nil for huge files.
      isearch-lazy-count t)

;; Smooth, readable scrolling.  Pixel scrolling must keep the stock
;; recentering rules: a high `scroll-conservatively' makes redisplay
;; chase point on every frame and the pinning stops the buffer scrolling
;; to the very top or bottom under the wheel.
;;
;; `line-spacing' is a pair (ABOVE . BELOW) since Emacs 31: a plain number
;; only adds space below the line, which makes the text hug the top of its
;; line box -- visible in the cursor bar, in `hl-line' bands and in tables.
;; The shares are split, not doubled: the total stays the 0.25 it used to be.
(setq-default scroll-margin 0
              echo-keystrokes 0.02
              line-spacing '(0.125 . 0.125))

(setq ring-bell-function #'ignore
      window-combination-resize t)

;;; Prose vs code

(setq visual-line-fringe-indicators nil)

;; Line numbers are on by default; `my/prose-layout' disables them in
;; Markdown and Org prose buffers.  `t' means absolute numbers; the width starts at
;; three columns and only grows, so the text does not jump around.
(setq display-line-numbers-type t
      display-line-numbers-width 3
      display-line-numbers-grow-only t)

;;; Dired

(setq dired-listing-switches "-alh"
      dired-dwim-target t
      dired-recursive-copies 'always
      dired-recursive-deletes 'top)

;;; Search

;; `xref' ships a ripgrep template but defaults to grep; ripgrep is
;; installed (see init-env.el) and honours .gitignore, so the text-search
;; commands stop walking elpa/ and native-compiled artifacts.  Used by
;; `project-find-regexp' (`C-x p g'), `dired-do-find-regexp' and by
;; `xref-find-references' (`M-?') only when no backend serves it -- buffers
;; Eglot manages ask the language server instead.
(setq-default xref-search-program 'ripgrep)

;; File-name search goes through fd (see `consult-fd' and `my/dirvish-fd'):
;; fd honours .gitignore/.ignore and runs in parallel, so it lists a big tree
;; in a fraction of the time `find' needs.  `--hidden' is what makes dotfiles
;; reachable (.github/, .zshrc); ignore files still apply, and the .git
;; directory itself is worth excluding by name because fd would otherwise show
;; its internals.  `--full-path' lets the input match against the whole path.
(setq consult-fd-args
      '((if (executable-find "fdfind" 'remote) "fdfind" "fd")
        "--color=never" "--full-path" "--hidden" "--exclude" ".git"))

;;; Misc

(setq use-file-dialog nil
      use-dialog-box nil
      uniquify-buffer-name-style 'forward)

;;; Part 2: definitions ----------------------------------------------------

(require 'seq)

(declare-function dired-hide-details-mode "dired")
(declare-function dirvish-quit "dirvish")
(declare-function dirvish-side "dirvish-side")
(declare-function dirvish-side-follow-mode "dirvish-side")

;;; Per-buffer hooks

;; Wrapped lines for prose buffers.  Org and Markdown inherit from
;; text-mode, and enable this explicitly as well.
(add-hook 'text-mode-hook (lambda () (visual-line-mode 1)))

;; Programming buffers: pair completion, current line and code folding.
(defun my/prog-mode-setup ()
  "Set up a programming buffer: pairing, current line, folding.
Folding is `hs-minor-mode' (kirigami routes the `z' keys to that backend),
but its overlay is shortened to the line before the closing delimiter:
otherwise `} else {' is glued onto the folded line and an if/else chain looks
like one line.  That is what `hs-adjust-block-end-function' -- new in Emacs
31 -- is for; the old recipe moved the overlay in `hs-set-up-overlay'."
  (electric-pair-mode 1)
  (hl-line-mode 1)
  (require 'hideshow)
  (hs-minor-mode 1)
  (setq-local hs-adjust-block-end-function
              (lambda (beg) (max beg (1- (line-beginning-position))))))

(add-hook 'prog-mode-hook #'my/prog-mode-setup)

;; Indentation guides in code and YAML; prose keeps its reading layout.
;; Character bars also work in terminals and avoid stipple/font dependencies.
(use-package indent-bars
  :ensure t
  :hook ((prog-mode yaml-ts-mode) . indent-bars-mode)
  :custom
  (indent-bars-prefer-character t)
  (indent-bars-color-by-depth nil)
  (indent-bars-no-descend-lists nil))

;; Code reading: nested delimiter colors and manually pinned symbols.
(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

;; No idle highlighting mode: loading and scanning start with an explicit
;; command.  Keep plain letters on marked text available to Evil and typing.
(use-package symbol-overlay
  :ensure t
  :bind (("M-s h ." . symbol-overlay-put)
         ("M-s h n" . symbol-overlay-jump-next)
         ("M-s h b" . symbol-overlay-jump-prev)
         ("M-s h c" . symbol-overlay-remove-all))
  :config
  (setq symbol-overlay-inhibit-map t))

;;; CJK word motion

;; emt: CJK-aware word motion via macOS NLP.  Installed from the fork with
;; `:vc' (no tags, so `:newest'); the native module lives in modules/
;; (ignored) and loaded on idle, not during startup.
(use-package emt
  :if (eq system-type 'darwin)
  :vc (:url "https://github.com/ChyuWei/emt" :rev :newest)
  :defer t)

;; Line numbers refer to listing rows in Dired, not file contents.
(add-hook 'dired-mode-hook
          (lambda () (display-line-numbers-mode -1)))
(add-hook 'dired-mode-hook #'dired-hide-details-mode)

;;; File, project and buffer commands --------------------------------------

(defun my/open-init-file ()
  "Open this Emacs configuration."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

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

;;; Dirvish

;; Loaded on first use by `my/dirvish-side' or by `C-x d'.
(use-package dirvish
  :ensure t
  :defer t
  :config
  ;; Dirvish 2.3 keeps side/subtree extensions outside its autoload path.
  (add-to-list 'load-path
               (expand-file-name "extensions"
                                 (file-name-directory (locate-library "dirvish"))))
  (require 'dirvish-side)
  (require 'dirvish-fd)
  (dirvish-override-dired-mode 1)
  (dirvish-side-follow-mode 1))

(defun my/dirvish-fd (pattern)
  "Search the current directory with fd and show the hits as a Dired buffer.
Unlike `consult-fd' (jump to one file) this keeps the results around: the
buffer is a real Dired/Dirvish buffer, so marks, batch rename and wgrep work
on the hits.  PATTERN is comma separated, as `dirvish-fd' expects."
  (interactive (list (read-string "fd pattern (comma separated): ")))
  (require 'dirvish)
  (require 'dirvish-fd)
  (dirvish-fd default-directory pattern))

(defun my/dirvish-side-window ()
  "Return the window showing a visible Dirvish side session, if any.
Detected with Dirvish's public `dirvish-curr' plus the built-in
`window-side' parameter, so no private session helper is involved."
  (seq-find (lambda (window)
              (and (window-parameter window 'window-side)
                   (with-current-buffer (window-buffer window)
                     (dirvish-curr))))
            (window-list nil 'nomini)))

(defun my/dirvish-side ()
  "Toggle the current frame's Dirvish sidebar, loading it on first use."
  (interactive)
  (require 'dirvish)
  ;; Close a visible tree even when an editing window is selected.
  (if-let* ((window (my/dirvish-side-window)))
      (progn
        (select-window window)
        (dirvish-quit))
    (dirvish-side)))

;;; Tree-sitter modes

;; no-littering adds var/treesit/ to `treesit-extra-load-path'.  Ensure it
;; exists so both the native installer and build-tree-sitter.sh use it.
(with-eval-after-load 'treesit
  (make-directory (no-littering-expand-var-file-name "treesit/") t))

;; Markdown, markdown-inline, Python and Rust live in var/treesit/ (the first
;; three from build-tree-sitter.sh, rust from the installer) and toml ships with
;; Emacs 31.  Only those modes are remapped, by `treesit-enabled-modes', which
;; writes a static entry into `major-mode-remap-alist' -- the table
;; `set-auto-mode' already consults.  Measured on 200 files: 6.0ms each.
;;
;; A mode must NOT be listed before its grammar is installed: the built-in
;; remap is unconditional, so an uninstalled language would land in a
;; tree-sitter mode with no fontification (and its `-ts-mode' function would
;; ask whether to install the grammar, `treesit-auto-install-grammar').  After
;; installing one (`M-x treesit-install-language-grammar', or
;; build-tree-sitter.sh), add its ts-mode to the list below.
(defconst my/treesit-enabled-ts-modes
  '(rust-ts-mode python-ts-mode toml-ts-mode)
  "Tree-sitter modes to enable, i.e. the ones whose grammar is installed.")

;; Declared for the byte compiler; set for real once treesit is loaded.
(defvar treesit--install-language-grammar-out-dir-history)

;;; Formatting

;; Format on save without blocking: apheleia pipes the buffer through an
;; external formatter asynchronously and applies its output as a diff, so
;; point and scroll position survive and a slow formatter never freezes the
;; save.  gofmt and rustfmt are installed on this machine; a mode whose
;; formatter is missing is skipped silently, so apheleia's own mode list is
;; kept as it ships.
(use-package apheleia
  :ensure t
  :defer t)

;;; Separate editing

;; `separedit' lifts the comment block, string, docstring or code block at
;; point into its own buffer with the comment prefixes and quotes stripped,
;; and writes it back with `C-c C-c'.  The edit buffer runs markdown-mode, so
;; markdown inside a docstring or a C comment is edited as markdown, and a
;; fenced block inside it can be entered again with `C-c ''.
;;
;; Two limits worth knowing: it finds a comment through the font-lock face, so
;; the block must be fontified (always true in a displayed buffer); and `.md'
;; files open in the built-in `markdown-ts-mode', which separedit does not
;; know -- its markdown support is `markdown-edit-code-block', i.e.
;; `markdown-mode'.  Org keeps its own `C-c '' (`org-edit-special').
(use-package separedit
  :ensure t
  :defer t
  :bind (("C-c '" . separedit))
  :custom
  (separedit-default-mode 'markdown-mode))

;;; Persistent scratch

;; `*scratch*' is where throwaway notes and REPL snippets go; keep its text,
;; point and major mode across restarts.  The state file lives under var/ with
;; the rest of the runtime data, and `persistent-scratch-mode' makes `C-x C-s'
;; save it instead of asking for a file name.
(use-package persistent-scratch
  :ensure t
  :defer t)

;;; Part 3: activation -----------------------------------------------------

(defun my/init-defaults-activate-files ()
  "Load recentf and enable the modes that must see files as they open.
Runs from `my/after-init-hook', which is before command-line files are
visited: `save-place-mode' only adds a `find-file-hook', so a file opened
before it is on never gets its saved position back, and recentf likewise
only records files visited after it is on."
  (require 'recentf)
  ;; Declared after the `require' so the byte compiler knows the variable;
  ;; at runtime it is already defined, so this changes nothing (and in
  ;; particular does not replace recentf's own default excludes).
  (defvar recentf-exclude)
  (dolist (dir '("elpa" "var" "etc"))
    (add-to-list 'recentf-exclude
                 (expand-file-name dir user-emacs-directory)))
  (let ((inhibit-message t))
    (recentf-mode 1))
  (save-place-mode 1))

(defun my/init-defaults-activate-scratch ()
  "Restore `*scratch*' and start autosaving it.
Runs from `my/after-init-hook': the buffer exists by then and the user cannot
have typed into it yet.  Batch sessions are skipped: autosave would overwrite
the user's scratch state when a test exits."
  (unless noninteractive
    (require 'persistent-scratch)
    (let ((file (no-littering-expand-var-file-name "persistent-scratch")))
      (setq persistent-scratch-save-file file)
      ;; The package reports a missing state file as a failed restore; `nil'
      ;; is a valid empty state, so create one on the first run.
      (unless (file-exists-p file)
        (with-temp-file file (insert "nil\n"))
        (set-file-modes file #o600))
      ;; Restoring the saved major mode runs `prog-mode-hook' (the default
      ;; `lisp-interaction-mode' derives from prog-mode), which would load
      ;; indent-bars during startup.  The scratch buffer needs its mode, not
      ;; the programming setup.
      (let ((prog-mode-hook nil))
        (persistent-scratch-setup-default)))))

(defun my/init-defaults-activate-scratch-mode ()
  "Enable `persistent-scratch-mode' in `*scratch*' after startup.
The buffer's major mode is set after `after-init-hook' on some startup paths
(the daemon), and changing the major mode resets buffer-local minor modes."
  (when (and (bound-and-true-p persistent-scratch-autosave-mode)
             (get-buffer "*scratch*"))
    (with-current-buffer "*scratch*"
      (persistent-scratch-mode 1))))

(defun my/init-defaults-activate-session ()
  "Enable the modes that only need to exist before the user interacts.
Runs from `my/idle-hook': they read or write disk, and `savehist' and
`global-auto-revert-mode' also apply to buffers that already exist."
  (savehist-mode 1)
  (global-auto-revert-mode 1)
  (winner-mode 1))

(defun my/init-defaults-activate-display ()
  "Enable the modes that change how buffers are drawn.
Runs from `my/after-init-hook': command-line files are visited after this
hook, so their line numbers are already on when they appear."
  (global-display-line-numbers-mode 1))

(defun my/init-defaults-activate-editing ()
  "Enable the global modes the first keystrokes depend on.
Runs from `my/after-init-hook': typing over a region, trackpad scrolling and
paren blinking would behave differently for the first second otherwise."
  (delete-selection-mode 1)
  (context-menu-mode 1)
  (pixel-scroll-precision-mode 1)
  (repeat-mode 1)
  (show-paren-mode 1)
  (blink-cursor-mode -1)
  ;; Very long lines: degrade font-lock and related modes instead of freezing.
  (global-so-long-mode 1))

(defun my/init-defaults-activate-treesit ()
  "Enable the tree-sitter modes listed in `my/treesit-enabled-ts-modes'.
Runs from `my/after-init-hook': it rewrites `major-mode-remap-alist', which
is too late once a file is already being visited.  `setopt' is required --
the `:set' function of `treesit-enabled-modes' is what fills that alist, so a
plain `setq' would silently change nothing.

Also points the grammar installer at var/treesit/:
`treesit-install-language-grammar' defaults to the `tree-sitter/' directory
beside this configuration (`locate-user-emacs-file'), which is outside the
path no-littering registered and is not ignored by git.  Its default is read
from this history variable; the automatic prompt path already picks the first
writable entry of `treesit-extra-load-path', which is the same directory."
  (require 'treesit)
  (setopt treesit-enabled-modes my/treesit-enabled-ts-modes)
  (setq treesit--install-language-grammar-out-dir-history
        (list (no-littering-expand-var-file-name "treesit/"))))

(defun my/init-defaults-activate-formatting ()
  "Enable format-on-save.
Runs from `my/after-init-hook': saving is a user action that comes much
later, so nothing on the first screen waits for this.  `emacs-lisp-mode' is
dropped from `apheleia-mode-alist' on purpose: its formatter is
`indent-region', which would rewrite the hand-aligned comment blocks this
configuration is made of.  `M-x apheleia-format-buffer' still formats an
Emacs Lisp buffer when asked."
  (require 'apheleia)
  (setq apheleia-mode-alist
        (assq-delete-all 'emacs-lisp-mode apheleia-mode-alist))
  (apheleia-global-mode 1))

(defun my/init-defaults-activate-cjk ()
  "Enable `emt-mode' when its native module exists.
Skip rather than prompt when `emt-lib-path' is missing; fetch it once with
`M-x emt-download-module'.  emt uses macOS NLP, so it is skipped elsewhere."
  (when (eq system-type 'darwin)
    (require 'emt)
    (if (file-exists-p emt-lib-path)
        (emt-mode 1)
      (message "emt module missing at %s; run M-x emt-download-module"
               emt-lib-path))))

(add-hook 'my/after-init-hook #'my/init-defaults-activate-display 10)
(add-hook 'my/after-init-hook #'my/init-defaults-activate-treesit 20)
(add-hook 'my/after-init-hook #'my/init-defaults-activate-files 30)
(add-hook 'my/after-init-hook #'my/init-defaults-activate-scratch 35)
(add-hook 'my/startup-hook #'my/init-defaults-activate-scratch-mode)
(add-hook 'my/after-init-hook #'my/init-defaults-activate-editing 40)
(add-hook 'my/after-init-hook #'my/init-defaults-activate-formatting 50)

(add-hook 'my/idle-hook #'my/init-defaults-activate-session)
(add-hook 'my/idle-hook #'my/init-defaults-activate-cjk)

(provide 'init-defaults)

;;; init-defaults.el ends here
