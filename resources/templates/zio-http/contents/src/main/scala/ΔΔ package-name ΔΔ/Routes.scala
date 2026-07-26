package ΔΔpackage-nameΔΔ

import zio.http.*

object AppRoutes:


  val correlationIdMiddleware: Middleware[Any] =
    Middleware.custom { handler =>
      Handler.fromFunctionZIO { (req: Request) =>
        val cid = req.headers
          .get("X-Correlation-ID")
          .getOrElse(java.util.UUID.randomUUID().toString)

        ZIO.logAnnotate("correlation_id", cid) {
          handler.run(req)
        }
      }
    }


  val routes: Routes[Any, Response] =
    Routes(
      Method.GET / Root ->
        handler(Response.text("Hello, world!")),

      Method.GET / "health" ->
        handler(Response.text("OK"))
    ) @@ correlationIdMiddleware
