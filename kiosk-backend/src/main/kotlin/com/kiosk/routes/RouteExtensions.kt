package com.kiosk.routes

import com.kiosk.domain.model.AppException
import io.ktor.server.application.*
import java.time.LocalDate

/**
 * Route 공통 유틸: 파라미터 파싱, enum 변환
 */

// Path parameter → Long ID
fun ApplicationCall.pathId(name: String = "id"): Long =
    parameters[name]?.toLongOrNull()
        ?: throw AppException.BadRequest("잘못된 $name")

// Query parameter → Long? (optional)
fun ApplicationCall.queryLong(name: String): Long? =
    request.queryParameters[name]?.toLongOrNull()

// Query parameter → Int with default
fun ApplicationCall.queryInt(name: String, default: Int): Int =
    request.queryParameters[name]?.toIntOrNull() ?: default

// Query parameter → LocalDate with default
fun ApplicationCall.queryDate(name: String, default: LocalDate = LocalDate.now()): LocalDate =
    request.queryParameters[name]?.let { LocalDate.parse(it) } ?: default

// Query parameter → LocalDate range (from, to) with defaults
fun ApplicationCall.queryDateRange(
    defaultDays: Long = 7
): Pair<LocalDate, LocalDate> {
    val from = queryDate("from", LocalDate.now().minusDays(defaultDays))
    val to = queryDate("to", LocalDate.now())
    return from to to
}

// String → Enum (safe)
inline fun <reified T : Enum<T>> parseEnum(value: String, label: String = ""): T =
    try {
        enumValueOf<T>(value)
    } catch (_: IllegalArgumentException) {
        throw AppException.BadRequest("잘못된 ${label.ifEmpty { T::class.simpleName ?: "값" }}: $value")
    }

// Query parameter → Enum? (optional)
inline fun <reified T : Enum<T>> ApplicationCall.queryEnum(name: String): T? =
    request.queryParameters[name]?.let { parseEnum<T>(it, name) }
