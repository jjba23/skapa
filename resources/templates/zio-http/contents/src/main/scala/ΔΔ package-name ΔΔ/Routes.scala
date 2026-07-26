package ΔΔpackage-nameΔΔ

import zio._
import zio.http._

object AppRoutes:

  val correlationIdMiddleware: Middleware[Any] =
    Middleware.logAnnotate { req =>
      val cid = req.headers
        .get("X-Correlation-ID")
        .getOrElse(java.util.UUID.randomUUID().toString)

      Set(LogAnnotation("correlation_id", cid))
    }

  val routes: Routes[Any, Response] =
    Routes(
      Method.GET / "health" -> handler(Response.text("OK")),
      Method.GET / "hello"  -> handler {
        for
          _ <- ZIO.logAnnotate("endpoint", "/hello")(ZIO.logInfo("Handling endpoint"))
        yield Response.text("Hello World!")
      }
    ) @@ correlationIdMiddleware
