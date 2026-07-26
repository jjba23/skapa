package example

import zio.test.*
import zio.http.*

object RoutesSpec extends ZIOSpecDefault:

  def spec =
    suite("Routes")(
      test("GET / returns Hello, world!") {

        for {
          response <- Routes.app.runZIO(
            Request.get(URL.decode("/").toOption.get)
          )
          body <- response.body.asString
        } yield assertTrue(body == "Hello, world!")
      }
    )
