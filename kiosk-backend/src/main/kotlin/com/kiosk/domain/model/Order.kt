package com.kiosk.domain.model

import java.time.LocalDateTime

enum class OrderStatus {
    PENDING,
    PAID,
    ACCEPTED,
    PREPARING,
    COMPLETED,
    PICKED_UP,
    CANCELLED
}

data class Order(
    val id: Long = 0,
    val orderNumber: String,
    val tableId: Long? = null,
    val status: OrderStatus = OrderStatus.PENDING,
    val totalAmount: Int,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

data class OrderItem(
    val id: Long = 0,
    val orderId: Long,
    val menuId: Long,
    val menuName: String,
    val quantity: Int,
    val unitPrice: Int,
    val totalPrice: Int,
    val selectedOptions: String = "" // JSON string of selected options
)

data class OrderWithItems(
    val order: Order,
    val items: List<OrderItem>
)
