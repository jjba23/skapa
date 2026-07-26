package mailgateway.controllers

import mailgateway.openapi.models.MailDeliveryFailure
import mailgateway.services.SendMailException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class ApplicationControllerAdvice {
    @ExceptionHandler(SendMailException::class)
    fun handleSendMailException(ex: Exception): ResponseEntity<MailDeliveryFailure> =
        ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            MailDeliveryFailure(
                cause = "Error sending mail: ${ex.message}",
            ),
        )
}
