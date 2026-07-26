package example

import zio.*
import zio.http.*

object HttpServer:

  val run: ZIO[Any, Throwable, Nothing] =
    Server
      .serve(Routes.app)
      .provide(
        Server.defaultWithPort(8080)
      )
