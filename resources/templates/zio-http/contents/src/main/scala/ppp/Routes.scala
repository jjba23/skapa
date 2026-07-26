package example

import zio.http.*

object Routes:

  val app: Routes[Any, Response] =
    Routes(
      Method.GET / Root ->
        handler(Response.text("Hello, world!")),

      Method.GET / "health" ->
        handler(Response.text("OK"))
    )
