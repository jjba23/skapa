;;; Skapa

;; Copyright © Josep Jesus Bigorra Algaba

;; skapa is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; skapa is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public License
;; along with skapa. If not, see <https://www.gnu.org/licenses/>.

(define-module (skapa main)
  #:declarative? #t
  #:use-module (ice-9 getopt-long)
  #:use-module (skapa valg)
  #:use-module (skapa license)
  #:use-module (skapa engine)
  #:export (main))

(define (run-wizard options)
  (let* ((resources (option-ref options
                                'resources "resources"))
         (template-name (option-ref options
                                    'template #f))
         (template-dir (format #f "~a/templates/~a" resources template-name))
         (valg-path (format #f "~a/valg.scm" template-dir))

         (valg (load-valg valg-path))
         (user-ctx (run-valg-prompts valg options))

         (project-name (or (assoc-ref user-ctx "project-name") #f))
         (available-licenses (list-available-licenses resources))
         (lic-id (prompt-choice "> Choose license" available-licenses "gpl3"))
         (lic-ctx (load-license-context lic-id resources))
         (final-ctx (append user-ctx lic-ctx
                            `(("year" . "2026"))))
         (dest-dir (format #f "dist/~a" project-name)))

    (format #t "
Forging project '~a' using template '~a'...
" project-name
            template-name)
    (render-template-directory template-dir dest-dir final-ctx)
    (format #t "[Success] Workspace created at: ~a\n" dest-dir)))

(define option-spec
  '((name (single-char #\n)
          (value #t))
    (creator (single-char #\c)
             (value #t))
    (type (single-char #\t)
          (value #t))
    (license (single-char #\l)
             (value #t))
    (owner (single-char #\o)
           (value #t))
    (template (single-char #\m)
              (value #t))
    (help (single-char #\h)
          (value #f))
    (resources (single-char #\r)
               (value #t))))

(define* (main #:key (args (command-line)))
  (run-wizard (getopt-long args option-spec)))
