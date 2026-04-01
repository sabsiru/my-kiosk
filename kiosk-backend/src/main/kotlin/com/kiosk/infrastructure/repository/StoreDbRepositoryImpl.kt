package com.kiosk.infrastructure.repository

import com.kiosk.domain.repository.StoreDbRepository
import com.kiosk.infrastructure.db.DatabaseFactory

class StoreDbRepositoryImpl : StoreDbRepository {
    override fun createStoreDb(storeId: Long) {
        DatabaseFactory.createStoreDb(storeId)
    }
}
