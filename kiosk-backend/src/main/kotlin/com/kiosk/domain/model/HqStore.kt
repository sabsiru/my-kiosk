package com.kiosk.domain.model

import java.time.LocalDateTime

data class HqStore(
    val id: Long = 0,
    val name: String,
    val code: String,
    val dbName: String,
    val status: StoreStatus = StoreStatus.ACTIVE,
    val createdAt: LocalDateTime = LocalDateTime.now()
)

enum class StoreStatus {
    ACTIVE,
    INACTIVE,
    SUSPENDED
}
