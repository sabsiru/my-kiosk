package com.kiosk.domain.repository

import com.kiosk.domain.model.HqStore

interface HqStoreRepository {
    suspend fun findAll(): List<HqStore>
    suspend fun findById(id: Long): HqStore?
    suspend fun create(store: HqStore): HqStore
    suspend fun update(store: HqStore): HqStore
    suspend fun delete(id: Long)
}
