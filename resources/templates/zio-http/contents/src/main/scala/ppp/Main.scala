package example

import zio.*

object Main extends ZIOAppDefault:

  override def run =
    HttpServer.run
