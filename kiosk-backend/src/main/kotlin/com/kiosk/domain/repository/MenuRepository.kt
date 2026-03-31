package com.kiosk.domain.repository

import com.kiosk.domain.model.*

interface MenuRepository {
    suspend fun findAllCategories(): List<Category>
    suspend fun findCategoryById(id: Long): Category?
    suspend fun createCategory(category: Category): Category
    suspend fun updateCategory(category: Category): Category?
    suspend fun deleteCategory(id: Long): Boolean

    suspend fun findAllMenus(): List<Menu>
    suspend fun findMenusByCategory(categoryId: Long): List<Menu>
    suspend fun findMenuById(id: Long): Menu?
    suspend fun findMenuWithOptions(id: Long): MenuWithOptions?
    suspend fun createMenu(menu: Menu): Menu
    suspend fun updateMenu(menu: Menu): Menu?
    suspend fun deleteMenu(id: Long): Boolean
    suspend fun updateSoldOut(id: Long, isSoldOut: Boolean): Boolean

    suspend fun createMenuOption(option: MenuOption): MenuOption
    suspend fun createMenuOptionItem(item: MenuOptionItem): MenuOptionItem
    suspend fun findOptionsByMenuId(menuId: Long): List<MenuOptionWithItems>
    suspend fun deleteOptionsByMenuId(menuId: Long): Boolean
}
