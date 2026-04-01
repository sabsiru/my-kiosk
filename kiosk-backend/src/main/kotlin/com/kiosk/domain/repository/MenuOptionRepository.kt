package com.kiosk.domain.repository

import com.kiosk.domain.model.MenuOption
import com.kiosk.domain.model.MenuOptionItem
import com.kiosk.domain.model.MenuOptionWithItems

interface MenuOptionRepository {
    suspend fun create(option: MenuOption): MenuOption
    suspend fun createItem(item: MenuOptionItem): MenuOptionItem
    suspend fun findByMenuId(menuId: Long): List<MenuOptionWithItems>
    suspend fun deleteByMenuId(menuId: Long): Boolean
}
