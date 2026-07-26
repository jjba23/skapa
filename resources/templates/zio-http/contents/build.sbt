ThisBuild / scalaVersion := "3.7.3"

object Versions:
  val zio        = "2.1.26"
  val zioLogging = "2.3.1"
  val zioHttp    = "3.3.3"

lazy val root = project
  .in(file("."))
  .settings(
    name    := "ΔΔ project-name ΔΔ",
    version := "0.1.0",

    updateOptions      := updateOptions.value.withLatestSnapshots(false),
    evictionErrorLevel := Level.Error,

    libraryDependencies ++= Seq(
      "dev.zio" %% "zio"              % Versions.zio,
      "dev.zio" %% "zio-http"         % Versions.zioHttp,
      "dev.zio" %% "zio-logging"      % Versions.zioLogging,
      "dev.zio" %% "zio-logging-json" % Versions.zioLogging,

      "dev.zio" %% "zio-test"     % Versions.zio % Test,
      "dev.zio" %% "zio-test-sbt" % Versions.zio % Test
    ),

    testFrameworks += new TestFramework("zio.test.sbt.ZTestFramework"),

    scalacOptions ++= Seq(
      // General Settings
      "-release:25",           // Target JDK 21 bytecode
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
