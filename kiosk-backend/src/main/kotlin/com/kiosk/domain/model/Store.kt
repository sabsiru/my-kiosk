package com.kiosk.domain.model

import java.time.LocalTime

data class Store(
    val id: Long = 1,
    val name: String,
    val openTime: LocalTime = LocalTime.of(9, 0),
    val closeTime: LocalTime = LocalTime.of(22, 0),
    val isOpen: Boolean = true,
    val hideAdminButton: Boolean = false
)
