package com.kiosk.application

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.MenuRepository
import com.kiosk.domain.repository.OrderRepository
import com.kiosk.domain.repository.TableRepository
import com.kiosk.infrastructure.db.TenantContext
import com.kiosk.websocket.SyncEvent
import com.kiosk.websocket.SyncManager
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class OrderUseCase(
    private val orderRepository: OrderRepository,
    private val menuRepository: MenuRepository,
    private val tableRepository: TableRepository
) {
    suspend fun createOrder(
        tableId: Long?,
        items: List<CreateOrderItemRequest>
    ): OrderWithItems {
        if (items.isEmpty()) throw AppException.BadRequest("주문 항목이 비어있습니다")

        val orderItems = items.map { item ->
            val menu = menuRepository.findById(item.menuId)
                ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: ${item.menuId}")

            if (menu.isSoldOut) throw AppException.BadRequest("품절된 메뉴입니다: ${menu.name}")
            if (item.quantity <= 0) throw AppException.BadRequest("수량은 1 이상이어야 합니다")

            val unitPrice = menu.price + item.optionAdditionalPrice
            OrderItem(
                orderId = 0, // will be set by repository
                menuId = menu.id,
                menuName = menu.name,
                quantity = item.quantity,
                unitPrice = unitPrice,
                totalPrice = unitPrice * item.quantity,
                selectedOptions = item.selectedOptions
            )
        }

        val totalAmount = orderItems.sumOf { it.totalPrice }
        val orderNumber = generateOrderNumber()

        val order = Order(
            orderNumber = orderNumber,
            tableId = tableId,
            totalAmount = totalAmount
        )

        val result = orderRepository.create(order, orderItems)

        // 테이블이 지정된 경우 OCCUPIED로 변경
        if (tableId != null) {
            tableRepository.updateStatus(tableId, TableStatus.OCCUPIED)
        }

        // WebSocket 브로드캐스트: 주방에 신규 주문 알림
        val storeId = TenantContext.get()
        SyncManager.broadcastToKitchen(storeId, SyncEvent("NEW_ORDER", Json.encodeToString(mapOf("orderNumber" to result.order.orderNumber))))

        return result
    }

    suspend fun getOrder(orderNumber: String): OrderWithItems =
        orderRepository.findByOrderNumber(orderNumber)
            ?: throw AppException.NotFound("주문을 찾을 수 없습니다: $orderNumber")

    suspend fun getOrderById(id: Long): OrderWithItems =
        orderRepository.findById(id)
            ?: throw AppException.NotFound("주문을 찾을 수 없습니다: $id")

    suspend fun getOrders(
        status: OrderStatus? = null,
        tableId: Long? = null,
        from: LocalDateTime? = null,
        to: LocalDateTime? = null,
        limit: Int = 50,
        offset: Int = 0
    ): List<OrderWithItems> =
        orderRepository.findAll(status, tableId, from, to, limit, offset)

    suspend fun updateOrderStatus(id: Long, status: OrderStatus): Boolean {
        orderRepository.findById(id)
            ?: throw AppException.NotFound("주문을 찾을 수 없습니다: $id")
        val result = orderRepository.updateStatus(id, status)

        // WebSocket 브로드캐스트: 주문 상태 변경 알림
        val storeId = TenantContext.get()
        val eventData = Json.encodeToString(mapOf("orderId" to id.toString(), "status" to status.name))
        SyncManager.broadcastToKitchen(storeId, SyncEvent("ORDER_STATUS_CHANGED", eventData))
        SyncManager.broadcastOrderStatus(storeId, SyncEvent("ORDER_STATUS_CHANGED", eventData))

        return result
    }

    suspend fun cancelOrder(id: Long): Boolean {
        val order = orderRepository.findById(id)
            ?: throw AppException.NotFound("주문을 찾을 수 없습니다: $id")

        if (order.order.status == OrderStatus.COMPLETED || order.order.status == OrderStatus.PICKED_UP) {
            throw AppException.BadRequest("완료된 주문은 취소할 수 없습니다")
        }

        return orderRepository.updateStatus(id, OrderStatus.CANCELLED)
    }

    suspend fun getActiveKitchenOrders(): List<OrderWithItems> =
        orderRepository.findActiveKitchenOrders()

    private suspend fun generateOrderNumber(): String {
        val today = LocalDate.now()
        val todayStr = today.format(DateTimeFormatter.ofPattern("yyyyMMdd"))
        val count = orderRepository.countByDateRange(today, today) + 1
        return "$todayStr-${count.toString().padStart(4, '0')}"
    }
}

data class CreateOrderItemRequest(
    val menuId: Long,
    val quantity: Int,
    val selectedOptions: String = "",
    val optionAdditionalPrice: Int = 0
)
