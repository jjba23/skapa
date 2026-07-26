package mailgateway

import io.kotest.core.spec.style.FunSpec
import io.kotest.datatest.withData
import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import mailgateway.controllers.ApplicationControllerAdvice
import mailgateway.controllers.SendGridV2MailSendController
import mailgateway.services.SdkSendgridClient
import mailgateway.util.StubSendGrid
import mailgateway.util.TestTags
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import kotlin.time.Duration.Companion.seconds

class SendGridV2MailSendControllerTest :
    FunSpec({

        val v2Route = "/v2/mail/send"
        val v1Route = "/v1/mail/send"
        val apiKey = "API_KEY"

        fun createMockMvc(returnStatus: HttpStatus): MockMvc {
            val client =
                SdkSendgridClient(
                    StubSendGrid(apiKey = apiKey, returnStatus = returnStatus.value()),
                    SimpleMeterRegistry(),
                )
            return MockMvcBuilders
                .standaloneSetup(SendGridV2MailSendController(client))
                .setControllerAdvice(ApplicationControllerAdvice())
                .build()
        }

        val samplePayload =
            javaClass.classLoader
                .getResource("fixtures/simple-send-mail-payload.json")
                ?.readText() ?: throw IllegalArgumentException("Sample Mail Payload file not found!")

        context("POST $v2Route").config(
            failfast = true,
            timeout = 10.seconds,
            tags = setOf(TestTags.CONTROLLER_TEST, TestTags.UNIT_TEST),
        ) {
            test("should return 202 ACCEPTED when SendGrid processes correctly") {
                createMockMvc(HttpStatus.ACCEPTED)
                    .perform(
                        post(v2Route)
                            .content(samplePayload)
                            .contentType(MediaType.APPLICATION_JSON),
                    ).andExpect(status().isAccepted)
            }

            test("should return 400 BAD REQUEST when payload is malformed JSON") {
                createMockMvc(HttpStatus.ACCEPTED)
                    .perform(
                        post(v2Route)
                            .content("{ \"invalid\": ")
                            .contentType(MediaType.APPLICATION_JSON),
                    ).andExpect(status().isBadRequest)
            }

            test("should return 400 BAD REQUEST when payload is unsupported JSON") {
                createMockMvc(HttpStatus.ACCEPTED)
                    .perform(
                        post(v2Route)
                            .content("{ \"foo\": \"bar\"")
                            .contentType(MediaType.APPLICATION_JSON),
                    ).andExpect(status().isBadRequest)
            }

            test("should return 500 INTERNAL SERVER ERROR when downstream fails (SendGrid)") {
                createMockMvc(HttpStatus.INTERNAL_SERVER_ERROR)
                    .perform(
                        post(v2Route)
                            .content(samplePayload)
                            .contentType(MediaType.APPLICATION_JSON),
                    ).andExpect(status().isInternalServerError)
            }

            withData(
                nameFn = { "should return 500 INTERNAL SERVER ERROR if SendGrid returning ${it.name}" },
                HttpStatus.UNAUTHORIZED,
                HttpStatus.FORBIDDEN,
                HttpStatus.TOO_MANY_REQUESTS,
            ) { errorStatus ->
                createMockMvc(errorStatus)
                    .perform(
                        post(v2Route)
                            .content(samplePayload)
                            .contentType(MediaType.APPLICATION_JSON),
                    ).andExpect(status().isInternalServerError)
            }

            test("should return 415 UNSUPPORTED MEDIA TYPE if JSON is not sent") {
                createMockMvc(HttpStatus.ACCEPTED)
                    .perform(
                        post(v2Route)
                            .content("plain text")
                            .contentType(MediaType.TEXT_PLAIN),
                    ).andExpect(status().isUnsupportedMediaType)
            }

            test("should return 404 NOT FOUND for unknown route") {
                createMockMvc(HttpStatus.ACCEPTED)
                    .perform(
                        post(v1Route)
                            .content(samplePayload)
                            .contentType(MediaType.APPLICATION_JSON),
                    ).andExpect(status().isNotFound)
            }
        }
    })
