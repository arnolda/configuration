(message "start reading init.el")

(add-to-list 'load-path "~/.emacs.d/packages")
(load "~/.emacs.d/local.el")
(load custom-file)

(server-start)

(define-coding-system-alias 'native 'utf-8)
(define-coding-system-alias 'utf8 'utf-8)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; melpa
(message "setup packages")

(require 'package)

(add-to-list 'package-archives
       '("melpa" . "http://melpa.org/packages/") t)
(package-initialize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; general
(message "general setup")

(defun switch-to-next-buffer ()
  "switch to the next buffer a la alt-tab"
  (interactive)
  (let ((l (cdr (window-list))))
    (if l
        (select-window (car l))
      (switch-to-buffer (other-buffer (current-buffer) 1)))))

(global-set-key [(control tab)] 'switch-to-next-buffer)

;; colored buffers
(require 'font-lock)
;; pretty printing
(require 'printing)
;; better subversion status line
(require 'psvn)

(require 'whitespace)
(global-whitespace-mode t)

;; intelligent selection
(add-hook 'mouse-track-click-hook 'id-select-double-click-hook)

(defun delete-file-and-buffer ()
  "Kill the current buffer and deletes the file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (when filename
      (delete-file filename)
      (message "Deleted file %s" filename)
      (kill-buffer))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; show/hide blocks

(add-hook 'tcl-mode-hook 'hs-minor-mode)
(add-hook 'c-mode-hook 'hs-minor-mode)
(add-hook 'c++-mode-hook 'hs-minor-mode)
(add-hook 'python-mode-hook 'hs-minor-mode)
(add-hook 'lua-mode-hook 'hs-minor-mode)

(global-set-key [(control h) (control h)] 'hs-hide-block)
(global-set-key [(control h) (control s)] 'hs-show-block)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; shell

(message "setup shell")

;; tab completion for shell commands
(require 'shell-command)
(shell-command-completion-mode)

;; remote file access
(require 'tramp)
(setq tramp-default-method "sshx")

(defun new-compilation-buffer (command)
  "Renames existing *compilation* buffer to something unique so
      that a new compilation job can be run."
  (interactive
   (list
    (let ((command (eval compile-command)))
      (if (or compilation-read-command current-prefix-arg)
          (compilation-read-command command)
        command))))
  (let ((cbuf (get-buffer "*compilation*"))
        (more-cbufs t)
        (n 1)
        (new-cbuf-name ""))
    (when cbuf
      (while more-cbufs
        (setq new-cbuf-name (format "*compilation%d*" n))
        (setq n (1+ n))
        (setq more-cbufs (get-buffer new-cbuf-name)))
      (with-current-buffer cbuf
        (rename-buffer new-cbuf-name)))
    (compile command)
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Mixed HTML+CCS+...
(message "setup web-mode")

(require 'web-mode)

(add-to-list 'magic-mode-alist '("\\(?:<\\?xml\\s +[^>]*>\\)?\\s *<\\(?:!--\\(?:[^-]\\|-[^-]\\)*-->\\s *<\\)*\\(?:!DOCTYPE\\s +[^>]*>\\s *<\\s *\\(?:!--\\(?:[^-]\\|-[^-]\\)*-->\\s *<\\)*\\)?[Hh][Tt][Mm][Ll]" . web-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Python
(message "setup Python")

(elpy-enable)

(require 'column-marker)
(add-hook 'python-mode-hook
          (lambda () (interactive)
            (column-marker-1 (+ fill-column 1))
            (column-number-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; C/C++
(message "setup C++")

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.cu\\'" . c++-mode))

;; automatic header/source file handling
(setq headerpattern "\\.\\(h\\|H\\|hh\\|hpp\\|hxx\\)$"
      sourcepattern "\\.\\(c\\|C\\|cc\\|cpp\\|cxx\\)$")

(defun c-complement (file)
  (let ((class (file-name-nondirectory (file-name-sans-extension file)))
        (dir (file-name-directory file)))
    (cond ((string-match sourcepattern file)
           (let ((files (directory-files
                         dir nil (concat "^" class headerpattern) nil)))
             (if files
                 (car files)
               (concat class ".hpp"))))
          ((string-match headerpattern file)
           (let ((files (directory-files
                         dir nil (concat "^" class sourcepattern) nil)))
             (if files
                 (car files)
               (concat class ".cpp"))
             ))))
  )

(defun make-class-frame ()
  (interactive)
  (let ((compl (c-complement buffer-file-name)))
    (if compl
        (progn (select-window (split-window))
               (find-file compl))
      (error "could not determine complement file")))
  )

(defun my-cpp-hook ()
  (interactive)
  (define-key c-mode-map [f5] 'make-class-frame)
  (define-key c++-mode-map [f5] 'make-class-frame)
  (c-set-style "gnu")
  )

(add-hook 'c++-mode-hook 'my-cpp-hook)
(add-hook 'c-mode-hook 'my-c-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Tcl
(add-to-list 'auto-mode-alist '("\\.tcl\\'" . tcl-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; lua
(require 'lua-mode)
(add-to-list  'auto-mode-alist '("\\.lua\\'" . lua-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; puppet
(require 'puppet-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; gnuplot mode
(require 'gnuplot-mode)

(setq auto-mode-alist (append '(("\\.plot$" . gnuplot-mode)) auto-mode-alist))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; LaTeX / text
(message "setup LaTeX")

(set-default 'ispell-local-dictionary "de")
(setq-default ispell-program-name "aspell")

(require 'lorem-ipsum)

(defun wc ()
  "Count words in the region"
  (interactive)
  (message "Word count: %s" (how-many "\\w+" (region-beginning) (region-end))))

(require 'tex-site)
(require 'auctex-latexmk)
(auctex-latexmk-setup)

(defun mylhook ()
  (setq time-stamp-active t)
  (auto-fill-mode t)
  (LaTeX-math-mode)
  )

(add-hook 'write-file-hooks 'time-stamp)
(add-hook 'LaTeX-mode-hook 'mylhook)

(setq TeX-style-private '("~/.emacs.d/auctex"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; short cuts

(global-set-key [f2] 'isearch-forward)

(global-set-key [f3] 'delete-window)
(global-set-key [(shift f3)] 'delete-frame)

(defun kill-current-buffer ()
  "Kill the current buffer"
  (interactive)
  (kill-buffer nil)
  )
(global-set-key [f4] 'kill-current-buffer)
(global-set-key [f6] 'new-frame)

(global-set-key [f7] 'next-error)
(global-set-key [(shift f7)] 'previous-error)
(global-set-key [f8] 'new-compilation-buffer)
(global-set-key [f9] 'recompile)
(global-set-key [(shift f9)] 'compile)

(global-set-key [f12] 'abort-recursive-edit)

(message "done reading init.el")
