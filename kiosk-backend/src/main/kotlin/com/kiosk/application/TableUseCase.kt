package com.kiosk.application

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.OrderRepository
import com.kiosk.domain.repository.PaymentRepository
import com.kiosk.domain.repository.TableRepository
import com.kiosk.infrastructure.db.TenantContext
import com.kiosk.websocket.SyncEvent
import com.kiosk.websocket.SyncManager
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class TableUseCase(
    private val tableRepository: TableRepository,
    private val orderRepository: OrderRepository,
    private val paymentRepository: PaymentRepository
) {

    suspend fun getTables(): List<KioskTable> =
        tableRepository.findAll()

    suspend fun createTable(tableNumber: Int, deviceId: String? = null): KioskTable {
        val existing = tableRepository.findByTableNumber(tableNumber)
        if (existing != null) {
            throw AppException.Conflict("이미 존재하는 테이블 번호입니다: $tableNumber")
        }
        return tableRepository.create(KioskTable(tableNumber = tableNumber, deviceId = deviceId))
    }

    suspend fun updateTable(id: Long, tableNumber: Int, deviceId: String?): KioskTable {
        tableRepository.findById(id)
            ?: throw AppException.NotFound("테이블을 찾을 수 없습니다: $id")
        return tableRepository.update(
            KioskTable(id = id, tableNumber = tableNumber, deviceId = deviceId)
        ) ?: throw AppException.NotFound("테이블 수정 실패")
    }

    suspend fun deleteTable(id: Long) {
        tableRepository.findById(id)
            ?: throw AppException.NotFound("테이블을 찾을 수 없습니다: $id")
        tableRepository.delete(id)
    }

    suspend fun updateStatus(id: Long, status: TableStatus) {
        tableRepository.findById(id)
            ?: throw AppException.NotFound("테이블을 찾을 수 없습니다: $id")
        tableRepository.updateStatus(id, status)
    }

    suspend fun checkoutTable(id: Long, method: PaymentMethod): List<Payment> {
        tableRepository.findById(id)
            ?: throw AppException.NotFound("테이블을 찾을 수 없습니다: $id")

        // 해당 테이블의 활성 주문 조회 (PENDING/PREPARING/COMPLETED)
        val allOrders = orderRepository.findAll(status = null, tableId = id, limit = 100, offset = 0)
        val activeOrders = allOrders.filter {
            it.order.status !in listOf(OrderStatus.CANCELLED, OrderStatus.PAID)
        }

        if (activeOrders.isEmpty()) {
            throw AppException.BadRequest("결제할 주문이 없습니다")
        }

        val payments = mutableListOf<Payment>()
        for (orderWithItems in activeOrders) {
            val order = orderWithItems.order
            val payment = paymentRepository.create(
                Payment(orderId = order.id, method = method, amount = order.totalAmount)
            )
            paymentRepository.updateStatus(
                payment.id, PaymentStatus.COMPLETED,
                approvalNumber = "APV-${System.currentTimeMillis()}",
                pgTransactionId = "PG-${payment.id}"
            )
            orderRepository.updateStatus(order.id, OrderStatus.PAID)
            payments.add(payment)
        }

        // 테이블 상태 리셋
        tableRepository.updateStatus(id, TableStatus.AVAILABLE)

        // WebSocket 브로드캐스트: 테이블 결제 완료
        val storeId = TenantContext.get()
        val eventData = Json.encodeToString(mapOf("tableId" to id.toString()))
        SyncManager.broadcastToKiosks(storeId, SyncEvent("TABLE_CHECKOUT", eventData))
        SyncManager.broadcastToKitchen(storeId, SyncEvent("TABLE_CHECKOUT", eventData))

        return payments
    }
}
