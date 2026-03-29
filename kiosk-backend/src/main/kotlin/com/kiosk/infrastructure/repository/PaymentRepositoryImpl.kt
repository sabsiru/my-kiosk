package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.PaymentRepository
import com.kiosk.infrastructure.db.PaymentTable
import com.kiosk.infrastructure.db.storeDbQuery
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction

class PaymentRepositoryImpl : PaymentRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun create(payment: Payment): Payment = dbQuery {
        val id = PaymentTable.insert {
            it[orderId] = payment.orderId
            it[method] = payment.method.name
            it[amount] = payment.amount
            it[status] = payment.status.name
            it[approvalNumber] = payment.approvalNumber
            it[pgTransactionId] = payment.pgTransactionId
            it[createdAt] = payment.createdAt
        }[PaymentTable.id]
        payment.copy(id = id)
    }

    override suspend fun findById(id: Long): Payment? = dbQuery {
        PaymentTable.select { PaymentTable.id eq id }
            .map { it.toPayment() }
            .singleOrNull()
    }

    override suspend fun findByOrderId(orderId: Long): Payment? = dbQuery {
        PaymentTable.select { PaymentTable.orderId eq orderId }
            .map { it.toPayment() }
            .singleOrNull()
    }

    override suspend fun updateStatus(
        id: Long,
        status: PaymentStatus,
        approvalNumber: String?,
        pgTransactionId: String?
    ): Boolean = dbQuery {
        PaymentTable.update({ PaymentTable.id eq id }) {
            it[PaymentTable.status] = status.name
            approvalNumber?.let { num -> it[PaymentTable.approvalNumber] = num }
            pgTransactionId?.let { txn -> it[PaymentTable.pgTransactionId] = txn }
        } > 0
    }

    private fun ResultRow.toPayment() = Payment(
        id = this[PaymentTable.id],
        orderId = this[PaymentTable.orderId],
        method = PaymentMethod.valueOf(this[PaymentTable.method]),
        amount = this[PaymentTable.amount],
        status = PaymentStatus.valueOf(this[PaymentTable.status]),
        approvalNumber = this[PaymentTable.approvalNumber],
        pgTransactionId = this[PaymentTable.pgTransactionId],
        createdAt = this[PaymentTable.createdAt]
    )
}
