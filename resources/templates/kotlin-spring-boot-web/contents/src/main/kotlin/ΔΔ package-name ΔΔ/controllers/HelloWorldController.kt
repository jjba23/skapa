package ΔΔpackage-nameΔΔ.controllers

import io.github.oshai.kotlinlogging.KotlinLogging
import io.github.oshai.kotlinlogging.withLoggingContext
import mailgateway.openapi.controllers.V1HelloWorldController
import mailgateway.services.SdkSendgridClient
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.RestController
import org.springframework.http.HttpStatus

@RestController
class HelloWorldController(
    val sendgridClient: SdkSendgridClient,
) : V1HelloWorldController {
    private val logger = KotlinLogging.logger {}

    override fun hello(): ResponseEntity<String> {
        return ResponseEntity.status(HttpStatus.OK).body("HELLO WORLD!")
    }
}
