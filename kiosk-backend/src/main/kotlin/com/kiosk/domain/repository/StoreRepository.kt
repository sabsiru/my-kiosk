package com.kiosk.domain.repository

import com.kiosk.domain.model.Store

interface StoreRepository {
    suspend fun get(): Store
    suspend fun update(store: Store): Store
}
