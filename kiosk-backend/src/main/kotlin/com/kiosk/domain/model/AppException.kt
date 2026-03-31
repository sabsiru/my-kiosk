package com.kiosk.domain.model

sealed class AppException(message: String) : RuntimeException(message) {
    class NotFound(message: String) : AppException(message)
    class BadRequest(message: String) : AppException(message)
    class Unauthorized(message: String) : AppException(message)
    class Forbidden(message: String) : AppException(message)
    class Conflict(message: String) : AppException(message)
}

fun <T> T?.orNotFound(message: String): T =
    this ?: throw AppException.NotFound(message)

fun <T> T?.orBadRequest(message: String): T =
    this ?: throw AppException.BadRequest(message)
