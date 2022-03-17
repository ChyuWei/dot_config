
(require 'init-funcs)

(ensure-straight)

(straight-use-package 'use-package)
(eval-and-compile
  (setq use-package-always-defer t)
  (setq use-package-expand-minimally t))

(eval-when-compile
  (require 'use-package))

(use-package diminish :straight t)
(use-package bind-key :straight t)    

(provide 'init-package)
