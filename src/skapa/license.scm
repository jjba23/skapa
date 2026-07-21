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

(define-module (skapa license)
  #:declarative? #t
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 textual-ports)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 ftw)
  #:export (list-available-licenses load-license-full-text load-license-header
                                    load-license-context))

(define (licenses-directory resources-dir)
  (format #f "~a/licenses" resources-dir))

(define (read-file-if-exists path)
  "Safely returns the string content of path if it exists, otherwise #f."
  (if (file-exists? path)
      (call-with-input-file path
        get-string-all) #f))

(define (list-available-licenses resources-dir)
  "Scans resources/licenses/ and returns a list of valid license directory names."
  (let* ((base-dir (licenses-directory resources-dir))
         (entries (and (file-exists? base-dir)
                       (scandir base-dir
                                (lambda (f)
                                  (and (not (member f
                                                    '("." "..")))
                                       (eq? 'directory
                                            (stat:type (stat (format #f
                                                                     "~a/~a"
                                                                     base-dir
                                                                     f))))))))))
    (or entries
        '())))

(define (load-license-full-text lic-id resources-dir)
  "Retrieves the complete license text (COPYING or LICENSE file)."
  (let* ((base (format #f "~a/licenses/~a" resources-dir lic-id))
         (copying-path (format #f "~a/COPYING" base))
         (license-path (format #f "~a/LICENSE" base)))
    (or (read-file-if-exists copying-path)
        (read-file-if-exists license-path) "")))

(define (load-license-header lic-id ext resources-dir)
  "Loads the language-specific header comment block (e.g. header.scm or header.txt)."
  (let* ((base (format #f "~a/licenses/~a" resources-dir lic-id))
         (ext-path (format #f "~a/header.~a" base ext))
         (gen-path (format #f "~a/header.txt" base)))
    (or (read-file-if-exists ext-path)
        (read-file-if-exists gen-path) "")))

(define (load-license-context lic-id resources-dir)
  "Generates an alist with both full license text and comment headers for the template engine context."
  (let ((full-text (load-license-full-text lic-id resources-dir))
        (header-scm (load-license-header lic-id "scm" resources-dir)))
    `(("license" unquote lic-id)
      ("license-full" unquote full-text)
      ("license-header-scm" unquote header-scm))))
