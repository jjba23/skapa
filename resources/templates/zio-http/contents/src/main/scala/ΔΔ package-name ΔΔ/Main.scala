package ΔΔpackage-nameΔΔ

import zio._
import zio.logging._


object Main extends ZIOAppDefault:

  override val bootstrap: ZLayer[ZIOAppArgs, Any, Any] =
    Runtime.removeDefaultLoggers >>> consoleJsonLogger(
      ConsoleLoggerConfig(
        format = LogFormat.default + LogFormat.annotations,
        filter = LogFilter.LogLevelByNameConfig(
          LogLevel.Info,
          "io.netty"      -> LogLevel.Info,
          "io.grpc.netty" -> LogLevel.Info
        )
      )
    )

  override def run: ZIO[Environment & (ZIOAppArgs & Scope), Any, Any] =
    HttpServer.run
