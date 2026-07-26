package ΔΔpackage-nameΔΔ

import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import mailgateway.controllers.SendGridV2MailSendController
import mailgateway.services.SdkSendgridClient
import mailgateway.util.StubSendGrid
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertNotNull
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest(
    classes = [
        StubSendGrid::class,
        SimpleMeterRegistry::class,
        SdkSendgridClient::class,
        SendGridV2MailSendController::class,
    ],
)
class SmokeTest {
    @Test
    fun contextLoads(
        @Autowired controller: SendGridV2MailSendController,
        @Autowired sendGridClient: SdkSendgridClient,
    ) {
        assertNotNull(controller)
        assertNotNull(sendGridClient)
    }
}
