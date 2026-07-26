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

;;; Memory System Cache Helpers

(define (default-memory-path)
  "Returns default path for persistent prompt memory (~/.config/skapa/memory.scm)."
  (let ((config-dir (or (getenv "XDG_CONFIG_HOME")
                        (and (getenv "HOME")
                             (string-append (getenv "HOME") "/.config")))))
    (if config-dir
        (string-append config-dir "/skapa/memory.scm") "./.skapa-memory.scm")))

(define (ensure-dir-exists path)
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

;;; Memory & Default Transparency Formatting

(define (format-default-hint spec-default memory-val)
  "Formats transparent hint string showing both remembered memory and template default."
  (let ((has-mem? (and memory-val
                       (not (string-null? (format #f "~a" memory-val)))))
        (has-spec? (and spec-default
                        (not (string-null? (format #f "~a" spec-default))))))
    (cond
      ((and has-mem? has-spec?
            (not (equal? (format #f "~a" memory-val)
                         (format #f "~a" spec-default))))
       (format #f
               "~a[remembered: ~a]~a ~a(template default: ~a)~a"
               ansi-cyan
               memory-val
               ansi-reset
               ansi-gray
               spec-default
               ansi-reset))
      (has-mem? (format #f "~a[remembered: ~a]~a" ansi-cyan memory-val
                        ansi-reset))
      (has-spec? (format #f "~a[default: ~a]~a" ansi-gray spec-default
                         ansi-reset))
      (else ""))))

;;; Enhanced Prompts

(define (prompt-string question spec-default memory-val required?)
  "Prompts user for a string with transparent memory display."
  (let* ((effective-default (if (and memory-val
                                     (not (string-null? (format #f "~a"
                                                                memory-val))))
                                memory-val spec-default))
         (hint (format-default-hint spec-default memory-val))
         (req-str (if required?
                      (format #f " ~a(required)~a" ansi-red ansi-reset) ""))
         (msg (format #f
                      "~a?~a ~a~a~a~a~a: "
                      ansi-green
                      ansi-reset
                      ansi-bold
                      question
                      ansi-reset
                      req-str
                      (if memory-val (format #f "[mem: ~a]" memory-val) "")
                      (if (string-null? hint) ""
                          (string-append " " hint)))))
    (display msg)
    (force-output)
    (let ((input (string-trim-both (read-line))))
      (cond
        ((not (string-null? input))
         input)
        ((and effective-default
              (not (string-null? (format #f "~a" effective-default))))
         (format #f "~a" effective-default))
        (required? (format #t "  ~a[error] This field cannot be empty.~a
"
                           ansi-red ansi-reset)
                   (prompt-string question spec-default memory-val required?))
        (else "")))))

(define (prompt-boolean question spec-default memory-val)
  "Prompts user for a yes/no answer with memory transparency."
  (let* ((effective-default (cond
                              ((boolean? memory-val)
                               memory-val)
                              ((boolean? spec-default)
                               spec-default)
                              (else #t)))
         (hint (format-default-hint (if (boolean? spec-default)
                                        (if spec-default "yes" "no") #f)
                                    (if (boolean? memory-val)
                                        (if memory-val "yes" "no") #f)))
         (default-toggle (if effective-default "Y/n" "y/N"))
         (msg (format #f
                      "~a?~a ~a~a ~a[~a]~a~a~a: "
                      ansi-green
                      ansi-reset
                      ansi-bold
                      question
                      ansi-reset
                      ansi-gray
                      default-toggle
                      (if memory-val (format #f "[mem: ~a]" memory-val) "")
                      ansi-reset
                      (if (string-null? hint) ""
                          (string-append " " hint)))))
    (display msg)
    (force-output)
    (let ((input (string-downcase (string-trim-both (read-line)))))
      (cond
        ((string-null? input)
         effective-default)
        ((member input
                 '("y" "yes"))
         #t)
        ((member input
                 '("n" "no"))
         #f)
        (else (format #t "  ~a[error] Please enter 'y' or 'n'.~a\n" ansi-red
                      ansi-reset)
              (prompt-boolean question spec-default memory-val))))))

(define (prompt-choice question choices spec-default memory-val)
  "Displays an indexed list of choices with memory indicators."
  (let* ((effective-default (or memory-val spec-default))
         (default-str (and effective-default
                           (format #f "~a" effective-default))))

    ;; 1. Print question header
    (format #t
            "~a?~a ~a~a\n"
            ansi-green
            ansi-reset
            ansi-bold
            question
            ansi-reset)

    ;; 2. Print indexed options with visual indicators
    (let loop
      ((i 1)
       (lst choices))
      (unless (null? lst)
        (let* ((opt (car lst))
               (is-mem? (and memory-val
                             (string-ci=? opt
                                          (format #f "~a" memory-val))))
               (is-spec? (and spec-default
                              (string-ci=? opt
                                           (format #f "~a" spec-default))))
               (badge (cond
                        (is-mem? (format #f " ~a[remembered]~a" ansi-cyan
                                         ansi-reset))
                        (is-spec? (format #f " ~a[template default]~a"
                                          ansi-gray ansi-reset))
                        (else ""))))
          (format #t
                  "  ~a~a) ~a~a~a\n"
                  (if (and default-str
                           (string-ci=? opt default-str)) ansi-bold ansi-gray)
                  i
                  opt
                  badge
                  ansi-reset))
        (loop (+ i 1)
              (cdr lst))))

    ;; 3. Prompt line
    (let* ((hint (format-default-hint spec-default memory-val))
           (prompt-msg (format #f "  Select [1-~a]~a: "
                               (length choices)
                               (if (string-null? hint) ""
                                   (string-append " " hint)))))
      (display prompt-msg)
      (force-output)
      (let ((input (string-trim-both (read-line))))
        (cond
          ;; Enter pressed -> use effective default or first choice
          ((string-null? input)
           (or default-str
               (car choices)))

          ;; Number typed (e.g. 1, 2, 3)
          ((and (string->number input)
                (integer? (string->number input))
                (>= (string->number input) 1)
                (<= (string->number input)
                    (length choices)))
           (list-ref choices
                     (- (string->number input) 1)))

          ;; Exact text typed (e.g. "mit")
          ((member input choices string-ci=?)
           (string-downcase input))

          (else (format #t
                 "  ~a[error] Invalid choice. Select 1-~a or type the option name.~a
"
                 ansi-red
                 (length choices) ansi-reset)
                (prompt-choice question choices spec-default memory-val)))))))

(define (normalize-symbol val)
  "Converts strings, symbols, or quoted lists into a plain symbol."
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
  "Evaluates a single prompt pair, forwarding both template defaults and remembered memory."
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
         (memory-val (or (assq-ref memory-alist key)
                         (assoc-ref memory-alist
                                    (symbol->string key))))
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
                 (prompt-string prompt-text spec-default memory-val required?))
                ((boolean)
                 (prompt-boolean prompt-text spec-default memory-val))
                ((choice)
                 (prompt-choice prompt-text choices spec-default memory-val))
                (else (or memory-val spec-default)))))))

(define* (run-valg-prompts valg cli-options
                           #:key (memory-path (default-memory-path)))
  "Iterates over prompts in the valg, transparently handling prompt memory across runs."
  (let* ((prompts (or (assq-ref valg
                                'prompts)
                      '()))
         (existing-memory (load-memory memory-path))
         (current-context (map (lambda (p)
                                 (log-debug s "PROMPT: ~a" p)
                                 (eval-prompt p cli-options existing-memory))
                               prompts))
         (updated-memory (fold (lambda (pair acc)
                                 (cons pair
                                       (alist-delete (car pair) acc)))
                               existing-memory current-context)))
    (save-memory memory-path updated-memory) current-context))
