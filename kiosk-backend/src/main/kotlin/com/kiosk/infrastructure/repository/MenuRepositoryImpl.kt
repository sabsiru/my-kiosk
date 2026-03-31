package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.MenuRepository
import com.kiosk.infrastructure.db.*
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction

class MenuRepositoryImpl : MenuRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun findAllCategories(): List<Category> = dbQuery {
        CategoryTable.select { CategoryTable.isActive eq true }
            .orderBy(CategoryTable.displayOrder)
            .map { it.toCategory() }
    }

    override suspend fun findCategoryById(id: Long): Category? = dbQuery {
        CategoryTable.select { CategoryTable.id eq id }
            .map { it.toCategory() }
            .singleOrNull()
    }

    override suspend fun createCategory(category: Category): Category = dbQuery {
        val id = CategoryTable.insert {
            it[name] = category.name
            it[displayOrder] = category.displayOrder
            it[isActive] = category.isActive
        }[CategoryTable.id]
        category.copy(id = id)
    }

    override suspend fun updateCategory(category: Category): Category? = dbQuery {
        val updated = CategoryTable.update({ CategoryTable.id eq category.id }) {
            it[name] = category.name
            it[displayOrder] = category.displayOrder
            it[isActive] = category.isActive
        }
        if (updated > 0) category else null
    }

    override suspend fun deleteCategory(id: Long): Boolean = dbQuery {
        CategoryTable.update({ CategoryTable.id eq id }) {
            it[isActive] = false
        } > 0
    }

    override suspend fun findAllMenus(): List<Menu> = dbQuery {
        MenuTable.select { MenuTable.isActive eq true }
            .map { it.toMenu() }
    }

    override suspend fun findMenusByCategory(categoryId: Long): List<Menu> = dbQuery {
        MenuTable.select { (MenuTable.categoryId eq categoryId) and (MenuTable.isActive eq true) }
            .orderBy(MenuTable.displayOrder)
            .map { it.toMenu() }
    }

    override suspend fun findMenuById(id: Long): Menu? = dbQuery {
        MenuTable.select { MenuTable.id eq id }
            .map { it.toMenu() }
            .singleOrNull()
    }

    override suspend fun findMenuWithOptions(id: Long): MenuWithOptions? = dbQuery {
        val menu = MenuTable.select { MenuTable.id eq id }
            .map { it.toMenu() }
            .singleOrNull() ?: return@dbQuery null

        val options = findOptionsByMenuIdInternal(id)
        MenuWithOptions(menu, options)
    }

    override suspend fun createMenu(menu: Menu): Menu = dbQuery {
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

    override suspend fun updateMenu(menu: Menu): Menu? = dbQuery {
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

    override suspend fun deleteMenu(id: Long): Boolean = dbQuery {
        MenuTable.update({ MenuTable.id eq id }) {
            it[isActive] = false
        } > 0
    }

    override suspend fun updateSoldOut(id: Long, isSoldOut: Boolean): Boolean = dbQuery {
        MenuTable.update({ MenuTable.id eq id }) {
            it[MenuTable.isSoldOut] = isSoldOut
        } > 0
    }

    override suspend fun createMenuOption(option: MenuOption): MenuOption = dbQuery {
        val id = MenuOptionTable.insert {
            it[menuId] = option.menuId
            it[name] = option.name
            it[isRequired] = option.isRequired
            it[maxSelection] = option.maxSelection
        }[MenuOptionTable.id]
        option.copy(id = id)
    }

    override suspend fun createMenuOptionItem(item: MenuOptionItem): MenuOptionItem = dbQuery {
        val id = MenuOptionItemTable.insert {
            it[optionId] = item.optionId
            it[name] = item.name
            it[additionalPrice] = item.additionalPrice
        }[MenuOptionItemTable.id]
        item.copy(id = id)
    }

    override suspend fun findOptionsByMenuId(menuId: Long): List<MenuOptionWithItems> = dbQuery {
        findOptionsByMenuIdInternal(menuId)
    }

    override suspend fun deleteOptionsByMenuId(menuId: Long): Boolean = dbQuery {
        val optionIds = MenuOptionTable.select { MenuOptionTable.menuId eq menuId }
            .map { it[MenuOptionTable.id] }

        optionIds.forEach { optionId ->
            MenuOptionItemTable.deleteWhere { MenuOptionItemTable.optionId eq optionId }
        }
        MenuOptionTable.deleteWhere { MenuOptionTable.menuId eq menuId }
        true
    }

    private fun findOptionsByMenuIdInternal(menuId: Long): List<MenuOptionWithItems> {
        val options = MenuOptionTable.select { MenuOptionTable.menuId eq menuId }
            .map { it.toMenuOption() }

        return options.map { option ->
            val items = MenuOptionItemTable.select { MenuOptionItemTable.optionId eq option.id }
                .map { it.toMenuOptionItem() }
            MenuOptionWithItems(option, items)
        }
    }

    private fun ResultRow.toCategory() = Category(
        id = this[CategoryTable.id],
        name = this[CategoryTable.name],
        displayOrder = this[CategoryTable.displayOrder],
        isActive = this[CategoryTable.isActive]
    )

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
