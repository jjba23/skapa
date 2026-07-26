package mailgateway.util

import io.kotest.core.NamedTag

object TestTags {
    val CONTROLLER_TEST = NamedTag("controller-test")
    val INTEGRATION_TEST = NamedTag("integration-test")
    val UNIT_TEST = NamedTag("unit-test")
}
