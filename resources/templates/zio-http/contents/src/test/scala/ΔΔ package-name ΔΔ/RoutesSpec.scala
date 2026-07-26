package ΔΔpackage-nameΔΔ

import zio._
import zio.test._
import zio.http._
import zio.test.TestAspect._

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


object UserRoutesSpec extends ZIOSpecDefault:

  override def spec = suite("UserRoutesSpec")(

    test("GET /users should return 200 OK and an empty list initially") {
      for
        request  <- ZIO.succeed(Request.get(URL.root / "users"))
        response <- UserRoutes.routes.runZIO(request)
        body     <- response.body.asString
      yield assertTrue(
        response.status == Status.Ok,
        body == "List()"
      )
    },

    test("POST /users should create a user and return 201 Created") {
      for
        postReq <- ZIO.succeed(Request.post(URL.root / "users", Body.empty))
        postRes <- UserRoutes.routes.runZIO(postReq)

        getReq  <- ZIO.succeed(Request.get(URL.root / "users" / "123"))
        getRes  <- UserRoutes.routes.runZIO(getReq)
      yield assertTrue(
        postRes.status == Status.Created,
        getRes.status == Status.Ok
      )
    },

    test("GET /users/:id should return 404 Not Found for non-existing user") {
      for
        request  <- ZIO.succeed(Request.get(URL.root / "users" / "unknown-id"))
        response <- UserRoutes.routes.runZIO(request)
      yield assertTrue(
        response.status == Status.NotFound
      )
    },

    test("DELETE /users/:id should remove existing user") {
      for
        _        <- UserRoutes.routes.runZIO(Request.post(URL.root / "users", Body.empty))

        delRes   <- UserRoutes.routes.runZIO(Request.delete(URL.root / "users" / "123"))

        getRes   <- UserRoutes.routes.runZIO(Request.get(URL.root / "users" / "123"))
      yield assertTrue(
        delRes.status == Status.NoContent,
        getRes.status == Status.NotFound
      )
    }

  ).provide(
    Scope.default,
    InMemoryUserRepository.live
  ) @@ sequential @@ timeout(15.seconds)
