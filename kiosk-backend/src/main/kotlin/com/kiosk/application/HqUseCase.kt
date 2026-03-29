package com.kiosk.application

import com.kiosk.domain.model.AppException
import com.kiosk.domain.model.HqStore
import com.kiosk.domain.model.StoreStatus
import com.kiosk.domain.repository.HqStoreRepository
import com.kiosk.infrastructure.db.DatabaseFactory
import java.time.LocalDateTime

class HqUseCase(private val hqStoreRepository: HqStoreRepository) {

    suspend fun getStores(): List<HqStore> =
        hqStoreRepository.findAll()

    suspend fun getStore(id: Long): HqStore =
        hqStoreRepository.findById(id)
            ?: throw AppException.NotFound("매장을 찾을 수 없습니다: $id")

    suspend fun createStore(name: String, code: String): HqStore {
        // 1) 임시 dbName으로 생성 (auto-increment ID 확보)
        val store = hqStoreRepository.create(
            HqStore(
                name = name,
                code = code,
                dbName = "pending",
                status = StoreStatus.ACTIVE,
                createdAt = LocalDateTime.now()
            )
        )

        // 2) auto-increment ID 기반 dbName으로 업데이트
        val dbName = "kiosk_store_${store.id}"
        val updated = hqStoreRepository.update(store.copy(dbName = dbName))

        // 3) 매장 DB 스키마 생성
        DatabaseFactory.createStoreDb(updated.id)

        return updated
    }

    suspend fun updateStore(id: Long, name: String, code: String, status: StoreStatus): HqStore {
        val existing = hqStoreRepository.findById(id)
            ?: throw AppException.NotFound("매장을 찾을 수 없습니다: $id")

        return hqStoreRepository.update(
            existing.copy(name = name, code = code, status = status)
        )
    }

    suspend fun deleteStore(id: Long) {
        hqStoreRepository.findById(id)
            ?: throw AppException.NotFound("매장을 찾을 수 없습니다: $id")
        hqStoreRepository.delete(id)
    }
}
