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

  val routes: Routes[UserRepository, Response] =
    (rootRoutes ++ UserRoutes.routes)


object UserRoutes:

  val routes: Routes[UserRepository, Response] =
    Routes(
      // GET /users
      Method.GET / "users" -> handler {
        ZIO.serviceWithZIO[UserRepository] { repo =>
          for
            users <- repo.findAll
            _     <- ZIO.logInfo(s"Fetched ${users.length} users")
          yield Response.json(users.toString)
        }
      },

      // GET /users/:id
      Method.GET / "users" / string("id") -> handler { (id: String, _: Request) =>
        ZIO.serviceWithZIO[UserRepository] { repo =>
          for
            maybeUser <- repo.findById(id)
          yield maybeUser match
            case Some(user) => Response.json(user.toString)
            case None       => Response.status(Status.NotFound)
          }
      },

      // POST /users
      Method.POST / "users" -> handler { (_: Request) =>
        ZIO.serviceWithZIO[UserRepository] { repo =>
          for
            _ <- repo.save(User("123", "Alice", "alice@example.com"))
            _ <- ZIO.logInfo("Created user 123")
          yield Response.status(Status.Created)
        }
      },

      // DELETE /users/:id
      Method.DELETE / "users" / string("id") -> handler { (id: String, _: Request) =>
        ZIO.serviceWithZIO[UserRepository] { repo =>
          for
            deleted <- repo.delete(id)
            _       <- ZIO.logInfo(s"Delete user $id result: $deleted")
          yield if deleted then Response.status(Status.NoContent)
                else Response.status(Status.NotFound)
        }
      }
    )
