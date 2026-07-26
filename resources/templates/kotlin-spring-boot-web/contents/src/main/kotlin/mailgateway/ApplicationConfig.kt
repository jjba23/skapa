package mailgateway

import com.sendgrid.SendGrid
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.stereotype.Service

@ConfigurationProperties(prefix = "application.sendgrid")
data class SendgridConfig(
    val apiKey: String,
)

@Service
class MailGatewaySendGridConnection(
    config: SendgridConfig,
) : SendGrid(config.apiKey)
