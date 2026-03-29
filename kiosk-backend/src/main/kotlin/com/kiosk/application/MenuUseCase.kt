package com.kiosk.application

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.MenuRepository

class MenuUseCase(private val menuRepository: MenuRepository) {

    suspend fun getCategories(): List<Category> =
        menuRepository.findAllCategories()

    suspend fun getMenusByCategory(categoryId: Long): List<Menu> =
        menuRepository.findMenusByCategory(categoryId)

    suspend fun getMenuDetail(menuId: Long): MenuWithOptions =
        menuRepository.findMenuWithOptions(menuId)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $menuId")

    suspend fun createCategory(name: String, displayOrder: Int = 0): Category =
        menuRepository.createCategory(Category(name = name, displayOrder = displayOrder))

    suspend fun updateCategory(id: Long, name: String, displayOrder: Int): Category {
        menuRepository.findCategoryById(id)
            ?: throw AppException.NotFound("카테고리를 찾을 수 없습니다: $id")
        return menuRepository.updateCategory(Category(id = id, name = name, displayOrder = displayOrder))
            ?: throw AppException.NotFound("카테고리 수정 실패")
    }

    suspend fun deleteCategory(id: Long) {
        menuRepository.findCategoryById(id)
            ?: throw AppException.NotFound("카테고리를 찾을 수 없습니다: $id")
        menuRepository.deleteCategory(id)
    }

    suspend fun createMenu(
        categoryId: Long,
        name: String,
        description: String,
        price: Int,
        imageUrl: String?,
        displayOrder: Int = 0
    ): Menu {
        if (price < 0) throw AppException.BadRequest("가격은 0 이상이어야 합니다")
        menuRepository.findCategoryById(categoryId)
            ?: throw AppException.NotFound("카테고리를 찾을 수 없습니다: $categoryId")
        return menuRepository.createMenu(
            Menu(
                categoryId = categoryId,
                name = name,
                description = description,
                price = price,
                imageUrl = imageUrl,
                displayOrder = displayOrder
            )
        )
    }

    suspend fun updateMenu(
        id: Long,
        categoryId: Long,
        name: String,
        description: String,
        price: Int,
        imageUrl: String?,
        displayOrder: Int
    ): Menu {
        if (price < 0) throw AppException.BadRequest("가격은 0 이상이어야 합니다")
        menuRepository.findMenuById(id)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $id")
        return menuRepository.updateMenu(
            Menu(
                id = id,
                categoryId = categoryId,
                name = name,
                description = description,
                price = price,
                imageUrl = imageUrl,
                displayOrder = displayOrder
            )
        ) ?: throw AppException.NotFound("메뉴 수정 실패")
    }

    suspend fun deleteMenu(id: Long) {
        menuRepository.findMenuById(id)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $id")
        menuRepository.deleteMenu(id)
    }

    suspend fun toggleSoldOut(id: Long): Boolean {
        val menu = menuRepository.findMenuById(id)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $id")
        val newSoldOut = !menu.isSoldOut
        menuRepository.updateSoldOut(id, newSoldOut)
        return newSoldOut
    }
}
