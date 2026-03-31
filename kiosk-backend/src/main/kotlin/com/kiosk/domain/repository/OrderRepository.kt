package com.kiosk.domain.repository

import com.kiosk.domain.model.*
import java.time.LocalDate
import java.time.LocalDateTime

interface OrderRepository {
    suspend fun create(order: Order, items: List<OrderItem>): OrderWithItems
    suspend fun findById(id: Long): OrderWithItems?
    suspend fun findByOrderNumber(orderNumber: String): OrderWithItems?
    suspend fun findAll(
        status: OrderStatus? = null,
        tableId: Long? = null,
        from: LocalDateTime? = null,
        to: LocalDateTime? = null,
        limit: Int = 50,
        offset: Int = 0
    ): List<OrderWithItems>
    suspend fun updateStatus(id: Long, status: OrderStatus): Boolean
    suspend fun findActiveKitchenOrders(): List<OrderWithItems>
    suspend fun countByDateRange(from: LocalDate, to: LocalDate): Int
}
