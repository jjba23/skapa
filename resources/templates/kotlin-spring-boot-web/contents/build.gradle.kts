plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.spring)
    alias(libs.plugins.spring.boot)
    alias(libs.plugins.spring.dependency.management)
    alias(libs.plugins.kotest)
    alias(libs.plugins.fabrikt)
    alias(libs.plugins.jacoco)
    alias(libs.plugins.ktlint)
    alias(libs.plugins.version.catalog.update)
    idea
}

group = "nl.vandebron"
version = "0.1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencyLocking {
    lockAllConfigurations()
    lockMode = LockMode.STRICT
}

kotlin {
    jvmToolchain(25)
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict", "-Xannotation-default-target=param-property")
    }
}

fabrikt {
    generate("mail-gateway") {
        apiFile = file("src/main/resources/static/openapi.yaml")
        basePackage = "mailgateway.openapi"
        model {
            generate = enabled
            sealedInterfacesForOneOf = enabled
            ignoreUnknownProperties = enabled
            serializationLibrary = Jackson
            instantLibrary = Kotlinx
        }
        controller {
            generate = enabled
            suspendModifier = disabled
            completionStage = disabled
            target = Spring
        }
        typeOverrides {
            datetime = Instant
        }
    }
}

val mockitoAgent = configurations.create("mockitoAgent")

tasks.named<Test>("test") {
    useJUnitPlatform()
    finalizedBy(tasks.named("jacocoTestReport"))
    systemProperty("spring.profiles.active", "test")

    testLogging {
        events("passed", "skipped", "failed")
        showStandardStreams = true
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    }
}

tasks.withType<Test>().configureEach {
    jvmArgumentProviders.add(
        CommandLineArgumentProvider { listOf("-javaagent:${mockitoAgent.asPath}") },
    )
}

tasks.named<JacocoReport>("jacocoTestReport") {
    reports {
        xml.required.set(true)
    }
}

tasks.named<JacocoCoverageVerification>("jacocoTestCoverageVerification") {
    dependsOn(tasks.named("jacocoTestReport"))
    violationRules {
        rule {
            limit {
                minimum = "0.7".toBigDecimal()
            }
        }
    }
}

tasks.runKtlintCheckOverMainSourceSet {
    setSource(tasks.fabriktGenerate)
}

ktlint {
    filter {
        exclude {
            it.file.path.contains("generated")
        }
    }
}

dependencies {
    // Kotlin language & features
    implementation(libs.kotlin.reflect)

    // HTTP server
    implementation(libs.spring.boot.starter.web)
    implementation(libs.spring.boot.starter.validation)
    implementation(libs.springdoc.openapi)
    implementation(libs.jackson.module.kotlin)
    implementation(libs.spring.boot.starter.actuator)

    // security
    implementation(libs.spring.security.web)
    implementation(libs.spring.security.config)

    // HTTP client
    implementation(libs.spring.boot.starter.restclient)

    // E-Mail
    implementation(libs.sendgrid)

    // Ops & Logging
    implementation(libs.kotlin.logging)
    implementation(libs.logstash.logback.encoder)

    // Metrics
    implementation(libs.spring.boot.starter.opentelemetry)
    implementation(libs.opentelemetry)
    implementation(libs.opentelemetry.instrumentation.annotations)
    implementation(libs.opentelemetry.micrometer)

    // Tests
    testImplementation(libs.spring.boot.starter.test)
    testImplementation(libs.spring.boot.webtestclient)
    testImplementation(libs.spring.boot.restclient.test)
    testImplementation(libs.spring.boot.starter.webmvc.test)
    testImplementation(platform(libs.kotest.bom))
    testImplementation(libs.bundles.kotest)
    testImplementation(libs.kotest.extensions.spring)
    testImplementation(libs.opentelemetry.sdk.testing)

    testImplementation(libs.mockito.kotlin)
    testImplementation(libs.mockito.core)
    mockitoAgent(libs.mockito.core) { isTransitive = false }

    testImplementation(platform(libs.kotest.bom))
    testImplementation(libs.bundles.kotest)
}
