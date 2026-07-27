ThisBuild / scalaVersion := "2.13.18"

val scalaTestVersion        = "3.2.18"

lazy val root = project
  .in(file("."))
  .settings(
    name    := "ΔΔ project-name ΔΔ",
    version := "0.1.0",

    updateOptions      := updateOptions.value.withLatestSnapshots(false),
    evictionErrorLevel := Level.Error,

    Compile / run / fork := true,

    libraryDependencies ++= Seq(
      "org.scalatest" %% "scalatest" % scalaTestVersion % Test
    ),

    scalacOptions ++= Seq(
        // general settings
        "-release:21", // generate optimized JDK21 Scala code
        "-encoding",
        "utf-8",       // Specify character encoding used by source files.
        "-Ybackend-parallelism",
        "8",           // faster compilation on multicore

        // caching
        "-Ycache-plugin-class-loader:last-modified",
        "-Ycache-macro-class-loader:last-modified",

        // lints & warnings
        "-feature",              // provide information about misused language features
        "-deprecation",          // warn about deprecated usage
        "-unchecked",            // provide more info about type erasure
        "-Xfatal-warnings",      // fail compile on warning
        "-Xlint:_",              // enable all linters
        "-explaintypes",         // Explain type errors in more detail.
        "-Ywarn-unused",         // warn about unused code
        "-Ywarn-dead-code",      // warn about unreachable code
        "-Ywarn-extra-implicit", // Warn when more than one implicit parameter section is defined.
        "-Ywarn-numeric-widen",  // Warn when numerics are widened.
        "-Ywarn-value-discard",  // Warn when non-Unit expression results are unused.

        // optimizations
        "-opt:l:inline", // aggressive inlining
        "-opt:l:method", // optimize method bodies

        // Prepare for Scala 3 and warn of incompatibilities
        "-Xsource:3",
    )
  )
