package ΔΔpackage-nameΔΔ

import zio.*
import zio.http.*

object HttpServer:

  val run: ZIO[Any, Throwable, Nothing] =
    Server
      .serve(AppRoutes.routes)
      .provide(
        Server.defaultWithPort(8080)
      )
