package com.kiosk.application

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.CategoryRepository
import com.kiosk.domain.repository.MenuRepository

class MenuUseCase(
    private val menuRepository: MenuRepository,
    private val categoryRepository: CategoryRepository
) {

    suspend fun getMenusByCategory(categoryId: Long): List<Menu> =
        menuRepository.findByCategory(categoryId)

    suspend fun getMenuDetail(menuId: Long): MenuWithOptions =
        menuRepository.findWithOptions(menuId)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $menuId")

    suspend fun createMenu(
        categoryId: Long,
        name: String,
        description: String,
        price: Int,
        imageUrl: String?,
        displayOrder: Int = 0
    ): Menu {
        if (price < 0) throw AppException.BadRequest("가격은 0 이상이어야 합니다")
        categoryRepository.findById(categoryId)
            ?: throw AppException.NotFound("카테고리를 찾을 수 없습니다: $categoryId")
        return menuRepository.create(
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
        menuRepository.findById(id)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $id")
        return menuRepository.update(
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
        menuRepository.findById(id)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $id")
        menuRepository.delete(id)
    }

    suspend fun toggleSoldOut(id: Long): Boolean {
        val menu = menuRepository.findById(id)
            ?: throw AppException.NotFound("메뉴를 찾을 수 없습니다: $id")
        val newSoldOut = !menu.isSoldOut
        menuRepository.updateSoldOut(id, newSoldOut)
        return newSoldOut
    }
}
