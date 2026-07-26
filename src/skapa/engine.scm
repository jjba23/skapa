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

(define-module (skapa engine)
  #:declarative? #t
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 ftw)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (render-template-string render-template-directory
                                   list-available-templates))

(define (mkdir-p path)
  "Recursively creates PATH and all required parent directories."
  (unless (or (string-null? path)
              (file-exists? path))
    (let ((parent (dirname path)))
      (when (and (not (string=? parent path))
                 (not (string=? parent ".")))
        (mkdir-p parent))
      (catch 'system-error
             (lambda ()
               (mkdir path))
             (lambda (key . args)
               (unless (and (file-exists? path)
                            (eq? 'directory
                                 (stat:type (stat path))))
                 (apply throw key args)))))))

(define (make-context-module context-alist)
  "Creates a fresh evaluation environment populated with variables from context-alist."
  (let ((m (make-fresh-user-module)))
    (for-each (lambda (pair)
                (let ((key (car pair))
                      (val (cdr pair)))
                  (when (and key val)
                    (let ((sym (if (symbol? key) key
                                   (string->symbol key))))
                      (module-define! m sym val))))) context-alist) m))

(define (eval-rune-token token-str context-module)
  "Parses and evaluates an embedded Scheme expression string."
  (catch #t
         (lambda ()
           (let* ((expr (with-input-from-string token-str read))
                  (res (eval expr context-module)))
             (cond
               ((boolean? res)
                (if res "true" "false"))
               ((or (null? res)
                    (not res))
                "")
               (else (format #f "~a" res)))))
         (lambda (key . args)
           (format #f "[[Template Error (~a): ~a]]" key token-str))))

(define (render-template-string template-str context-alist)
  "Replaces all ΔΔ scheme-expression ΔΔ tags with evaluated results."
  (let ((eval-env (make-context-module context-alist)))
    (let loop
      ((offset 0)
       (acc ""))
      (let ((start (string-contains template-str "ΔΔ" offset)))
        (if (not start)
            (string-append acc
                           (substring template-str offset))
            (let ((end (string-contains template-str "ΔΔ"
                                        (+ start 2))))
              (if (not end)
                  (string-append acc
                                 (substring template-str offset))
                  (let* ((prefix (substring template-str offset start))
                         (expr-str (string-trim-both (substring template-str
                                                                (+ start 2)
                                                                end)))
                         (evaluated (eval-rune-token expr-str eval-env)))
                    (loop (+ end 2)
                          (string-append acc prefix evaluated))))))))))

(define (render-template-directory src-dir dest-dir context-alist)
  "Recursively renders and outputs directory structure and files from src-dir into dest-dir."
  (mkdir-p dest-dir)
  (let ((entries (scandir src-dir
                          (lambda (f)
                            (not (member f
                                         '("." ".." "valg.scm" ".DS_Store")))))))
    (for-each (lambda (entry)
                (let* ((rendered-entry (render-template-string entry
                                                               context-alist))
                       (src-path (format #f "~a/~a" src-dir entry))
                       (dest-path (format #f "~a/~a" dest-dir rendered-entry)))
                  (if (eq? 'directory
                           (stat:type (stat src-path)))
                      (render-template-directory src-path dest-path
                                                 context-alist)
                      (let* ((raw (call-with-input-file src-path
                                    get-string-all))
                             (rendered (render-template-string raw
                                                               context-alist)))
                        (call-with-output-file dest-path
                          (lambda (port)
                            (display rendered port)))))))
              (or entries
                  '()))))

(define (list-available-templates resources-dir)
  "Scans resources/templates and returns a list of template directory names."
  (let* ((templates-dir (format #f "~a/templates" resources-dir))
         (entries (and (file-exists? templates-dir)
                       (scandir templates-dir
                                (lambda (f)
                                  (and (not (member f
                                                    '("." "..")))
                                       (eq? 'directory
                                            (stat:type (stat (format #f
                                                              "~a/~a"
                                                              templates-dir f))))))))))
    (or entries
        '())))
