(require 'dsvn)
(require 'log-edit)
(require 'projectile)
(require 'files)

(defun masvn-status ()
  (interactive)
  (projectile-save-project-buffers)
  (switch-to-svn-buffer (projectile-project-root))
  (svn-refresh t))

(defun svn-stash-open-file ()
  "Opens the selected file"
  (interactive)
  (find-file (get-text-property (line-beginning-position) 'file-path))
  (setq buffer-read-only t)
  (diff-mode))

(defun svn-stash-apply ()
  "Applies the selected patch"
  (interactive)
  (let ((patch-file (get-text-property (line-beginning-position) 'file-path)))
    (message (format "Applying %s..." patch-file))
    (svn-run-with-output "patch" (list patch-file))
    (masvn-status)))

(defun svn-stash-list ()
  "List all the .patch files"
  (interactive)
  (let ((buf (get-buffer-create "*svn stash list*")))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert "Svn stashes\n---\n")
      (insert (mapconcat (lambda (f)
                           (propertize f 'file-path f))
                         (file-expand-wildcards "*.patch" t) "\n"))
      (insert "\n---")
      (setq buffer-read-only t)
      (goto-char (point-min))
      (svn-stash-mode)
      (pop-to-buffer buf))))

(defun buffer-whole-string (buffer)
  (with-current-buffer buffer
    (save-restriction
      (widen)
      (buffer-substring-no-properties buffer (point-min) (point-max)))))

(defun svn-stash-save (patch-name)
  (interactive "sEnter patch name: ")
  (let ((patch-file (format "%s.patch" patch-name))
        (buf (get-buffer-create "*svn patch*")))
    (message (format "Creating %s..." patch-file))
    (with-current-buffer (svn-run-hidden 'diff nil)
      (append-to-file (point-min) (point-max) patch-file)
      (svn-run-hidden 'revert (list "." "--depth=infinity"))
      (masvn-status)
      (svn-stash-list))))

(defvar svn-stash-mode-map nil "Keymap for svn-stash-mode")
(unless svn-stash-mode-map
  (setq svn-stash-mode-map (make-sparse-keymap))
  (define-key svn-stash-mode-map "z" 'svn-stash-save)
  (define-key svn-stash-mode-map "a" 'svn-stash-apply)
  (define-key svn-stash-mode-map [mouse-2] 'svn-stash-open-file)
  (define-key svn-stash-mode-map "\r" 'svn-stash-open-file)
  (define-key svn-stash-mode-map "g" 'svn-stash-list)
  (define-key svn-stash-mode-map "q" 'bury-buffer))

(defun svn-stash-mode ()
  "Major mode for viewing svn stashes"
  (interactive)
  (setq major-mode 'svn-stash-mode mode-name "Svn stash")
  (use-local-map svn-stash-mode-map))

(define-key svn-status-mode-map "z" 'svn-stash-list)
(global-set-key (kbd "C-c C-s") 'masvn-status)
