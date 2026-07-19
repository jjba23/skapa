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
  #:use-module (ice-9 string-fun)
  #:use-module (srfi srfi-13)
  #:use-module (scriba scriba)
  #:use-module (scriba auto)
  #:export (main))

(define s
  (scriba-auto-logger))

(define readme-template
  (string-append "# ---+++project-name+++---\n\n"
                 "> Formed by the hand of ---+++creator+++---.

" "## Overview\n"
                 "Welcome to ---+++project-name+++---.\n\n"
                 "---+++crossroads-content+++---\n"))

;; =========================================================================
;; The Runic Templating Engine
;; =========================================================================

(define (template-replace template key value)
  "Scans the template string and replaces all instances of the runic sequence
'---+++key+++---' with the given value string."
  (let ((rune-tag (string-append "---+++" key "+++---")))
    (string-replace-substring template rune-tag value)))

(define (render-template template context)
  "Recursively processes the template by mapping over an association list (alist)
of context keys and values, yielding the final injected string document."
  (let loop
    ((current-template template)
     (ctx context))
    (if (null? ctx) current-template
        (let* ((pair (car ctx))
               (key (car pair))
               (val (cdr pair)))
          (if (string? val)
              (loop (template-replace current-template key val)
                    (cdr ctx))
              (loop current-template
                    (cdr ctx)))))))

;; =========================================================================
;; User Input / I/O Interface
;; =========================================================================

(define (prompt-user message default-val)
  "Displays an interactive prompt string to the user, flushes the output port,
and returns trimmed input. Cascades to default-val if the input line is empty."
  (log-info s message)
  (force-output)
  (let ((input (string-trim-both (read-line))))
    (if (string-null? input) default-val input)))

;; =========================================================================
;; Crossroads Logic Manager
;; =========================================================================

(define (handle-crossroads type context-alist)
  "Evaluates the branching choice 'type' (Open Source vs. Proprietary).
Extends the incoming context alist by prompting for path-specific items
and binding the dynamically generated 'crossroads-content' template token."
  (cond
    ((string-ci=? type "o")
     (let* ((license-flag (assoc-ref context-alist "license"))
            (license (or license-flag
                         (prompt-user
                          "> Choose your shield (License) [MIT/GPL/Apache]: "
                          "MIT")))
            (content (string-append
                      "## License
This project is open-source and distributed under the **"
                      license "** license.\n")))
       (cons (cons "crossroads-content" content)
             (cons (cons "license" license) context-alist))))
    ((string-ci=? type "p")
     (let* ((owner-flag (assoc-ref context-alist "owner"))
            (owner (or owner-flag
                       (prompt-user
                        "> Enter the Copyright Owner (Longhouse Chief): "
                        "The Clan")))
            (content (string-append
                      "## Copyright
All rights reserved. Proprietary property of **" owner
                      "**.\n")))
       (cons (cons "crossroads-content" content)
             (cons (cons "owner" owner) context-alist))))
    (else (cons (cons "crossroads-content" "") context-alist))))

;; =========================================================================
;; Main Entry Point & Orchestration
;; =========================================================================

(define (run-wizard options)
  "Orchestrates the scaffolding lifecycle: extracts active CLI arguments,
prompts for unconfigured fields, evaluates the crossroads logic path,
and safely attempts to commit the structure to the underlying file system."
  (log-info s "Gathering materials for the forge...\n")
  (let* ((opt-name (option-ref options
                               'name #f))
         (name (or opt-name
                   (prompt-user "> Enter project name: " "my-project")))

         (opt-creator (option-ref options
                                  'creator #f))
         (creator (or opt-creator
                      (prompt-user "> Enter your name (The Creator): "
                                   "Anonymous")))

         (base-ctx (list (cons "project-name" name)
                         (cons "creator" creator)
                         (cons "license"
                               (option-ref options
                                           'license #f))
                         (cons "owner"
                               (option-ref options
                                           'owner #f))))

         (opt-type (option-ref options
                               'type #f))
         (type (or opt-type
                   (let loop
                     ()
                     (let ((t (prompt-user
                               "
--- THE CROSSROADS ---
> Is this project Open Source (o) or Proprietary (p)? "
                               "o")))
                       (if (member t
                                   '("o" "p" "O" "P")) t
                           (begin
                             (log-warning s
                              "Invalid layout. Please select 'o' or 'p'.
")
                             (loop)))))))

         (final-ctx (handle-crossroads type base-ctx))
         (rendered-readme (render-template readme-template final-ctx)))

    (log-info s "\nForging files...\n")
    (catch #t
           (lambda ()
             (mkdir name)
             (let ((port (open-output-file (string-append name "/README"))))
               (display rendered-readme port)
               (close-output-port port))
             (format #t
              "[Success] Project '~a' has been breathed into existence!
" name))
           (lambda (key . args)
             (format #t "[Error] Failed to forge the project workspace: ~a
" key)))))


;; ==========================================

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
               (value #f))))

(define* (main #:key (args (command-line)))
  (let* ((_ (begin
              (newline)
              (write args)
              (newline)))

         (options (getopt-long args option-spec))
         (resources (option-ref options
                                'resources #f)))
    (log-info s "Starting Skapa, The Project Scaffolder")
    (run-wizard options)))
