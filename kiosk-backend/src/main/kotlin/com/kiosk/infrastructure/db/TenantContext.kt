package com.kiosk.infrastructure.db

import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction

object TenantContext {
    private val currentStoreId = ThreadLocal<Long>()

    fun set(storeId: Long) = currentStoreId.set(storeId)
    fun get(): Long = currentStoreId.get() ?: throw IllegalStateException("Tenant store ID not set")
    fun getOrNull(): Long? = currentStoreId.get()
    fun clear() = currentStoreId.remove()
}

suspend fun <T> storeDbQuery(block: suspend () -> T): T {
    val storeId = TenantContext.get()
    val db = DatabaseFactory.getStoreDatabase(storeId)
    return newSuspendedTransaction(db = db) { block() }
}
