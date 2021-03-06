(defconst intero-packages
  '(company
    (company-ghc :excluded t)
    (company-ghci :excluded t)
    flycheck
    (flycheck-haskell :excluded t)
    (ghc :excluded t)
    haskell-mode
    intero))

(defun intero/post-init-company ()
  (spacemacs|add-company-hook intero-repl-mode))

(defun intero/pre-init-haskell-mode ()
  (spacemacs|use-package-add-hook haskell-mode
    :post-init
    (progn
      (setq
       haskell-process-auto-import-loaded-modules nil
       haskell-process-suggest-remove-import-lines nil
       haskell-tags-on-save nil))
    :post-config
    (progn
      (remove-hook 'haskell-mode-hook 'interactive-haskell-mode))))

(defun intero/init-intero ()
  (use-package intero
    :defer t
    :init
    (progn
      (add-to-list 'company-backends-haskell-mode
                   '(company-intero company-dabbrev-code company-yasnippet))
      (add-hook 'haskell-mode-hook
                (lambda ()
                  (let ((checkers '(haskell-ghc haskell-stack-ghc)))
                    (if (boundp 'flycheck-disabled-checkers)
                        (dolist (checker checkers)
                          (add-to-list 'flycheck-disabled-checkers checker))
                      (setq flycheck-disabled-checkers checkers)))
                  (intero-mode))))
    :config
    (progn
      (spacemacs|diminish intero-mode " λ" " \\")

      (flycheck-add-next-checker 'intero
                                 '(warning . haskell-hlint))

      (defun intero/insert-type ()
        (interactive)
        (intero-type-at :insert))

      (defun intero/display-repl ()
        (interactive)
        (let ((buffer (intero-repl-buffer)))
          (unless (get-buffer-window buffer 'visible)
            (display-buffer (intero-repl-buffer)))))

      (defun intero/pop-to-repl ()
        (interactive)
        (pop-to-buffer (intero-repl-buffer)))

      (defun intero/load-repl ()
        "Load the current file in the REPL, display the REPL, but
preserve buffer focus."
        (interactive)
        (let ((buffer (current-buffer)))
          (intero-repl-load)
          (pop-to-buffer buffer)))

      (dolist (mode haskell-modes)
        (spacemacs/set-leader-keys-for-major-mode mode
          "gg"  'intero-goto-definition

          "hi"  'intero-info
          "ht"  'intero-type-at
          "hT"  'intero/insert-type

          "sb"  'intero/load-repl
          "sr"  'intero-repl-load))

      (dolist (mode (cons 'haskell-cabal-mode haskell-modes))
        (spacemacs/set-leader-keys-for-major-mode mode
          "sc"  nil
          "ss"  'intero/display-repl
          "sS"  'intero/pop-to-repl))

      (dolist (mode (append haskell-modes '(haskell-cabal-mode intero-repl-mode)))
        (spacemacs/declare-prefix-for-mode mode "mi" "haskell/intero")
        (spacemacs/set-leader-keys-for-major-mode mode
          "ic"  'intero-cd
          "id"  'intero-devel-reload
          "ik"  'intero-destroy
          "il"  'intero-list-buffers
          "ir"  'intero-restart
          "it"  'intero-targets))

      (evil-define-key '(insert normal) intero-mode-map
        (kbd "M-.") 'intero-goto-definition))))
