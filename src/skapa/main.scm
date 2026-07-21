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
  #:use-module (ice-9 ftw)
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

(define (directory? path)
  "Returns #t if the given file system path is a directory."
  (eq? 'directory
       (stat:type (stat path))))

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

(define (render-template-directory src-dir dest-dir context)
  "Recursively scans src-dir, renders both file/directory names and file contents,
and outputs the generated directory structure to dest-dir."
  (ensure-directory dest-dir)
  (let ((entries (or (scandir src-dir
                              (lambda (f)
                                (not (member f
                                             '("." "..")))))
                     '())))
    (unless (not (null? entries))
      (error "No files found for this template: ~a" src-dir))
    (for-each (lambda (entry)
                (let* ((rendered-entry (render-template entry context))
                       (src-path (format #f "~a/~a" src-dir entry))
                       (dest-path (format #f "~a/~a" dest-dir rendered-entry)))
                  (if (directory? src-path)
                      (render-template-directory src-path dest-path context)
                      (let* ((raw-content (read-file-string src-path))
                             (rendered (render-template raw-content context)))
                        (write-file-string dest-path rendered))))) entries)))

(define (list-templates resources-dir)
  "Scans the resources/templates directory and returns a list of available template names."
  (let* ((templates-dir (format #f "~a/templates" resources-dir))
         (entries (scandir templates-dir
                           (lambda (file)
                             (not (member file
                                          '("." "..")))))))
    (if entries
        (filter (lambda (entry)
                  (let ((full-path (format #f "~a/~a" templates-dir entry)))
                    (directory? full-path))) entries)
        '())))

(define (prompt-template options resources)
  "Retrieves template choice from CLI flags, or interactively lists available templates.
Errors out if the selected template does not exist."
  (let ((available-templates (list-templates resources)))
    (when (null? available-templates)
      (error "No templates found in resources directory" resources))

    (let* ((default-template (if (member "simple-readme" available-templates)
                                 "simple-readme"
                                 (car available-templates)))
           (prompt-msg (format #f "> Choose a template [~a]: "
                               (string-join available-templates "/")))
           (chosen (or (option-ref options
                                   'template #f)
                       (prompt-user prompt-msg default-template))))
      
      (if (member chosen available-templates) chosen
          (error (format #f
                  "Template '~a' does not exist. Available templates: ~a"
                  chosen
                  (string-join available-templates ", ")))))))

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
  "Orchestrates CLI flag evaluation, prompts, recursive template rendering, and directory output."
  (log-info s "Gathering materials for the forge...\n")
  (let* ((resources (option-ref options
                                'resources #f))
         (template-name (prompt-template options resources))
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
         (src-template-dir (format #f "~a/templates/~a" resources
                                   template-name))
         (dest-project-dir (format #f "dist/~a" name)))
    
    (log-info s "\nForging files...\n")
    (catch #t
           (lambda ()
             (ensure-directory "dist")
             (render-template-directory src-template-dir dest-project-dir
                                        final-ctx)
             (format #t "[Success] Project '~a' created from template '~a'!
"
                     name template-name))
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
    (template (single-char #\m)
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
