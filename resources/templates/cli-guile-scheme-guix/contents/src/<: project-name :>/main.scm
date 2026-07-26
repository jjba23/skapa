<: license-header-scm :>

(define-module (<: project-name :> main)
  #:declarative? #t
  #:use-module (ice-9 getopt-long)
  #:export (main))

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
    (display "<: project-name :>")))
