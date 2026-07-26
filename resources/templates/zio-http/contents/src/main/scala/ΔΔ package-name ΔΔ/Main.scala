package ΔΔpackage-nameΔΔ

import zio._
import zio.logging._


object Main extends ZIOAppDefault:

  override val bootstrap: ZLayer[ZIOAppArgs, Any, Any] =
    Runtime.removeDefaultLoggers >>> consoleJsonLogger()

  override def run =
    HttpServer.run
