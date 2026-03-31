package com.kiosk.domain.model

enum class TableStatus {
    AVAILABLE,
    OCCUPIED,
    RESERVED
}

data class KioskTable(
    val id: Long = 0,
    val tableNumber: Int,
    val deviceId: String? = null,
    val status: TableStatus = TableStatus.AVAILABLE,
    val isActive: Boolean = true
)
