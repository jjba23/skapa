ThisBuild / scalaVersion := "3.7.3"

val zioVersion        = "2.1.26"
val zioLoggingVersion = "2.5.3"
val zioHttpVersion    = "3.3.3"

lazy val root = project
  .in(file("."))
  .settings(
    name    := "ΔΔ project-name ΔΔ",
    version := "0.1.0",

    updateOptions      := updateOptions.value.withLatestSnapshots(false),
    evictionErrorLevel := Level.Error,

    libraryDependencies ++= Seq(
      "dev.zio" %% "zio"              % zioVersion,
      "dev.zio" %% "zio-http"         % zioHttpVersion,
      "dev.zio" %% "zio-logging"      % zioLoggingVersion,

      "dev.zio" %% "zio-test"     % zioVersion % Test,
      "dev.zio" %% "zio-test-sbt" % zioVersion % Test
    ),

    testFrameworks += new TestFramework("zio.test.sbt.ZTestFramework"),

    scalacOptions ++= Seq(
      "-encoding", "utf-8",    // Specify character encoding
      "-feature",              // Warn about misused language features
      "-deprecation",          // Warn about deprecated APIs
      "-unchecked",            // Enable additional warnings where type information is erased
      "-Xfatal-warnings",      // Fail compilation on warnings
      "-explain",              // Explain type errors in detail

      // Scala 3 Linting
      "-Wunused:all",          // Warn on unused imports, locals, privates, and parameters
      "-Wvalue-discard"        // Warn when non-Unit expression results are unused
    )
  )
