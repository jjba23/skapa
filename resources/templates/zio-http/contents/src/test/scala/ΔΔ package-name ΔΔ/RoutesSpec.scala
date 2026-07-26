package ΔΔpackage-nameΔΔ

import zio.test.*
import zio.http.*

object RoutesSpec extends ZIOSpecDefault:

  def spec =
    suite("Root Routes")(
      test("GET /hello returns Hello World!") {

        for {
          response <- AppRoutes.rootRoutes.runZIO(
            Request.get(URL.decode("/hello").toOption.get)
          )
          body <- response.body.asString
        } yield assertTrue(body == "Hello World!")
      }
    )
