(require 'transient)
(require 'json)

;;; Use a better mechanism for this like defcustom to support helm and
;;; ido
(when (featurep 'ivy)
  (require 'ivy))


;;; Legacy Nix
(defun nix-env-install (package)
  "Install a package through `nix-env --install <package>'"
  (interactive "sPackage: ")
  (async-shell-command (format "nix-env --install %s" package)))

;;; Nix
(defcustom nix-profile-command
  "nix profile --experimental-features 'nix-command flakes ca-references'"
  "The `nix profile' command which will use the experimental
ca-references feature until flakes become stable.")

(defun nix-profile-info ()
  "List installed packages"
  (interactive)
  (async-shell-command
   (format "%s info" nix-profile-command)))

(defun nix-profile-install ()
  "List installed packages (Slow on the first run)"
  (interactive)
  (let* ((all-packages (shell-command-to-string "nix search nixpkgs --json"))
	 (packages-json (json-parse-string all-packages))
	 (package (ivy-read "Package: " packages-json))
	 (package (apply 'concat (cddr (split-string package "\\."))))
	 )
    (async-shell-command
     (format "%s install nixpkgs#%s" nix-profile-command package)
     "Nix")))

(defun nix-profile-remove ()
  "Remove packages from a profile"
  (interactive)
  (let* ((package 
	 (ivy-read "Package: "
		   (split-string 
		    (shell-command-to-string "nix profile info")
		    "\n")))
	 (package-number (car (split-string package))))
    (async-shell-command (format "nix --experimental-features 'nix-command ca-references' profile remove %s" package-number))))


(defun nix-profile-upgrade ()
  "Upgrade packages using their most recent flake"
  (interactive)
  (async-shell-command "nix profile upgrade \".*\""))

;; (defun nix-profile-upgrade-all ()
;;   "Upgrade all packages"
;;   (nix-profile-upgrade))

(transient-define-prefix nix-legacy ()
  "Legacy Nix commands"
  ["nix-env"
   ("I" "--install" nix-env-install)])

(transient-define-prefix nix ()
  "Nix flake interface"
  :man-page "nix"
  ["profile"
   ("i" "info" nix-profile-info)
   ("I" "install" nix-profile-install)
   ("r" "remove" nix-profile-remove)
   ("U" "upgrade \".*\"" nix-profile-upgrade)])


(provide 'nix)
