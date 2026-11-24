;; skapa
;;
;; SPDX-License-Identifier: MIT
;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

(use-modules (guix gexp)
             (guix packages)
             (guix git-download)
             ((guix licenses)
              #:prefix license:)
             (guix build-system guile)
             (gnu packages)
             (gnu packages bash)
             (gnu packages base)
             (gnu packages linux)
             (gnu packages guile)
             (gnu packages guile-xyz)
             ;; The release the channel in channels.scm pins, imported with a
             ;; prefix so it cannot be confused with Guix's older copy.
             ((jointhefreeworld packages guile)
              #:prefix jtf:)
             (ice-9 match))

(define %source-dir
  (dirname (current-filename)))

(define-public skapa
  (package
    (name "skapa")
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
                              (string-append share "/resources"))
                (mkdir-p (string-append share "/resources/templates"))
                (copy-recursively "resources/templates"
                                  (string-append share "/resources/templates"))
                (mkdir-p (string-append share "/resources/licenses"))
                (copy-recursively "resources/licenses"
                                  (string-append share "/resources/licenses"))
                (install-file "scripts/skapa" bin)
                (chmod (string-append bin "/skapa") #o755))))
          (add-after 'install-program-files 'wrap-program
            (lambda _
              ;; The channel's scriba is imported with a prefix, and a
              ;; prefix-qualified name cannot be written as a `#$' unquote, so
              ;; the long form is used here.
              (let ((deps (list (ungexp jtf:guile-scriba)
                                #$guile-json-4
                                #$output)))
                (wrap-program (string-append #$output "/bin/skapa")
                  `("GUILE_LOAD_PATH" ":" prefix
                    ,(map (lambda (dir)
                            (string-append dir "/share/guile/site/3.0")) deps))
                  `("GUILE_LOAD_COMPILED_PATH" ":" prefix
                    ,(map (lambda (dir)
                            (string-append dir "/lib/guile/3.0/site-ccache"))
                          deps))))))

          (add-after 'unpack 'fix-paths
            (lambda* (#:key inputs #:allow-other-keys)
              (for-each (match-lambda
                          ((pattern program format-string)
                           (substitute* "scripts/skapa"
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
    (inputs (list guile-3.0
                  bash-minimal
                  coreutils-minimal
                  util-linux
                  jtf:guile-scriba
                  guile-json-4))
    (home-page "https://github.com/jjba23/skapa")
    (synopsis "Interactive CLI wizard project scaffolder")
    (description
     "A lightweight command-line project scaffolder featuring a template system.")
    (license license:expat)))

skapa
