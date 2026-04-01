package com.kiosk.plugins

import com.kiosk.domain.model.AppException
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import kotlinx.serialization.Serializable
import java.time.Instant

fun Application.configureStatusPages() {
    install(StatusPages) {
        exception<AppException.NotFound> { call, cause ->
            call.respond(HttpStatusCode.NotFound, errorResponse(HttpStatusCode.NotFound, cause.message, call))
        }
        exception<AppException.BadRequest> { call, cause ->
            call.respond(HttpStatusCode.BadRequest, errorResponse(HttpStatusCode.BadRequest, cause.message, call))
        }
        exception<AppException.Unauthorized> { call, cause ->
            call.respond(HttpStatusCode.Unauthorized, errorResponse(HttpStatusCode.Unauthorized, cause.message, call))
        }
        exception<AppException.Forbidden> { call, cause ->
            call.respond(HttpStatusCode.Forbidden, errorResponse(HttpStatusCode.Forbidden, cause.message, call))
        }
        exception<AppException.Conflict> { call, cause ->
            call.respond(HttpStatusCode.Conflict, errorResponse(HttpStatusCode.Conflict, cause.message, call))
        }
        exception<Exception> { call, cause ->
            call.application.environment.log.error("Unhandled exception", cause)
            call.respond(
                HttpStatusCode.InternalServerError,
                errorResponse(HttpStatusCode.InternalServerError, "서버 오류가 발생했습니다", call)
            )
        }
    }
}

private fun errorResponse(status: HttpStatusCode, message: String?, call: ApplicationCall) = ErrorResponse(
    code = status.value,
    error = status.description,
    message = message ?: status.description,
    path = call.request.path(),
    timestamp = Instant.now().toString()
)

@Serializable
data class ErrorResponse(
    val code: Int,
    val error: String,
    val message: String,
    val path: String,
    val timestamp: String
)
