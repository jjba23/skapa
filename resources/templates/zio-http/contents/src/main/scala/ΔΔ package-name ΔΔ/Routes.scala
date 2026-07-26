package ΔΔpackage-nameΔΔ

import zio._
import zio.http._

object AppRoutes:

 val rootRoutes: Routes[Any, Nothing] = Routes(
      Method.GET / "health" -> handler(Response.text("OK")),
      Method.GET / "hello"  -> handler {
        for
          _ <- ZIO.logAnnotate("endpoint", "/hello")(ZIO.logInfo("Handling endpoint"))
        yield Response.text("Hello World!")
      }
    )

  val routes: Routes[Any, Response] =
    (rootRoutes ++ UserRoutes.routes) @@ correlationIdMiddleware


object UserRoutes:

  val routes: Routes[UserRepository, Response] =
    Routes(
      Method.GET / "users" -> handler {
        ZIO.serviceWithZIO[UserRepository] { repo =>
          for
            users <- repo.findAll
            _     <- ZIO.logInfo(s"Fetched ${users.length} users")
          yield Response.json(users.toString) // Replace with json encoding as needed
        }
      },

      Method.GET / "users" / string("id") -> handler { (id: String, _: Request) =>
        ZIO.serviceWithZIO[UserRepository] { repo =>
          for
            maybeUser <- repo.findById(id)
          yield maybeUser match
            case Some(user) => Response.json(user.toString)
            case None       => Response.status(Status.NotFound)
          }
      },

      Method.POST / "users" -> handler { (req: Request) =>
        ZIO.serviceWithZIO[UserRepository] { repo =>
          for
            _ <- repo.save(User("123", "Alice", "alice@example.com"))
            _ <- ZIO.logInfo("Created user 123")
          yield Response.status(Status.Created)
        }
      }
    )
