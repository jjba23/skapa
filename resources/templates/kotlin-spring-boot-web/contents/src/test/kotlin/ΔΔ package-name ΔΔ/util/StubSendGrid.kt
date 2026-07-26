package ΔΔpackage-nameΔΔ.util

import com.sendgrid.Request
import com.sendgrid.Response
import com.sendgrid.SendGrid
import org.springframework.http.HttpStatus
import java.io.IOException

class StubSendGrid(
    apiKey: String?,
    val returnStatus: Int = HttpStatus.ACCEPTED.value(),
    val returnBody: String =
        """
        {"foo": "bar"}
        """.trimIndent(),
) : SendGrid(apiKey) {
    var request: Request? = null

    @Throws(IOException::class)
    override fun makeCall(request: Request?): Response {
        this.request = request
        val response = Response()
        response.statusCode = returnStatus
        response.body = returnBody
        val headers: MutableMap<String?, String?> = HashMap()
        headers["Test"] = "Header"
        response.headers = headers
        return response
    }
}
