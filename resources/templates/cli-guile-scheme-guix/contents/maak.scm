ΔΔ license-header-scm ΔΔ

(define-module (maak)
  #:use-module (maak maak)
  #:declarative? #t)

;; ====== Maak constants ======

;; The path to the directory where the main project files will be deployed.
(define deploy-dir
  "/srv/http/jointhefreeworld.org")

;; The URL for the CSS stylesheet used to style API documentation.
(define api-docs-css-url
  "https://jointhefreeworld.org/static/css/jointhefreeworld.css")

(define project-name
  'ΔΔ project-name ΔΔ)

(define hot-reload-file-types
  '(scm))

;; ====== Maak tasks ======

(define (help)
  "Display program help screen."
  (time-machine-program-shell (list "ΔΔ project-name ΔΔ" "--help")))

(define (default)
  "Default task to run, call program's help."
  (list-tasks))

;; The task named `run' below is the name maak exposes on the command line, so
;; it shadows the builtin of the same name inside this file; the shell helper is
;; therefore reached through the module it comes from.
(define (fmt)
  "Format Scheme source code files according to the Guix style guide."
  ((@ (maak maak) run)
   (list "find" "." "-maxdepth" "8" "-name" "*.scm" "-type" "f"
         "-exec" "guix" "style" "-f" "{}" ";")
   #:verbose? #t))

(define (repl)
  "Development REPL."
  (manifest-shell (list "guile" "-L" "./src"
                        "-c" "'((@ (ares server) run-nrepl-server))'")))

;; A manifest shell joins the parts it is handed into one shell line, so each
;; argument is a part of its own and each command is a call of its own: a `&&'
;; would be one word inside a part, and a failure would be reported by the line
;; rather than by the step that failed.
(define (docs)
  "Generate technical API documentation for the project."
  (delete-file-recursively "doc")
  (time-machine-manifest-shell (list "documenta" "api"
                                     (~ "./src/~a" project-name)))
  (time-machine-manifest-shell (list "texi2any" "-v" "--html"
                                     (~ "--css-ref=~a" api-docs-css-url)
                                     "./doc/api/index.texi"))
  (mv "./index" "./doc/api-dist"))

(define (package-docker)
  "Build the project's container image."
  ;; `guix-pack' would run the ambient Guix; the generated project builds its
  ;; image at the revision channels.scm pins, inside the manifest shell.
  (time-machine-manifest-shell
   (list "guix" "pack" "--file=./guix.scm" "--format=docker"
         "--image-tag=ΔΔ project-name ΔΔ" "-S" "/bin=bin"
         "bash" "coreutils" "util-linux-with-udev" "guile")
   #:verbose? #t))

(define (push-docker-latest)
  "Push the latest locally generated Docker image to Dockerhub."
  (container (list "push"
                   (~ "localhost/~a:latest" project-name)
                   (~ "docker.io/jjba23/~a:latest" project-name))
             #:verbose? #t))

(define (push-docker-tag)
  "Push the locally generated Docker image to Dockerhub."
  (git-fetch "--all")
  ;; `git describe' answers the empty string under `--dry-run', since nothing is
  ;; run: the dry run then prints the tag it cannot know yet rather than a
  ;; command with a hole in it.
  (let* ((latest-tag (git-describe-tag))
         (tag (if (string=? latest-tag "") "<latest-tag>" latest-tag)))
    (container (list "push"
                     (~ "localhost/~a:latest" project-name)
                     (~ "docker.io/jjba23/~a:~a" project-name tag))
               #:verbose? #t)))

(define (dev-run)
  (time-machine-manifest-shell (list "guile" "-L" "./src"
                                     "-c" "'((@(ΔΔ project-name ΔΔ main) main))'"
                                     "--resources" "./resources")
                               #:verbose? #t))

(define (run)
  (time-machine-program-shell (list "ΔΔ project-name ΔΔ")))

(define (hot-reload)
  "Hot-reloading developer's setup."
  (time-machine-manifest-shell (list "watchexec"
                                     "--clear"
                                     "--exts"
                                     (string-join (map symbol->string
                                                       hot-reload-file-types)
                                                  ",")
                                     "--on-busy-update=restart"
                                     "--shell" "bash"
                                     "--watch" "."
                                     "--"
                                     "maak" "dev-run")))

(define (hr)
  "Alias to hot-reloading."
  (hot-reload))

(define (dev)
  "Developer's setup."
  (hot-reload))
