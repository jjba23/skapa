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
  #:use-module (srfi srfi-13)
  #:use-module (skapa engine)
  #:export (list-available-licenses load-license-full-text load-license-header
                                    load-all-license-headers copy-license-file
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
  "Loads a specific language header comment block (e.g. header.scm or header.txt)."
  (let* ((base (format #f "~a/licenses/~a" resources-dir lic-id))
         (ext-path (format #f "~a/header.~a" base ext))
         (gen-path (format #f "~a/header.txt" base)))
    (or (read-file-if-exists ext-path)
        (read-file-if-exists gen-path) "")))

(define (load-all-license-headers lic-id resources-dir)
  "Scans resources/licenses/<lic-id>/ for files matching 'header.<ext>'
and returns an alist mapping 'license-header-<ext>' to their string contents."
  (let* ((base (format #f "~a/licenses/~a" resources-dir lic-id))
         (entries (and (file-exists? base)
                       (scandir base
                                (lambda (f)
                                  (and (string-prefix? "header." f)
                                       (not (string=? f "header."))
                                       (eq? 'regular
                                            (stat:type (stat (format #f
                                                                     "~a/~a"
                                                                     base f))))))))))
    (if entries
        (map (lambda (f)
               (let* ((ext (substring f
                                      (string-length "header.")))
                      (path (format #f "~a/~a" base f))
                      (content (or (read-file-if-exists path) "")))
                 (cons (format #f "license-header-~a" ext) content))) entries)
        '())))

(define (load-license-context lic-id resources-dir)
  "Generates an alist with full license text and all dynamically discovered headers."
  (let ((full-text (load-license-full-text lic-id resources-dir))
        (headers (load-all-license-headers lic-id resources-dir)))
    (append `(("license" unquote lic-id)
              ("license-full" unquote full-text)) headers)))

(define (copy-license-file lic-id resources-dir dest-dir context-alist)
  "Copies and renders the full license text (COPYING or LICENSE) to dest-dir/COPYING."
  (let* ((full-text (load-license-full-text lic-id resources-dir))
         (rendered (render-template-string full-text context-alist))
         (dest-path (format #f "~a/COPYING" dest-dir)))
    (unless (string-null? rendered)
      (call-with-output-file dest-path
        (lambda (port)
          (display rendered port))))))
