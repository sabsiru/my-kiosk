package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.HqStore
import com.kiosk.domain.model.StoreStatus
import com.kiosk.domain.repository.HqStoreRepository
import com.kiosk.infrastructure.db.DatabaseFactory
import com.kiosk.infrastructure.db.HqStoreTable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction

class HqStoreRepositoryImpl : HqStoreRepository {

    private suspend fun <T> hqQuery(block: suspend () -> T): T =
        newSuspendedTransaction(db = DatabaseFactory.getHqDatabase()) { block() }

    override suspend fun findAll(): List<HqStore> = hqQuery {
        HqStoreTable.selectAll()
            .map { it.toHqStore() }
    }

    override suspend fun findById(id: Long): HqStore? = hqQuery {
        HqStoreTable.select { HqStoreTable.id eq id }
            .map { it.toHqStore() }
            .singleOrNull()
    }

    override suspend fun create(store: HqStore): HqStore = hqQuery {
        val id = HqStoreTable.insert {
            it[name] = store.name
            it[code] = store.code
            it[dbName] = store.dbName
            it[status] = store.status.name
            it[createdAt] = store.createdAt
        }[HqStoreTable.id]
        store.copy(id = id)
    }

    override suspend fun update(store: HqStore): HqStore = hqQuery {
        HqStoreTable.update({ HqStoreTable.id eq store.id }) {
            it[name] = store.name
            it[code] = store.code
            it[status] = store.status.name
        }
        store
    }

    override suspend fun delete(id: Long): Unit = hqQuery {
        HqStoreTable.deleteWhere { HqStoreTable.id eq id }
    }

    private fun ResultRow.toHqStore() = HqStore(
        id = this[HqStoreTable.id],
        name = this[HqStoreTable.name],
        code = this[HqStoreTable.code],
        dbName = this[HqStoreTable.dbName],
        status = StoreStatus.valueOf(this[HqStoreTable.status]),
        createdAt = this[HqStoreTable.createdAt]
    )
}
