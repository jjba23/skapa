package ΔΔpackage-nameΔΔ

import zio.*
import zio.logging.*

object Main extends ZIOAppDefault:

  override val bootstrap: ZLayer[ZIOAppArgs, Any, Any] =
    Runtime.removeDefaultLoggers >>> consoleJson(
      LogFormat.label("timestamp", LogFormat.timestamp.fixed(java.time.format.DateTimeFormatter.ISO_OFFSET_DATE_TIME)) +
      LogFormat.label("level", LogFormat.level) +
      LogFormat.label("thread", LogFormat.fiberId) +
      LogFormat.label("message", LogFormat.line) +
      LogFormat.label("cause", LogFormat.cause) +
      LogFormat.annotations
    )

  override def run =
    for
      _ <- ZIO.logInfo("Server starting up...")

      // Example: Add scoped context (MDC style)
      // _ <- ZIO.logAnnotate("correlation_id", "req-123456") {
      //        for
      //          _ <- ZIO.logAnnotate("user_id", "usr-8899") {
      //                 ZIO.logInfo("Executing request with context")
      //               }
      //          _ <- ZIO.logInfo("Executing request without user context, but keeping correlation_id")
      //        yield ()
      //      }

      _ <- HttpServer.run
    yield ()
