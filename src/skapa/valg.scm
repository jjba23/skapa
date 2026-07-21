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

(define-module (skapa valg)
  #:declarative? #t
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (scriba scriba)
  #:use-module (scriba auto)
  #:use-module (ice-9 getopt-long)
  #:export (load-valg run-valg-prompts prompt-choice prompt-boolean
                      eval-prompt))

(define s
  (scriba-auto-logger))

(define (load-valg valg-path)
  "Loads a template valg file if it exists, returning an alist."
  (log-info s "Reading valg file if exists: ~a" valg-path)
  (if (file-exists? valg-path)
      (with-input-from-file valg-path
        read)
      '()))

(define (prompt-string question default-val required?)
  "Prompts user for a string. If required? is #t and no input or default exists, re-prompts."
  (let* ((has-default? (and default-val
                            (not (string-null? default-val))))
         (default-str (if has-default?
                          (format #f " [~a]" default-val) ""))
         (req-str (if required? " (required)" ""))
         (msg (format #f "~a~a~a: " question req-str default-str)))
    (display msg)
    (force-output)
    (let ((input (string-trim-both (read-line))))
      (cond
        ((not (string-null? input))
         input)
        (has-default? default-val)
        (required? (display "This field cannot be empty. Please enter a value.
")
                   (prompt-string question default-val required?))
        (else "")))))

(define (prompt-boolean question default-val)
  "Prompts user for a yes/no answer, defaulting to default-val (#t or #f)."
  (let* ((default-str (if default-val "Y/n" "y/N"))
         (msg (format #f "~a [~a]: " question default-str)))
    (display msg)
    (force-output)
    (let ((input (string-downcase (string-trim-both (read-line)))))
      (cond
        ((string-null? input)
         default-val)
        ((member input
                 '("y" "yes"))
         #t)
        ((member input
                 '("n" "no"))
         #f)
        (else (display "Please enter 'y' or 'n'.\n")
              (prompt-boolean question default-val))))))

(define (prompt-choice question choices default-val)
  "Prompts user to select one option from a list of valid choices."
  (let* ((choices-str (string-join choices "/"))
         (msg (format #f "~a [~a] (default ~a): " question choices-str
                      default-val)))
    (display msg)
    (force-output)
    (let ((input (string-trim-both (read-line))))
      (cond
        ((string-null? input)
         default-val)
        ((member input choices string-ci=?)
         (string-downcase input))
        (else (format #t "Invalid choice. Pick one of: ~a\n" choices-str)
              (prompt-choice question choices default-val))))))

(define (eval-prompt prompt-spec cli-options)
  "Evaluates a single prompt specification pair from the valg."
  (let* ((key (assoc-ref prompt-spec
                         'key))
         (prompt-text (assoc-ref prompt-spec
                                 'prompt))
         (type (assoc-ref prompt-spec
                          'type))
         (default (assoc-ref prompt-spec
                             'default))
         (required? (or (assoc-ref prompt-spec
                                   'required?)
                        (assoc-ref prompt-spec
                                   'required) #f))
         (choices (assoc-ref prompt-spec
                             'choices))
         (cli-val (and cli-options
                       (option-ref cli-options
                                   (string->symbol key) #f))))
    (cons key
          (or cli-val
              (case type
                ((string)
                 (prompt-string prompt-text default required?))
                ((boolean)
                 (prompt-boolean prompt-text default))
                ((choice)
                 (prompt-choice prompt-text choices default))
                (else default))))))

(define (run-valg-prompts valg cli-options)
  "Iterates over prompts in the valg and collects key-value context."
  (let ((prompts (or (assoc-ref valg
                                'prompts)
                     '())))
    (map (lambda (p)
           (eval-prompt p cli-options)) prompts)))
