package ΔΔpackage-nameΔΔ.controllers

import io.github.oshai.kotlinlogging.KotlinLogging
import io.github.oshai.kotlinlogging.withLoggingContext
import ΔΔpackage-nameΔΔ.openapi.controllers.V1HelloController
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.RestController
import org.springframework.http.HttpStatus

@RestController
class HelloController() : V1HelloController {
    private val logger = KotlinLogging.logger {}

    override fun getHelloWorld(): ResponseEntity<String> {
        return ResponseEntity.status(HttpStatus.OK).body("HELLO WORLD!")
    }
}
