package ΔΔpackage-nameΔΔ

import zio._
import zio.http._

object AppRoutes:

  // Idiomatic ZIO HTTP 3.x correlation ID middleware
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
          _ <- ZIO.logInfo("Handling hello endpoint")
        yield Response.text("Hello World!")
      }
    ) @@ correlationIdMiddleware
