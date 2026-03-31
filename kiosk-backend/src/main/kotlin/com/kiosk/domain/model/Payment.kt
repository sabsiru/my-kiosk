package com.kiosk.domain.model

import java.time.LocalDateTime

enum class PaymentMethod {
    CARD,
    KAKAO_PAY,
    NAVER_PAY,
    CASH
}

enum class PaymentStatus {
    PENDING,
    COMPLETED,
    CANCELLED,
    FAILED
}

data class Payment(
    val id: Long = 0,
    val orderId: Long,
    val method: PaymentMethod,
    val amount: Int,
    val status: PaymentStatus = PaymentStatus.PENDING,
    val approvalNumber: String? = null,
    val pgTransactionId: String? = null,
    val createdAt: LocalDateTime = LocalDateTime.now()
)
