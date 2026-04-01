package com.kiosk.plugins

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.cors.routing.*
import org.slf4j.LoggerFactory

private val logger = LoggerFactory.getLogger("CORS")

fun Application.configureCORS() {
    install(CORS) {
        allowMethod(HttpMethod.Options)
        allowMethod(HttpMethod.Get)
        allowMethod(HttpMethod.Post)
        allowMethod(HttpMethod.Put)
        allowMethod(HttpMethod.Delete)
        allowHeader(HttpHeaders.Authorization)
        allowHeader(HttpHeaders.ContentType)

        val allowedHosts = System.getenv("CORS_ALLOWED_HOSTS")
        if (allowedHosts.isNullOrBlank()) {
            logger.warn("CORS_ALLOWED_HOSTS 환경변수 미설정 — 모든 호스트 허용 (개발 모드)")
            anyHost()
        } else {
            allowedHosts.split(",").map { it.trim() }.forEach { host ->
                allowHost(host, schemes = listOf("http", "https"))
            }
        }
    }
}
