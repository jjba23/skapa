((name . "Scala 3 ZIO + HTTP")
 ;; Wizard prompts and steps
 (prompts ((key . project-name)
           (prompt . "Project name (Lisp convention, kebab-case)")
           (required? . #t)
           (type . string))
          ((key . project-class-name)
           (prompt . "Project class name (Java convention, PascalCase)")
           (required? . #t)
           (type . string))

          ((key . package-name)
           (prompt . "Project package name (Java convention, thisisasentence)")
           (required? . #t)
           (type . string))

          ((key . group-name)
           (prompt . "Project group (Java convention, dotted package name)")
           (required? . #t)
           (type . string))

          ((key . project-summary) (prompt . "Project summary")
           (required? . #t)
           (type . string))

          ((key . project-description) (prompt . "Project description")
           (required? . #t)
           (type . string))

          ((key . creator) (prompt . "Project author")
           (required? . #t)
           (type . string))))
