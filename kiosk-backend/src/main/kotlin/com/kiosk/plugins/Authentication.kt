package com.kiosk.plugins

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.response.*
import java.util.*

object JwtConfig {
    private val secret = System.getenv("JWT_SECRET") ?: "kiosk-dev-secret-key-change-in-production"
    private val issuer = "kiosk-backend"
    private val audience = "kiosk-admin"
    private val algorithm = Algorithm.HMAC256(secret)
    private const val VALIDITY_MS = 24 * 60 * 60 * 1000L // 24시간

    fun generateToken(adminId: Long, username: String, role: String, storeId: Long?): String = JWT.create()
        .withIssuer(issuer)
        .withAudience(audience)
        .withClaim("adminId", adminId)
        .withClaim("username", username)
        .withClaim("role", role)
        .withClaim("storeId", storeId)
        .withExpiresAt(Date(System.currentTimeMillis() + VALIDITY_MS))
        .sign(algorithm)

    fun Application.configureAuthentication() {
        install(Authentication) {
            jwt("admin-jwt") {
                verifier(
                    JWT.require(algorithm)
                        .withIssuer(issuer)
                        .withAudience(audience)
                        .build()
                )
                validate { credential ->
                    if (credential.payload.getClaim("adminId").asLong() != null) {
                        JWTPrincipal(credential.payload)
                    } else null
                }
                challenge { _, _ ->
                    call.respond(HttpStatusCode.Unauthorized, ErrorResponse("인증이 필요합니다"))
                }
            }
        }
    }
}

fun JWTPrincipal.adminId(): Long =
    payload.getClaim("adminId").asLong()

fun JWTPrincipal.role(): String =
    payload.getClaim("role").asString()

fun JWTPrincipal.storeId(): Long? =
    payload.getClaim("storeId").asLong()
