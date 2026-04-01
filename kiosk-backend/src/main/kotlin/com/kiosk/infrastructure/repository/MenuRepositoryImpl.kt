package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.MenuRepository
import com.kiosk.infrastructure.db.*
import org.jetbrains.exposed.sql.*

class MenuRepositoryImpl : MenuRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun findAll(): List<Menu> = dbQuery {
        MenuTable.select { MenuTable.isActive eq true }
            .map { it.toMenu() }
    }

    override suspend fun findByCategory(categoryId: Long): List<Menu> = dbQuery {
        MenuTable.select { (MenuTable.categoryId eq categoryId) and (MenuTable.isActive eq true) }
            .orderBy(MenuTable.displayOrder)
            .map { it.toMenu() }
    }

    override suspend fun findById(id: Long): Menu? = dbQuery {
        MenuTable.select { MenuTable.id eq id }
            .map { it.toMenu() }
            .singleOrNull()
    }

    override suspend fun findWithOptions(id: Long): MenuWithOptions? = dbQuery {
        val menu = MenuTable.select { MenuTable.id eq id }
            .map { it.toMenu() }
            .singleOrNull() ?: return@dbQuery null

        val options = MenuOptionTable.select { MenuOptionTable.menuId eq id }
            .map { it.toMenuOption() }
            .map { option ->
                val items = MenuOptionItemTable.select { MenuOptionItemTable.optionId eq option.id }
                    .map { it.toMenuOptionItem() }
                MenuOptionWithItems(option, items)
            }

        MenuWithOptions(menu, options)
    }

    override suspend fun create(menu: Menu): Menu = dbQuery {
        val id = MenuTable.insert {
            it[categoryId] = menu.categoryId
            it[name] = menu.name
            it[description] = menu.description
            it[price] = menu.price
            it[imageUrl] = menu.imageUrl
            it[isSoldOut] = menu.isSoldOut
            it[isActive] = menu.isActive
            it[displayOrder] = menu.displayOrder
        }[MenuTable.id]
        menu.copy(id = id)
    }

    override suspend fun update(menu: Menu): Menu? = dbQuery {
        val updated = MenuTable.update({ MenuTable.id eq menu.id }) {
            it[categoryId] = menu.categoryId
            it[name] = menu.name
            it[description] = menu.description
            it[price] = menu.price
            it[imageUrl] = menu.imageUrl
            it[isSoldOut] = menu.isSoldOut
            it[displayOrder] = menu.displayOrder
        }
        if (updated > 0) menu else null
    }

    override suspend fun delete(id: Long): Boolean = dbQuery {
        MenuTable.update({ MenuTable.id eq id }) {
            it[isActive] = false
        } > 0
    }

    override suspend fun updateSoldOut(id: Long, isSoldOut: Boolean): Boolean = dbQuery {
        MenuTable.update({ MenuTable.id eq id }) {
            it[MenuTable.isSoldOut] = isSoldOut
        } > 0
    }

    private fun ResultRow.toMenu() = Menu(
        id = this[MenuTable.id],
        categoryId = this[MenuTable.categoryId],
        name = this[MenuTable.name],
        description = this[MenuTable.description],
        price = this[MenuTable.price],
        imageUrl = this[MenuTable.imageUrl],
        isSoldOut = this[MenuTable.isSoldOut],
        isActive = this[MenuTable.isActive],
        displayOrder = this[MenuTable.displayOrder]
    )

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
