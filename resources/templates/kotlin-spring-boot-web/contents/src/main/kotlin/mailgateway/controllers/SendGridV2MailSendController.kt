package mailgateway.controllers

import io.github.oshai.kotlinlogging.KotlinLogging
import io.github.oshai.kotlinlogging.withLoggingContext
import mailgateway.openapi.controllers.V2MailSendController
import mailgateway.openapi.models.MailDeliveryRequest
import mailgateway.services.SdkSendgridClient
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.RestController

@RestController
class SendGridV2MailSendController(
    val sendgridClient: SdkSendgridClient,
) : V2MailSendController {
    private val logger = KotlinLogging.logger {}

    override fun sendMail(mailDeliveryRequest: MailDeliveryRequest): ResponseEntity<Unit> {
        val loggingContext: Map<String, String> =
            mapOf(
                "subject" to mailDeliveryRequest.subject,
                "templateId" to mailDeliveryRequest.templateId,
                "from" to mailDeliveryRequest.from.emailAddress,
                "to" to mailDeliveryRequest.to.emailAddress,
            )

        withLoggingContext(loggingContext) {
            logger.info { "Received mail delivery request, sending mail to SendGrid" }

            sendgridClient.sendMail(mailDeliveryRequest)

            logger.info { "Success sending mail to SendGrid" }

            return ResponseEntity.accepted().build()
        }
    }
}
