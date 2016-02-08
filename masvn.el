(require 'projectile)
(require 'dsvn)

(defun masvn-status ()
  (interactive)
  (projectile-save-project-buffers)
  (switch-to-svn-buffer (projectile-project-root))
  (svn-refresh true))

(global-set-key (kbd "C-c C-s") 'masvn-status)
