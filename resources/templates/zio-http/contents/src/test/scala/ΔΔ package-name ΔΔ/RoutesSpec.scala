package ΔΔpackage-nameΔΔ

import zio.test.*
import zio.http.*

object RoutesSpec extends ZIOSpecDefault:

  def spec =
    suite("Routes")(
      test("GET /hello returns Hello World!") {

        for {
          response <- AppRoutes.routes.runZIO(
            Request.get(URL.decode("/hello").toOption.get)
          )
          body <- response.body.asString
        } yield assertTrue(body == "Hello World!")
      }
    )
