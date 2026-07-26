package mailgateway.services

import com.sendgrid.Method
import com.sendgrid.Request
import com.sendgrid.SendGrid
import com.sendgrid.helpers.mail.Mail
import com.sendgrid.helpers.mail.objects.Attachments
import com.sendgrid.helpers.mail.objects.Email
import com.sendgrid.helpers.mail.objects.Personalization
import io.github.oshai.kotlinlogging.KotlinLogging
import io.github.oshai.kotlinlogging.withLoggingContext
import io.micrometer.core.instrument.MeterRegistry
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.StatusCode
import mailgateway.Prelude.Counters.SENDGRID_FAILURE_COUNTER
import mailgateway.Prelude.Counters.SENDGRID_SUCCESSFUL_COUNTER
import mailgateway.openapi.models.MailDeliveryRequest
import mailgateway.openapi.models.MailParticipant
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service

interface SendgridClient {
    fun sendMail(req: MailDeliveryRequest)
}

class SendMailException(
    message: String,
) : Exception(message)

@Service
class SdkSendgridClient(
    private val sendGrid: SendGrid,
    meterRegistry: MeterRegistry,
) : SendgridClient {
    private val logger = KotlinLogging.logger {}

    private val successCounter = meterRegistry.counter(SENDGRID_SUCCESSFUL_COUNTER)
    private val failureCounter = meterRegistry.counter(SENDGRID_FAILURE_COUNTER)

    override fun sendMail(req: MailDeliveryRequest) {
        val span = Span.current()

        span.setAttribute("mail_provider", "sendgrid")
        span.setAttribute("mail.template_id", req.templateId)
        span.addEvent("Sending mail")

        try {
            val mail = buildSendGridMail(req, span.spanContext.traceId, span.spanContext.spanId)

            val request =
                Request().apply {
                    method = Method.POST
                    endpoint = "mail/send"
                    body = mail.build()
                }

            val response = sendGrid.api(request)

            span.setAttribute("http.response.status_code", response.statusCode.toLong())

            withLoggingContext(
                "mail-provider" to "sendgrid",
                "response-status" to response.statusCode.toString(),
            ) {
                logger.info { "SendGrid response received" }
            }

            if (response.statusCode != HttpStatus.ACCEPTED.value()) {
                failureCounter.increment()
                throw SendMailException("Failed to send mail with Sendgrid: ${response.body}")
            } else {
                successCounter.increment()
                span.setStatus(StatusCode.OK)
            }
        } catch (e: Exception) {
            span.recordException(e)
            span.setStatus(StatusCode.ERROR, e.message ?: "SendGrid Error")

            logger.error(e) { "Error sending mail: ${e.message}" }
            throw e
        }
    }

    private fun buildSendGridMail(
        cmd: MailDeliveryRequest,
        traceId: String,
        spanId: String,
    ): Mail {
        val personalization =
            Personalization().apply {
                addTo(cmd.to.toEmail())
                cmd.cc?.forEach { addCc(it.toEmail()) }
                cmd.bcc?.forEach { addBcc(it.toEmail()) }
                cmd.dynamicTemplateData?.forEach { (k, v) -> addDynamicTemplateData(k, v) }
            }

        return Mail().apply {
            from = cmd.from.toEmail()
            subject = cmd.subject
            addPersonalization(personalization)

            cmd.attachments?.forEach { a ->
                addAttachments(
                    Attachments
                        .Builder(a.filename, a.content)
                        .withType(a.mimeType)
                        .build(),
                )
            }

            templateId = cmd.templateId

            cmd.customArgs?.forEach { (k, v) -> addCustomArg(k, v) }

            addCustomArg("trace_id", traceId)
            addCustomArg("span_id", spanId)

            cmd.customHeaders?.forEach { (k, v) -> addHeader(k, v) }
            cmd.replyTo?.let { replyTo = it.toEmail() }
        }
    }

    private fun MailParticipant.toEmail(): Email = if (this.name != null) Email(this.emailAddress, this.name) else Email(this.emailAddress)
}
