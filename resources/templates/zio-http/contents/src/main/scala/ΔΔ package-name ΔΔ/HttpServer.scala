package ΔΔpackage-nameΔΔ

import zio._
import zio.http._

object HttpServer:

  val run: ZIO[Any, Throwable, Nothing] =
    Server
      .serve(AppRoutes.routes)
      .provide(
        Server.defaultWithPort(8080),
        InMemoryUserRepository.live
      )
