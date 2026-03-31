package com.kiosk.domain.repository

import com.kiosk.domain.model.KioskTable
import com.kiosk.domain.model.TableStatus

interface TableRepository {
    suspend fun findAll(): List<KioskTable>
    suspend fun findById(id: Long): KioskTable?
    suspend fun findByTableNumber(tableNumber: Int): KioskTable?
    suspend fun create(table: KioskTable): KioskTable
    suspend fun update(table: KioskTable): KioskTable?
    suspend fun delete(id: Long): Boolean
    suspend fun updateStatus(id: Long, status: TableStatus): Boolean
    suspend fun resetAllStatus(): Int
    suspend fun findPendingOrderTableIds(): List<Long>
}
