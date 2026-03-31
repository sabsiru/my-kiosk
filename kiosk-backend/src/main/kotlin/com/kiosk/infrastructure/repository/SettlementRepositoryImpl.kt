package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.Settlement
import com.kiosk.domain.repository.SettlementRepository
import com.kiosk.infrastructure.db.SettlementTable
import com.kiosk.infrastructure.db.storeDbQuery
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction
import java.time.LocalDate
import java.time.LocalDateTime

class SettlementRepositoryImpl : SettlementRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun findByDate(date: LocalDate): Settlement? = dbQuery {
        SettlementTable.select { SettlementTable.date eq date }
            .map { it.toSettlement() }
            .singleOrNull()
    }

    override suspend fun findByDateRange(from: LocalDate, to: LocalDate): List<Settlement> = dbQuery {
        SettlementTable.select {
            (SettlementTable.date greaterEq from) and (SettlementTable.date lessEq to)
        }
            .orderBy(SettlementTable.date, SortOrder.DESC)
            .map { it.toSettlement() }
    }

    override suspend fun createOrUpdate(settlement: Settlement): Settlement = dbQuery {
        val existing = SettlementTable.select { SettlementTable.date eq settlement.date }
            .singleOrNull()

        if (existing != null) {
            SettlementTable.update({ SettlementTable.date eq settlement.date }) {
                it[totalRevenue] = settlement.totalRevenue
                it[totalOrders] = settlement.totalOrders
                it[cardAmount] = settlement.cardAmount
                it[cashAmount] = settlement.cashAmount
                it[kakaoPayAmount] = settlement.kakaoPayAmount
                it[naverPayAmount] = settlement.naverPayAmount
                it[cancelledAmount] = settlement.cancelledAmount
                it[cancelledCount] = settlement.cancelledCount
            }
            settlement.copy(id = existing[SettlementTable.id])
        } else {
            val id = SettlementTable.insert {
                it[date] = settlement.date
                it[totalRevenue] = settlement.totalRevenue
                it[totalOrders] = settlement.totalOrders
                it[cardAmount] = settlement.cardAmount
                it[cashAmount] = settlement.cashAmount
                it[kakaoPayAmount] = settlement.kakaoPayAmount
                it[naverPayAmount] = settlement.naverPayAmount
                it[cancelledAmount] = settlement.cancelledAmount
                it[cancelledCount] = settlement.cancelledCount
            }[SettlementTable.id]
            settlement.copy(id = id)
        }
    }

    override suspend fun close(date: LocalDate): Boolean = dbQuery {
        SettlementTable.update({ SettlementTable.date eq date }) {
            it[isClosed] = true
            it[closedAt] = LocalDateTime.now()
        } > 0
    }

    private fun ResultRow.toSettlement() = Settlement(
        id = this[SettlementTable.id],
        date = this[SettlementTable.date],
        totalRevenue = this[SettlementTable.totalRevenue],
        totalOrders = this[SettlementTable.totalOrders],
        cardAmount = this[SettlementTable.cardAmount],
        cashAmount = this[SettlementTable.cashAmount],
        kakaoPayAmount = this[SettlementTable.kakaoPayAmount],
        naverPayAmount = this[SettlementTable.naverPayAmount],
        cancelledAmount = this[SettlementTable.cancelledAmount],
        cancelledCount = this[SettlementTable.cancelledCount],
        isClosed = this[SettlementTable.isClosed],
        closedAt = this[SettlementTable.closedAt]
    )
}
