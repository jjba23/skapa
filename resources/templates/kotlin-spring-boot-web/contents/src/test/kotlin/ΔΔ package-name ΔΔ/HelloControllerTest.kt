package ΔΔpackage-nameΔΔ

import io.kotest.core.spec.style.FunSpec
import io.kotest.datatest.withData
import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import ΔΔpackage-nameΔΔ.controllers.ApplicationControllerAdvice
import ΔΔpackage-nameΔΔ.controllers.HelloController
import ΔΔpackage-nameΔΔ.util.TestTags
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import kotlin.time.Duration.Companion.seconds

class HelloControllerTest :
    FunSpec({

        val v1Route = "/v1/hello"

        fun createMockMvc(returnStatus: HttpStatus): MockMvc {
            return MockMvcBuilders
                .standaloneSetup(HelloController())
                .setControllerAdvice(ApplicationControllerAdvice())
                .build()
        }

        context("POST $v1Route").config(
            failfast = true,
            timeout = 10.seconds,
            tags = setOf(TestTags.CONTROLLER_TEST, TestTags.UNIT_TEST),
        ) {
            test("should return 200 OK when request for hello world") {
                createMockMvc(HttpStatus.OK)
                    .perform(get(v1Route)).andExpect(status().isOk)
            }

        }
    })
