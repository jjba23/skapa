package ΔΔpackage-nameΔΔ

import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import ΔΔpackage-nameΔΔ.controllers.HelloController
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertNotNull
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest(
    classes = [
        SimpleMeterRegistry::class,
        HelloController::class,
    ],
)
class SmokeTest {
    @Test
    fun contextLoads(
        @Autowired controller: HelloController,
    ) {
        assertNotNull(controller)
    }
}
