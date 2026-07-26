package ΔΔpackage-nameΔΔ

import zio.http.*

object AppRoutes:


  val loggingMiddleware = HandlerAspect.customizeResponse { response =>
    response.header("X-Correlation-ID").fold(ZIO.unit) { id =>
      ZIO.logAnnotate("correlation_id", id)
    }
  }


  val routes: Routes[Any, Response] =
    Routes(
      Method.GET / Root ->
        handler(Response.text("Hello, world!")),

      Method.GET / "health" ->
        handler(Response.text("OK"))
    ) @@ loggingMiddleware
