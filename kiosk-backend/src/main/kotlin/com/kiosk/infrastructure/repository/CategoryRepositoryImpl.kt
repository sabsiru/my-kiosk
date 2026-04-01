package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.Category
import com.kiosk.domain.repository.CategoryRepository
import com.kiosk.infrastructure.db.CategoryTable
import com.kiosk.infrastructure.db.storeDbQuery
import org.jetbrains.exposed.sql.*

class CategoryRepositoryImpl : CategoryRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun findAll(): List<Category> = dbQuery {
        CategoryTable.select { CategoryTable.isActive eq true }
            .orderBy(CategoryTable.displayOrder)
            .map { it.toCategory() }
    }

    override suspend fun findById(id: Long): Category? = dbQuery {
        CategoryTable.select { CategoryTable.id eq id }
            .map { it.toCategory() }
            .singleOrNull()
    }

    override suspend fun create(category: Category): Category = dbQuery {
        val id = CategoryTable.insert {
            it[name] = category.name
            it[displayOrder] = category.displayOrder
            it[isActive] = category.isActive
        }[CategoryTable.id]
        category.copy(id = id)
    }

    override suspend fun update(category: Category): Category? = dbQuery {
        val updated = CategoryTable.update({ CategoryTable.id eq category.id }) {
            it[name] = category.name
            it[displayOrder] = category.displayOrder
            it[isActive] = category.isActive
        }
        if (updated > 0) category else null
    }

    override suspend fun delete(id: Long): Boolean = dbQuery {
        CategoryTable.update({ CategoryTable.id eq id }) {
            it[isActive] = false
        } > 0
    }

    private fun ResultRow.toCategory() = Category(
        id = this[CategoryTable.id],
        name = this[CategoryTable.name],
        displayOrder = this[CategoryTable.displayOrder],
        isActive = this[CategoryTable.isActive]
    )
}
