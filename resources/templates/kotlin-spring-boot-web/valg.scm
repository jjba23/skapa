((name . "Kotlin Spring Boot Web")
 ;;
 (prompts ((key . project-name) (prompt . "Project name")
           (required? . #t)
           (type . string))

          ((key . creator) (prompt . "Project author")
           (required? . #t)
           (type . string))


          ((key . include-db) (prompt . "Include PostgreSQL configuration?")
           (type . boolean)
           (default . #t))))
