package com.kiosk.application

import com.kiosk.domain.model.Category
import com.kiosk.domain.model.*
import com.kiosk.domain.repository.CategoryRepository

class CategoryUseCase(private val categoryRepository: CategoryRepository) {

    suspend fun getCategories(): List<Category> =
        categoryRepository.findAll()

    suspend fun createCategory(name: String, displayOrder: Int = 0): Category =
        categoryRepository.create(Category(name = name, displayOrder = displayOrder))

    suspend fun updateCategory(id: Long, name: String, displayOrder: Int): Category {
        categoryRepository.findById(id)
            ?: throw AppException.NotFound("카테고리를 찾을 수 없습니다: $id")
        return categoryRepository.update(Category(id = id, name = name, displayOrder = displayOrder))
            ?: throw AppException.NotFound("카테고리 수정 실패")
    }

    suspend fun deleteCategory(id: Long) {
        categoryRepository.findById(id)
            ?: throw AppException.NotFound("카테고리를 찾을 수 없습니다: $id")
        categoryRepository.delete(id)
    }
}
