package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.Store
import com.kiosk.domain.repository.StoreRepository
import com.kiosk.infrastructure.db.StoreTable
import com.kiosk.infrastructure.db.storeDbQuery
import org.jetbrains.exposed.sql.*
import java.time.LocalTime

class StoreRepositoryImpl : StoreRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun get(): Store = dbQuery {
        StoreTable.selectAll()
            .map { it.toStore() }
            .firstOrNull() ?: run {
            val id = StoreTable.insert {
                it[name] = "키오스크 매장"
                it[openTime] = LocalTime.of(9, 0)
                it[closeTime] = LocalTime.of(22, 0)
                it[isOpen] = true
            }[StoreTable.id]
            Store(id = id, name = "키오스크 매장")
        }
    }

    override suspend fun update(store: Store): Store = dbQuery {
        StoreTable.update({ StoreTable.id eq store.id }) {
            it[name] = store.name
            it[openTime] = store.openTime
            it[closeTime] = store.closeTime
            it[isOpen] = store.isOpen
            it[hideAdminButton] = store.hideAdminButton
        }
        store
    }

    private fun ResultRow.toStore() = Store(
        id = this[StoreTable.id],
        name = this[StoreTable.name],
        openTime = this[StoreTable.openTime],
        closeTime = this[StoreTable.closeTime],
        isOpen = this[StoreTable.isOpen],
        hideAdminButton = this[StoreTable.hideAdminButton]
    )
}
