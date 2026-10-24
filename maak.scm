;; skapa

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;; skapa is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; skapa is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with skapa.  If not, see <https://www.gnu.org/licenses/>.

(define-module (maak)
  #:declarative? #t
  #:use-module (maak maak)
  ;; The container helpers are imported under a prefix because the
  ;; tasks below are named the way maak exposes them on the command
  ;; line -- `maak container-build' -- and a task may not shadow the
  ;; helper it calls.
  #:use-module ((maak container) #:prefix ct:))

;; ====== Skapa file constants ======

;; The URL for the CSS stylesheet used to style API documentation.
(define api-docs-css-url
  "https://jointhefreeworld.org/static/css/jointhefreeworld.css")

;; The path to the directory where the main project files will be deployed.
(define deploy-dir
  "/srv/http/jointhefreeworld.org")

(define project-name
  'skapa)

(define hot-reload-file-types
  '(scm))

;; ====== Skapa file tasks ======

(define (help)
  "Display program help screen."
  (program-shell (list "skapa" "--help")))

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
  (time-machine-manifest-shell (list "guile" "-L" "./src"
                                     "-c" "'((@ (ares server) run-nrepl-server))'")))

;; A manifest shell joins the parts it is handed into one shell line, so each
;; argument is a part of its own and each command is a call of its own: a `&&'
;; would be one word inside a part, and a failure would be reported by the line
;; rather than by the step that failed.
(define (docs)
  "Generate technical API documentation for Skapa."
  (delete-file-recursively "doc")
  (time-machine-manifest-shell (list "documenta" "api" "./src/skapa"))
  (time-machine-manifest-shell (list "texi2any" "-v" "--html"
                                     (~ "--css-ref=~a" api-docs-css-url)
                                     "-o" "index_html"
                                     "./doc/api/index.texi"))
  (mv "./index_html" "./doc/api-dist"))

(define (deploy)
  "Generate documentation for the project and publish to web directory."
  (docs)
  (remkdir-p (~ "~a/api-docs/skapa" deploy-dir))
  (mv "doc/api-dist/*"
      (~ "~a/api-docs/skapa" deploy-dir)
      #:expand? #t)
  (delete-file-recursively "doc"))

(define (package-docker)
  "Pack Skapa as a Docker image with `guix pack'."
  (guix-pack '()
             #:file "./guix.scm"
             #:format "docker"
             #:image-tag (~ "~a" project-name)
             #:symlinks '("/bin=bin")
             #:extra-packages '("bash" "coreutils" "util-linux-with-udev" "guile")
             #:verbose? #t))

(define (push-docker-latest)
  "Push the latest locally generated Docker image to Dockerhub."
  (ct:container (list "push"
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
    (ct:container (list "push"
                        (~ "localhost/~a:latest" project-name)
                        (~ "docker.io/jjba23/~a:~a" project-name tag))
                  #:verbose? #t)))

(define (dev-run)
  (time-machine-manifest-shell (list "guile" "-L" "./src"
                                     "-c" "'((@(skapa main) main))'"
                                     "--resources" "./resources")
                               #:verbose? #t))

(define (run)
  "Run skapa."
  (time-machine-program-shell (list "skapa")
                              #:verbose? #t))

;; ====== Container tasks ======

(define (container-build)
  "Build the container image for skapa."
  (ct:container-build "." #:tag "skapa:latest" #:verbose? #t))

(define (container-run)
  "Run the container image for skapa."
  (ct:container-run "skapa" #:interactive? #t #:tty? #t #:verbose? #t))
