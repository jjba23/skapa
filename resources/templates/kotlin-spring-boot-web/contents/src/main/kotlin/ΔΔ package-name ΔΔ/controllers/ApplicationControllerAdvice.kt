package ΔΔpackage-nameΔΔ.controllers

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class ApplicationControllerAdvice {
    @ExceptionHandler(Exception::class)
    fun handleSendMailException(ex: Exception): ResponseEntity<String> =
        ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            "Error processing request: ${ex.message}",
        )
}
