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
  #:export (load-valg run-valg-prompts
                      prompt-string
                      prompt-choice
                      prompt-boolean
                      eval-prompt
                      load-memory
                      save-memory
                      default-memory-path))

(define s
  (scriba-auto-logger))

;;; ANSI Escape Codes for Styled CLI Output
(define ansi-reset
  "\x1b[0m")
(define ansi-bold
  "\x1b[1m")
(define ansi-green
  "\x1b[32m")
(define ansi-cyan
  "\x1b[36m")
(define ansi-gray
  "\x1b[90m")
(define ansi-red
  "\x1b[31m")

;;; Memory / Cache System Functions

(define (default-memory-path)
  "Returns the default path for persistent prompt memory (~/.config/skapa/memory.scm)."
  (let ((config-dir (or (getenv "XDG_CONFIG_HOME")
                        (and (getenv "HOME")
                             (string-append (getenv "HOME") "/.config")))))
    (if config-dir
        (string-append config-dir "/skapa/memory.scm") "./.skapa-memory.scm")))

(define (ensure-dir-exists path)
  "Ensures directory path exists before writing files."
  (unless (or (string-null? path)
              (file-exists? path))
    (let ((parent (dirname path)))
      (when (and (not (string=? parent path))
                 (not (string=? parent ".")))
        (ensure-dir-exists parent))
      (catch 'system-error
             (lambda ()
               (mkdir path))
             (lambda _
               #f)))))

(define (load-memory memory-path)
  "Loads cached user answers from a memory file, returning an alist."
  (catch #t
         (lambda ()
           (if (file-exists? memory-path)
               (with-input-from-file memory-path
                 read)
               '()))
         (lambda (k . args)
           (log-warn s "Could not read memory from ~a: ~a" memory-path args)
           '())))

(define (save-memory memory-path alist)
  "Saves an alist of answers back to the persistent memory file."
  (catch #t
         (lambda ()
           (ensure-dir-exists (dirname memory-path))
           (with-output-to-file memory-path
             (lambda ()
               (display ";;; Skapa persistent prompt memory cache
")
               (write alist)
               (newline))))
         (lambda (k . args)
           (log-warn s "Could not save memory cache to ~a: ~a" memory-path
                     args))))

(define (load-valg valg-path)
  "Loads a template valg file if it exists, returning an alist."
  (if (file-exists? valg-path)
      (with-input-from-file valg-path
        read)
      '()))

;;; Prettier Prompt Engine

(define (prompt-string question default-val required?)
  "Prompts user for a string with ANSI styling."
  (let* ((has-default? (and default-val
                            (not (string-null? (format #f "~a" default-val)))))
         (default-str (if has-default?
                          (format #f " ~a[~a]~a" ansi-gray default-val
                                  ansi-reset) ""))
         (req-str (if required?
                      (format #f " ~a(required)~a" ansi-red ansi-reset) ""))
         (msg (format #f
                      "~a?~a ~a~a~a~a: "
                      ansi-green
                      ansi-reset
                      ansi-bold
                      question
                      ansi-reset
                      req-str
                      default-str)))
    (display msg)
    (force-output)
    (let ((input (string-trim-both (read-line))))
      (cond
        ((not (string-null? input))
         input)
        (has-default? (format #f "~a" default-val))
        (required? (format #t
                    "  ~a[error] This field cannot be empty. Please enter a value.~a
"
                    ansi-red ansi-reset)
                   (prompt-string question default-val required?))
        (else "")))))

(define (prompt-boolean question default-val)
  "Prompts user for a yes/no answer with ANSI styling."
  (let* ((default-hint (if default-val "Y/n" "y/N"))
         (msg (format #f
                      "~a?~a ~a~a ~a[~a]~a: "
                      ansi-green
                      ansi-reset
                      ansi-bold
                      question
                      ansi-reset
                      ansi-gray
                      default-hint
                      ansi-reset)))
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
        (else (format #t "  ~a[error] Please enter 'y' or 'n'.~a\n" ansi-red
                      ansi-reset)
              (prompt-boolean question default-val))))))

(define (prompt-choice question choices default-val)
  "Prompts user to select one option from a list with ANSI styling."
  (let* ((choices-str (string-join choices "/"))
         (msg (format #f
                      "~a?~a ~a~a ~a(~a)~a ~a[~a]~a: "
                      ansi-green
                      ansi-reset
                      ansi-bold
                      question
                      ansi-reset
                      ansi-cyan
                      choices-str
                      ansi-reset
                      ansi-gray
                      default-val
                      ansi-reset)))
    (display msg)
    (force-output)
    (let ((input (string-trim-both (read-line))))
      (cond
        ((string-null? input)
         default-val)
        ((member input choices string-ci=?)
         (string-downcase input))
        (else (format #t "  ~a[error] Invalid choice. Pick one of: ~a~a
"
                      ansi-red choices-str ansi-reset)
              (prompt-choice question choices default-val))))))

(define (normalize-symbol val)
  "Converts strings, symbols, or quoted lists like '(quote foo) into a plain symbol."
  (cond
    ((symbol? val)
     val)
    ((string? val)
     (string->symbol val))
    ((and (pair? val)
          (eq? (car val)
               'quote))
     (cadr val))
    (else (string->symbol (format #f "~a" val)))))

(define (eval-prompt prompt-spec cli-options memory-alist)
  "Evaluates a single prompt specification pair, prioritizing CLI flags, memory, then defaults."
  (let* ((raw-key (or (assq-ref prompt-spec
                                'key)
                      (assoc-ref prompt-spec "key")))
         (key (normalize-symbol raw-key))
         (prompt-text (or (assq-ref prompt-spec
                                    'prompt)
                          (assoc-ref prompt-spec "prompt")))
         (type (normalize-symbol (or (assq-ref prompt-spec
                                               'type)
                                     (assoc-ref prompt-spec "type"))))
         (spec-default (or (assq-ref prompt-spec
                                     'default)
                           (assoc-ref prompt-spec "default")))
         ;; Look up previous memory answer; fallback to template spec default
         (memory-val (or (assq-ref memory-alist key)
                         (assoc-ref memory-alist
                                    (symbol->string key))))
         (effective-default (if (and memory-val
                                     (not (equal? memory-val ""))) memory-val
                                spec-default))
         (required? (or (assq-ref prompt-spec
                                  'required?)
                        (assq-ref prompt-spec
                                  'required)
                        (assoc-ref prompt-spec "required?") #f))
         (choices (or (assq-ref prompt-spec
                                'choices)
                      (assoc-ref prompt-spec "choices")))
         (cli-val (and cli-options
                       (option-ref cli-options key #f))))
    (cons key
          (or cli-val
              (case type
                ((string)
                 (prompt-string prompt-text effective-default required?))
                ((boolean)
                 (prompt-boolean prompt-text effective-default))
                ((choice)
                 (prompt-choice prompt-text choices effective-default))
                (else effective-default))))))

(define* (run-valg-prompts valg cli-options
                           #:key (memory-path (default-memory-path)))
  "Iterates over prompts in the valg, reading/writing memory across scaffolding runs."
  (let* ((prompts (or (assq-ref valg
                                'prompts)
                      '()))
         (existing-memory (load-memory memory-path))
         ;; Collect answers for current session
         (current-context (map (lambda (p)
                                 (log-debug s "PROMPT: ~a" p)
                                 (eval-prompt p cli-options existing-memory))
                               prompts))
         ;; Merge new answers into memory
         (updated-memory (fold (lambda (pair acc)
                                 (cons pair
                                       (alist-delete (car pair) acc)))
                               existing-memory current-context)))
    ;; Write updated answers back to disk
    (save-memory memory-path updated-memory) current-context))
