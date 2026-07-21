((name . "Fullstack Web App")
 ;;
 (prompts ((key . project-name) (prompt . "Project name")
           (required? . #t)
           (type . string))

          ((key . creator) (prompt . "Project author")
           (required? . #t)
           (type . string))

          ((key . framework) (prompt . "Backend Framework")
           (type . choice)
           (choices "spring" "ktor" "htmx")
           (default . "spring"))

          ((key . include-db) (prompt . "Include PostgreSQL configuration?")
           (type . boolean)
           (default . #t))))
