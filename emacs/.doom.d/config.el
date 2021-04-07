;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;;(setq doom-theme 'doom-one)
(setq doom-theme 'doom-molokai)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Company auto-completion is completely annoying
;;
;; (with-eval-after-load 'company
;;   (define-key company-active-map (kbd "<return>") nil)
;;   (define-key company-active-map (kbd "TAB" nil))
;;   (define-key company-active-map (kbd "RET") nil)
;;   (define-key company-active-map (kbd "C-SPC") #'company-complete-selection)
;;   )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bind C-w + Arrow like in vim
;;
;; This doesn't work for some reason
;; (with-eval-after-load "evil"
;;   '(progn
;;     (define-key evil-window-map (kbd "<left>") evil-window-left)
;;     (define-key evil-window-map (kbd "<right>") evil-window-right)
;;     (define-key evil-window-map (kbd "<up>") evil-window-up)
;;     (define-key evil-window-map (kbd "<down>") evil-window-down)
;;      )
;;   )
(map!
 :after evil
 :map evil-window-map
 [left] 'evil-window-left
 [right] 'evil-window-right
 [up] 'evil-window-up
 [down] 'evil-window-down
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Notes
;;
;; evil-want-Y-yank-to-eol
;; Whether Y yanks to the end of the line.
;; The default behavior is to yank the whole line, like Vim.
;; Sky: Well, apparently this is a lie.
;;
;; This doesn work AT ALL
;;(setq evil-want-Y-yank-to-eol nil)
;; instead had to use M-x customize-variable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Minor settings

(setq
 ;; Auto search for projects in these directories
 projectile-project-search-path '("~/Dev/")
 )
