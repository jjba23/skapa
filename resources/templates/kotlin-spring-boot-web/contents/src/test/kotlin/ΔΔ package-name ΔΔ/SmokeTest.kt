package ΔΔpackage-nameΔΔ

import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import ΔΔpackage-nameΔΔ.controllers.V1HelloController
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertNotNull
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest(
    classes = [
        SimpleMeterRegistry::class,
        V1HelloController::class,
    ],
)
class SmokeTest {
    @Test
    fun contextLoads(
        @Autowired controller: V1HelloController,
    ) {
        assertNotNull(controller)
        assertNotNull(sendGridClient)
    }
}
