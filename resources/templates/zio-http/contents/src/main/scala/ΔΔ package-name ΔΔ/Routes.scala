package ΔΔpackage-nameΔΔ

import zio.http.*

object AppRoutes:

  val routes: Routes[Any, Response] =
    Routes(
      Method.GET / Root ->
        handler(Response.text("Hello, world!")),

      Method.GET / "health" ->
        handler(Response.text("OK"))
    )
