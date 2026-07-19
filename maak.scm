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
  #:use-module (ice-9 string-fun)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 popen)
  #:use-module (maak maak))

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

;; ====== Skapa abstractions ======

(define (syscall-with-output cmd)
  (let* ((process (open-input-pipe cmd))
         (process-output (get-string-all process)))
    (close-pipe process) process-output))

;; ====== Skapa file tasks ======

(define (help)
  "Display program help screen."
  (program-shell '("skapa --help")))

(define (default)
  "Default task to run, call program's help."
  (list-tasks))

(define (fmt)
  "Format Scheme source code files according to the Guix style guide."
  ($ '("find . -maxdepth 8 -name '*.scm'" "-type f -exec guix style -f {} \\;")
     #:verbose? #t))

(define (repl)
  "Development REPL."
  (manifest-shell '("guile -L ./src"
                    "-c '((@ (ares server) run-nrepl-server))'")))

(define (docs)
  "Generate technical API documentation for Skapa."
  (delete-file-recursively "doc")
  (manifest-shell (list "documenta api ./src/skapa && "
                        (~ "texi2any -v --html --css-ref=~a -o index_html" api-docs-css-url)
                        "./doc/api/index.texi"))
  (mv "./index_html" "./doc/api-dist"))

(define (deploy)
  "Generate documentation for the project and publish to web directory."
  (docs)
  (remkdir-p (~ "~a/api-docs/skapa" deploy-dir))
  (mv "doc/api-dist/*"
      (~ "~a/api-docs/skapa" deploy-dir))
  (delete-file-recursively "doc"))

(define (package-docker)
  "Create a Docker image for Skapa."
  ($ '("guix pack --file=./guix.scm" "--format=docker" "--image-tag=skapa"
       "-S /bin=bin" "bash coreutils util-linux-with-udev guile")))

(define (push-docker-latest)
  "Push the latest locally generated Docker image to Dockerhub."
  ($ (list (~ "podman push localhost/~a:latest" project-name)
           (~ "docker.io/jjba23/~a:latest" project-name))
     #:verbose? #t))

(define (push-docker-tag)
  "Push the locally generated Docker image to Dockerhub."
  ($ '("git fetch --all"))
  (let* ((latest-tag (syscall-with-output "git describe --tags --abbrev=0")))
    ($ (list (~ "podman push localhost/~a:latest" project-name)
             (~ "docker.io/jjba23/~a:~a" project-name latest-tag))
       #:verbose? #t)))

(define (dev-run)
  (time-machine-manifest-shell (list
                                "guile -L ./src -c '((@(skapa main) main))'"
                                "--resources ./resources")
                               #:verbose? #t))

(define (run)
  "Run skapa."
  (time-machine-program-shell (list "skapa --help")
                              #:verbose? #t))
