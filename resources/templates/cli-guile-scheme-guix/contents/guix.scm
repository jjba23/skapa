<: license-header-scm :>

(use-modules (guix gexp)
             (guix packages)
             (guix git-download)
             ((guix licenses)
              #:prefix license:)
             (guix build-system guile)
             ((guix build utils)
              #:select (with-directory-excursion ))
             (gnu packages)
             (gnu packages base)
             (gnu packages bash)
             (gnu packages guile)
             (gnu packages guile-xyz)
             (gnu packages linux))

(define %source-dir
  (dirname (current-filename)))

(define-public <: project-name :>
  (package
    (name "<: project-name :>")
    (version "dev")
    (source
     (local-file %source-dir
                 #:recursive? #t
                 #:select? (git-predicate %source-dir)))
    (build-system guile-build-system)
    (arguments
     (list
      #:source-directory "src"
      #:modules '((guix build guile-build-system)
                  (guix build utils)
                  (ice-9 match))
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'build 'install-program-files
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (share (string-append #$output "/share")))
                (install-file "resources/help.txt"
                              (string-append share "/resources/"))
                (install-file "scripts/<: project-name :>" bin)
                (chmod (string-append bin "/<: project-name :>") #o755))))
          (add-after 'unpack 'fix-paths
            (lambda* (#:key inputs #:allow-other-keys)
              (for-each (match-lambda
                          ((pattern program format-string)
                           (substitute* "scripts/<: project-name :>"
                             ((pattern)
                              (format #f format-string
                                      (search-input-file inputs
                                                         (string-append "bin/"
                                                          program)))))))
                        '(("readlink -f " "readlink" "~s -f ")
                          ("realpath " "realpath" "~s ")
                          ("dirname " "dirname" "~s ")
                          ("getopt " "getopt" "~s ")
                          ("exec guile " "guile" "exec ~s "))))))))
    (inputs (list guile-3.0 bash-minimal coreutils util-linux))
    (synopsis
     "")
    (description
     "")
    (home-page "https://codeberg.org/jjba23/<: project-name :>")
    (license license:agpl3+)))

<: project-name :>
