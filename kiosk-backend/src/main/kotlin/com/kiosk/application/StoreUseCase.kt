package com.kiosk.application

import com.kiosk.domain.model.Store
import com.kiosk.domain.repository.StoreRepository
import com.kiosk.domain.repository.TableRepository
import java.time.LocalTime

class StoreUseCase(
    private val storeRepository: StoreRepository,
    private val tableRepository: TableRepository
) {

    suspend fun getStore(): Store =
        storeRepository.get()

    suspend fun updateStore(
        name: String, openTime: LocalTime, closeTime: LocalTime,
        isOpen: Boolean, hideAdminButton: Boolean
    ): Store {
        val store = storeRepository.get()
        return storeRepository.update(
            store.copy(
                name = name, openTime = openTime, closeTime = closeTime,
                isOpen = isOpen, hideAdminButton = hideAdminButton
            )
        )
    }

    suspend fun openStore(): Store {
        val store = storeRepository.get()
        tableRepository.resetAllStatus()
        return storeRepository.update(store.copy(isOpen = true))
    }

    suspend fun closeStore(): Store {
        val store = storeRepository.get()
        return storeRepository.update(store.copy(isOpen = false))
    }
}
