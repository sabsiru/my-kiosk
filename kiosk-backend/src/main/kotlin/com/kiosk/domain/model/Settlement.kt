package com.kiosk.domain.model

import java.time.LocalDate
import java.time.LocalDateTime

data class Settlement(
    val id: Long = 0,
    val date: LocalDate,
    val totalRevenue: Int,
    val totalOrders: Int,
    val cardAmount: Int = 0,
    val cashAmount: Int = 0,
    val kakaoPayAmount: Int = 0,
    val naverPayAmount: Int = 0,
    val cancelledAmount: Int = 0,
    val cancelledCount: Int = 0,
    val isClosed: Boolean = false,
    val closedAt: LocalDateTime? = null
)
