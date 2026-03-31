package com.kiosk.domain.repository

import com.kiosk.domain.model.Admin

interface AdminRepository {
    suspend fun findByUsername(username: String): Admin?
    suspend fun findById(id: Long): Admin?
    suspend fun findAll(): List<Admin>
    suspend fun findByStoreId(storeId: Long): List<Admin>
    suspend fun create(admin: Admin): Admin
    suspend fun update(admin: Admin): Admin
    suspend fun delete(id: Long)
}
