package com.kiosk.domain.repository

import com.kiosk.domain.model.Settlement
import java.time.LocalDate

interface SettlementRepository {
    suspend fun findByDate(date: LocalDate): Settlement?
    suspend fun findByDateRange(from: LocalDate, to: LocalDate): List<Settlement>
    suspend fun createOrUpdate(settlement: Settlement): Settlement
    suspend fun close(date: LocalDate): Boolean
}
