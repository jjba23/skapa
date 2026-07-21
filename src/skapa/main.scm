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
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 format)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 string-fun)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:use-module (scriba scriba)
  #:use-module (scriba auto)
  #:export (main))

;; =========================================================================
;; File System & I/O Helpers
;; =========================================================================

(define s
  (scriba-auto-logger))

(define (prompt-user message default-val)
  "Displays an interactive prompt string to the user, flushes output,
and returns trimmed input (or default-val if empty)."
  (log-info s message)
  (force-output)
  (let ((input (string-trim-both (read-line))))
    (if (string-null? input) default-val input)))

(define (prompt-choice message valid-choices default-val error-msg)
  "Repeatedly prompts the user until input matches one of valid-choices."
  (let loop
    ()
    (let ((choice (prompt-user message default-val)))
      (if (member choice valid-choices string-ci=?)
          (string-downcase choice)
          (begin
            (log-warning s error-msg)
            (loop))))))

(define (get-option options key prompt-msg default-val)
  "Retrieves an option from the CLI options list or prompts the user if absent."
  (or (option-ref options key #f)
      (prompt-user prompt-msg default-val)))

(define (ensure-directory dir)
  "Safely creates a directory if it does not already exist."
  (catch #t
         (lambda ()
           (mkdir dir))
         (lambda _
           #f)))

(define (read-file-string path)
  "Reads an entire file into a string."
  (call-with-input-file path
    get-string-all))

(define (write-file-string path content)
  "Writes a string payload to a target file path."
  (call-with-output-file path
    (lambda (port)
      (display content port))))

;; =========================================================================
;; The Runic Templating Engine
;; =========================================================================

(define rune-prefix
  "<:")
(define rune-suffix
  ":>")

(define (template-replace template key value)
  "Replaces instances of rune-prefix + key + rune-suffix with value."
  (let ((rune-tag (string-append rune-prefix key rune-suffix)))
    (string-replace-substring template rune-tag value)))

(define (render-template template context)
  "Applies an association list of context pairs to a template string."
  (fold (lambda (pair acc)
          (let ((key (car pair))
                (val (cdr pair)))
            (if (string? val)
                (template-replace acc key val) acc))) template context))

;; =========================================================================
;; Crossroads Logic Manager
;; =========================================================================

(define (apply-crossroads-branch context key prompt default template-fmt)
  "Helper to prompt for missing metadata and append crossroads content to context."
  (let* ((existing-val (assoc-ref context key))
         (val (or existing-val
                  (prompt-user prompt default)))
         (content (format #f template-fmt val)))
    (alist-cons "crossroads-content" content
                (alist-cons key val context))))

(define (handle-crossroads type context-alist)
  "Evaluates branching choices and extends context with generated content."
  (cond
    ((string-ci=? type "o")
     (apply-crossroads-branch context-alist "license"
      "> Choose your shield (License) [MIT/GPL/Apache]: " "MIT"
      "## License
This project is open-source and distributed under the **~a** license.
"))

    ((string-ci=? type "p")
     (apply-crossroads-branch context-alist "owner"
      "> Enter the Copyright Owner (Longhouse Chief): " "The Clan"
      "## Copyright
All rights reserved. Proprietary property of **~a**.
"))

    (else (alist-cons "crossroads-content" "" context-alist))))

;; =========================================================================
;; Main Entry Point & Orchestration
;; =========================================================================

(define (run-wizard options)
  "Orchestrates CLI flag evaluation, prompts, rendering, and directory output."
  (log-info s "Gathering materials for the forge...\n")
  (let* ((resources (option-ref options
                                'resources #f))
         (name (get-option options
                           'name "> Enter project name: " "my-project"))
         (creator (get-option options
                              'creator "> Enter your name (The Creator): "
                              "Anonymous"))
         (license (option-ref options
                              'license #f))
         (owner (option-ref options
                            'owner #f))

         (type (or (option-ref options
                               'type #f)
                   (prompt-choice
                    "
--- THE CROSSROADS ---
> Is this project Open Source (o) or Proprietary (p)? "
                    '("o" "p") "o" "Invalid layout. Please select 'o' or 'p'.
")))

         (base-ctx `(("project-name" unquote name)
                     ("creator" unquote creator)
                     ("license" unquote license)
                     ("owner" unquote owner)))

         (final-ctx (handle-crossroads type base-ctx))
         (template-path (format #f "~a/templates/simple-readme/README.org"
                                resources))
         (readme-template (read-file-string template-path))
         (rendered-readme (render-template readme-template final-ctx)))

    (log-info s "\nForging files...\n")
    (catch #t
           (lambda ()
             (ensure-directory "dist")
             (ensure-directory (format #f "dist/~a" name))
             (write-file-string (format #f "dist/~a/README.org" name)
                                rendered-readme)
             (format #t
              "[Success] Project '~a' has been breathed into existence!
" name))
           (lambda (key . args)
             (format #t "[Error] Failed to forge the project workspace: ~a: ~a
"
                     key args)))))

;; =========================================================================
;; Command Line Options Interface
;; =========================================================================

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
    (help (single-char #\h)
          (value #f))
    (resources (single-char #\r)
               (value #t))))

(define* (main #:key (args (command-line)))
  (newline)
  (write args)
  (newline)
  (let ((options (getopt-long args option-spec)))
    (log-info s "Starting Skapa, The Project Scaffolder")
    (run-wizard options)))
