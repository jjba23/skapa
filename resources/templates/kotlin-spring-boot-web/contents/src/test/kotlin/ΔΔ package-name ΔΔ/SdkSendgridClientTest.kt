package ΔΔpackage-nameΔΔ

import io.github.oshai.kotlinlogging.KotlinLogging
import io.kotest.assertions.throwables.shouldNotThrowAny
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import mailgateway.Prelude.Counters.SENDGRID_FAILURE_COUNTER
import mailgateway.Prelude.Counters.SENDGRID_SUCCESSFUL_COUNTER
import mailgateway.openapi.models.MailDeliveryRequest
import mailgateway.openapi.models.MailParticipant
import mailgateway.services.SdkSendgridClient
import mailgateway.services.SendMailException
import mailgateway.util.StubSendGrid
import mailgateway.util.TestTags
import org.springframework.http.HttpStatus
import kotlin.time.Duration.Companion.seconds

class SdkSendgridClientTest :
    FunSpec({

        val logger = KotlinLogging.logger {}

        val someFakeApiKey = "API_KEY"

        val someRequest =
            MailDeliveryRequest(
                to = MailParticipant("test@example.com", "Tester"),
                from = MailParticipant("sender@example.com"),
                subject = "Hello",
                templateId = "d-123",
            )

        context("SdkSendgridClient").config(
            failfast = true,
            timeout = 10.seconds,
            tags = setOf(TestTags.UNIT_TEST),
        ) {
            test("sends mail successfully and increments counter") {
                val meterRegistry = SimpleMeterRegistry()

                val client =
                    SdkSendgridClient(
                        StubSendGrid(apiKey = someFakeApiKey, returnStatus = HttpStatus.ACCEPTED.value()),
                        meterRegistry,
                    )

                logger.info { "someRequest: $someRequest" }

                shouldNotThrowAny { client.sendMail(someRequest) }

                meterRegistry.get(SENDGRID_SUCCESSFUL_COUNTER).counter().count() shouldBe 1.0
            }

            test("fails and increments counter") {
                val meterRegistry = SimpleMeterRegistry()

                val client =
                    SdkSendgridClient(
                        StubSendGrid(
                            apiKey = someFakeApiKey,
                            returnStatus = HttpStatus.INTERNAL_SERVER_ERROR.value(),
                        ),
                        meterRegistry,
                    )

                logger.info { "someRequest: $someRequest" }

                shouldThrow<SendMailException> { client.sendMail(someRequest) }

                meterRegistry.get(SENDGRID_FAILURE_COUNTER).counter().count() shouldBe 1.0
            }
        }
    })
