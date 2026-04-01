package com.kiosk.application

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.OrderRepository
import com.kiosk.domain.repository.PaymentRepository

class PaymentUseCase(
    private val paymentRepository: PaymentRepository,
    private val orderRepository: OrderRepository
) {
    suspend fun createPayment(orderId: Long, method: PaymentMethod): Payment {
        val order = orderRepository.findById(orderId)
            ?: throw AppException.NotFound("주문을 찾을 수 없습니다: $orderId")

        if (order.order.status in listOf(OrderStatus.PAID, OrderStatus.CANCELLED)) {
            throw AppException.BadRequest("결제할 수 없는 주문입니다")
        }

        val existing = paymentRepository.findByOrderId(orderId)
        if (existing != null && existing.status == PaymentStatus.COMPLETED) {
            throw AppException.Conflict("이미 결제된 주문입니다")
        }

        val payment = paymentRepository.create(
            Payment(
                orderId = orderId,
                method = method,
                amount = order.order.totalAmount
            )
        )

        // 실제 PG 연동은 여기서 처리 (현재는 즉시 승인 시뮬레이션)
        paymentRepository.updateStatus(
            payment.id,
            PaymentStatus.COMPLETED,
            approvalNumber = "APV-${System.currentTimeMillis()}",
            pgTransactionId = "PG-${payment.id}"
        )
        orderRepository.updateStatus(orderId, OrderStatus.PAID)

        return paymentRepository.findById(payment.id)
            ?: throw AppException.NotFound("결제 정보를 조회할 수 없습니다")
    }

    suspend fun cancelPayment(paymentId: Long): Payment {
        val payment = paymentRepository.findById(paymentId)
            ?: throw AppException.NotFound("결제를 찾을 수 없습니다: $paymentId")

        if (payment.status != PaymentStatus.COMPLETED) {
            throw AppException.BadRequest("완료된 결제만 취소할 수 있습니다")
        }

        paymentRepository.updateStatus(paymentId, PaymentStatus.CANCELLED)
        orderRepository.updateStatus(payment.orderId, OrderStatus.CANCELLED)

        return paymentRepository.findById(paymentId)
            .orNotFound("결제 정보를 조회할 수 없습니다")
    }

    suspend fun getPaymentStatus(paymentId: Long): Payment =
        paymentRepository.findById(paymentId)
            ?: throw AppException.NotFound("결제를 찾을 수 없습니다: $paymentId")
}
