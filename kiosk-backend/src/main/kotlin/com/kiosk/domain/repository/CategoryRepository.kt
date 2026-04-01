package com.kiosk.domain.repository

import com.kiosk.domain.model.Category

interface CategoryRepository {
    suspend fun findAll(): List<Category>
    suspend fun findById(id: Long): Category?
    suspend fun create(category: Category): Category
    suspend fun update(category: Category): Category?
    suspend fun delete(id: Long): Boolean
}
