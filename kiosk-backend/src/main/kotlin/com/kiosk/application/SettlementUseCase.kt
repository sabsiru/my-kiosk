package com.kiosk.application

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.OrderRepository
import com.kiosk.domain.repository.PaymentRepository
import com.kiosk.domain.repository.SettlementRepository
import java.time.LocalDate

class SettlementUseCase(
    private val settlementRepository: SettlementRepository,
    private val orderRepository: OrderRepository,
    private val paymentRepository: PaymentRepository
) {
    suspend fun getDailySettlement(date: LocalDate): Settlement =
        settlementRepository.findByDate(date)
            ?: Settlement(date = date, totalRevenue = 0, totalOrders = 0)

    suspend fun getPeriodSettlement(from: LocalDate, to: LocalDate): List<Settlement> =
        settlementRepository.findByDateRange(from, to)

    suspend fun getByPaymentMethod(from: LocalDate, to: LocalDate): Map<String, Int> {
        val settlements = settlementRepository.findByDateRange(from, to)
        return mapOf(
            "CARD" to settlements.sumOf { it.cardAmount },
            "CASH" to settlements.sumOf { it.cashAmount },
            "KAKAO_PAY" to settlements.sumOf { it.kakaoPayAmount },
            "NAVER_PAY" to settlements.sumOf { it.naverPayAmount }
        )
    }

    suspend fun closeDaily(date: LocalDate): Settlement {
        var settlement = settlementRepository.findByDate(date)
        if (settlement == null) {
            recalculateForDate(date)
            settlement = settlementRepository.findByDate(date)
                .orNotFound("정산 데이터를 생성할 수 없습니다")
        }

        if (settlement.isClosed) {
            throw AppException.BadRequest("이미 마감된 정산입니다")
        }

        settlementRepository.close(date)
        return settlementRepository.findByDate(date)
            .orNotFound("마감된 정산 데이터를 조회할 수 없습니다")
    }

    suspend fun recalculateForDate(date: LocalDate): Settlement {
        val from = date.atStartOfDay()
        val to = date.atTime(23, 59, 59)
        val orders = orderRepository.findAll(from = from, to = to, limit = 10000, offset = 0)
        val payments = orders.mapNotNull { orderWithItems ->
            paymentRepository.findByOrderId(orderWithItems.order.id)
        }
        return calculateAndSave(date, orders, payments)
    }

    suspend fun calculateAndSave(date: LocalDate, orders: List<OrderWithItems>, payments: List<Payment>): Settlement {
        val completedPayments = payments.filter { it.status == PaymentStatus.COMPLETED }
        val cancelledPayments = payments.filter { it.status == PaymentStatus.CANCELLED }

        val settlement = Settlement(
            date = date,
            totalRevenue = completedPayments.sumOf { it.amount },
            totalOrders = orders.count { it.order.status != OrderStatus.CANCELLED },
            cardAmount = completedPayments.filter { it.method == PaymentMethod.CARD }.sumOf { it.amount },
            cashAmount = completedPayments.filter { it.method == PaymentMethod.CASH }.sumOf { it.amount },
            kakaoPayAmount = completedPayments.filter { it.method == PaymentMethod.KAKAO_PAY }.sumOf { it.amount },
            naverPayAmount = completedPayments.filter { it.method == PaymentMethod.NAVER_PAY }.sumOf { it.amount },
            cancelledAmount = cancelledPayments.sumOf { it.amount },
            cancelledCount = cancelledPayments.size
        )

        return settlementRepository.createOrUpdate(settlement)
    }
}
