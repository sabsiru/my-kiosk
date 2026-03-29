package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.KioskTable
import com.kiosk.domain.model.TableStatus
import com.kiosk.domain.repository.TableRepository
import com.kiosk.infrastructure.db.KioskTableTable
import com.kiosk.infrastructure.db.storeDbQuery
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction

class TableRepositoryImpl : TableRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun findAll(): List<KioskTable> = dbQuery {
        KioskTableTable.select { KioskTableTable.isActive eq true }
            .orderBy(KioskTableTable.tableNumber)
            .map { it.toKioskTable() }
    }

    override suspend fun findById(id: Long): KioskTable? = dbQuery {
        KioskTableTable.select { KioskTableTable.id eq id }
            .map { it.toKioskTable() }
            .singleOrNull()
    }

    override suspend fun findByTableNumber(tableNumber: Int): KioskTable? = dbQuery {
        KioskTableTable.select { KioskTableTable.tableNumber eq tableNumber }
            .map { it.toKioskTable() }
            .singleOrNull()
    }

    override suspend fun create(table: KioskTable): KioskTable = dbQuery {
        val id = KioskTableTable.insert {
            it[tableNumber] = table.tableNumber
            it[deviceId] = table.deviceId
            it[status] = table.status.name
            it[isActive] = table.isActive
        }[KioskTableTable.id]
        table.copy(id = id)
    }

    override suspend fun update(table: KioskTable): KioskTable? = dbQuery {
        val updated = KioskTableTable.update({ KioskTableTable.id eq table.id }) {
            it[tableNumber] = table.tableNumber
            it[deviceId] = table.deviceId
            it[status] = table.status.name
        }
        if (updated > 0) table else null
    }

    override suspend fun delete(id: Long): Boolean = dbQuery {
        KioskTableTable.update({ KioskTableTable.id eq id }) {
            it[isActive] = false
        } > 0
    }

    override suspend fun updateStatus(id: Long, status: TableStatus): Boolean = dbQuery {
        KioskTableTable.update({ KioskTableTable.id eq id }) {
            it[KioskTableTable.status] = status.name
        } > 0
    }

    override suspend fun resetAllStatus(): Int = dbQuery {
        KioskTableTable.update({ KioskTableTable.isActive eq true }) {
            it[status] = TableStatus.AVAILABLE.name
        }
    }

    override suspend fun findPendingOrderTableIds(): List<Long> = dbQuery {
        KioskTableTable.select { KioskTableTable.isActive eq true }
            .map { it[KioskTableTable.id] }
    }

    private fun ResultRow.toKioskTable() = KioskTable(
        id = this[KioskTableTable.id],
        tableNumber = this[KioskTableTable.tableNumber],
        deviceId = this[KioskTableTable.deviceId],
        status = TableStatus.valueOf(this[KioskTableTable.status]),
        isActive = this[KioskTableTable.isActive]
    )
}
