ThisBuild / scalaVersion := "3.7.3"

lazy val root = project
  .in(file("."))
  .settings(
    name := "zio-http-template",
    version := "0.1.0",

    libraryDependencies ++= Seq(
      "dev.zio" %% "zio" % "2.1.19",
      "dev.zio" %% "zio-http" % "3.3.3",

      "dev.zio" %% "zio-test" % "2.1.19" % Test,
      "dev.zio" %% "zio-test-sbt" % "2.1.19" % Test
    ),

    testFrameworks += new TestFramework("zio.test.sbt.ZTestFramework")
  )
