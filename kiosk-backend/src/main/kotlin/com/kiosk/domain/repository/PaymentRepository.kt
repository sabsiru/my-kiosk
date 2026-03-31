package com.kiosk.domain.repository

import com.kiosk.domain.model.Payment
import com.kiosk.domain.model.PaymentStatus

interface PaymentRepository {
    suspend fun create(payment: Payment): Payment
    suspend fun findById(id: Long): Payment?
    suspend fun findByOrderId(orderId: Long): Payment?
    suspend fun updateStatus(id: Long, status: PaymentStatus, approvalNumber: String? = null, pgTransactionId: String? = null): Boolean
}
