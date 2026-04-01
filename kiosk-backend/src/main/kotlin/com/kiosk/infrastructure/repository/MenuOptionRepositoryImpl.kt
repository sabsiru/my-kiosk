package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.MenuOption
import com.kiosk.domain.model.MenuOptionItem
import com.kiosk.domain.model.MenuOptionWithItems
import com.kiosk.domain.repository.MenuOptionRepository
import com.kiosk.infrastructure.db.MenuOptionItemTable
import com.kiosk.infrastructure.db.MenuOptionTable
import com.kiosk.infrastructure.db.storeDbQuery
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq

class MenuOptionRepositoryImpl : MenuOptionRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun create(option: MenuOption): MenuOption = dbQuery {
        val id = MenuOptionTable.insert {
            it[menuId] = option.menuId
            it[name] = option.name
            it[isRequired] = option.isRequired
            it[maxSelection] = option.maxSelection
        }[MenuOptionTable.id]
        option.copy(id = id)
    }

    override suspend fun createItem(item: MenuOptionItem): MenuOptionItem = dbQuery {
        val id = MenuOptionItemTable.insert {
            it[optionId] = item.optionId
            it[name] = item.name
            it[additionalPrice] = item.additionalPrice
        }[MenuOptionItemTable.id]
        item.copy(id = id)
    }

    override suspend fun findByMenuId(menuId: Long): List<MenuOptionWithItems> = dbQuery {
        val options = MenuOptionTable.select { MenuOptionTable.menuId eq menuId }
            .map { it.toMenuOption() }

        options.map { option ->
            val items = MenuOptionItemTable.select { MenuOptionItemTable.optionId eq option.id }
                .map { it.toMenuOptionItem() }
            MenuOptionWithItems(option, items)
        }
    }

    override suspend fun deleteByMenuId(menuId: Long): Boolean = dbQuery {
        val optionIds = MenuOptionTable.select { MenuOptionTable.menuId eq menuId }
            .map { it[MenuOptionTable.id] }

        optionIds.forEach { optionId ->
            MenuOptionItemTable.deleteWhere { MenuOptionItemTable.optionId eq optionId }
        }
        MenuOptionTable.deleteWhere { MenuOptionTable.menuId eq menuId }
        true
    }

    private fun ResultRow.toMenuOption() = MenuOption(
        id = this[MenuOptionTable.id],
        menuId = this[MenuOptionTable.menuId],
        name = this[MenuOptionTable.name],
        isRequired = this[MenuOptionTable.isRequired],
        maxSelection = this[MenuOptionTable.maxSelection]
    )

    private fun ResultRow.toMenuOptionItem() = MenuOptionItem(
        id = this[MenuOptionItemTable.id],
        optionId = this[MenuOptionItemTable.optionId],
        name = this[MenuOptionItemTable.name],
        additionalPrice = this[MenuOptionItemTable.additionalPrice]
    )
}
