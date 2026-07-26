package mailgateway.controllers

import io.opentelemetry.api.trace.Span
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class TraceIdResponseFilter : OncePerRequestFilter() {
    companion object {
        private const val TRACE_ID_HEADER_NAME = "X-Trace-Id"
        private const val SPAN_ID_HEADER_NAME = "X-Span-Id"
    }

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain,
    ) {
        val spanContext = Span.current().spanContext

        if (spanContext.isValid) {
            response.addHeader(TRACE_ID_HEADER_NAME, spanContext.traceId)
            response.addHeader(SPAN_ID_HEADER_NAME, spanContext.spanId)
        }

        filterChain.doFilter(request, response)
    }
}
