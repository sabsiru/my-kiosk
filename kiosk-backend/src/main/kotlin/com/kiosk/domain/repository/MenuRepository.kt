package com.kiosk.domain.repository

import com.kiosk.domain.model.*

interface MenuRepository {
    suspend fun findAll(): List<Menu>
    suspend fun findByCategory(categoryId: Long): List<Menu>
    suspend fun findById(id: Long): Menu?
    suspend fun findWithOptions(id: Long): MenuWithOptions?
    suspend fun create(menu: Menu): Menu
    suspend fun update(menu: Menu): Menu?
    suspend fun delete(id: Long): Boolean
    suspend fun updateSoldOut(id: Long, isSoldOut: Boolean): Boolean
}
