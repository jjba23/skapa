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
  #:use-module (scriba scriba)
  #:use-module (scriba auto)
  #:export (main))

(define s (scriba-auto-logger))
(define* (main #:key (args (command-line)))
  (let* ((_ (begin
              (newline)
              (write args)
              (newline)))
         (option-spec '((resources (single-char #\r)
                                   (value #t))))

         (options (getopt-long args option-spec))
         (resources (option-ref options
                                'resources #f)))
    (log-info s "Skapa: Project Templater")))
