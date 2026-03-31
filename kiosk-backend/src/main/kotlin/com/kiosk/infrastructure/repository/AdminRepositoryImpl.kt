package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.Admin
import com.kiosk.domain.model.AdminRole
import com.kiosk.domain.repository.AdminRepository
import com.kiosk.infrastructure.db.DatabaseFactory
import com.kiosk.infrastructure.db.HqAdminTable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction

class AdminRepositoryImpl : AdminRepository {

    private suspend fun <T> hqQuery(block: suspend () -> T): T =
        newSuspendedTransaction(db = DatabaseFactory.getHqDatabase()) { block() }

    override suspend fun findByUsername(username: String): Admin? = hqQuery {
        HqAdminTable.select { HqAdminTable.username eq username }
            .map { it.toAdmin() }
            .singleOrNull()
    }

    override suspend fun findById(id: Long): Admin? = hqQuery {
        HqAdminTable.select { HqAdminTable.id eq id }
            .map { it.toAdmin() }
            .singleOrNull()
    }

    override suspend fun findAll(): List<Admin> = hqQuery {
        HqAdminTable.selectAll()
            .map { it.toAdmin() }
    }

    override suspend fun findByStoreId(storeId: Long): List<Admin> = hqQuery {
        HqAdminTable.select { HqAdminTable.storeId eq storeId }
            .map { it.toAdmin() }
    }

    override suspend fun create(admin: Admin): Admin = hqQuery {
        val id = HqAdminTable.insert {
            it[username] = admin.username
            it[passwordHash] = admin.passwordHash
            it[name] = admin.name
            it[role] = admin.role.name
            it[storeId] = admin.storeId
        }[HqAdminTable.id]
        admin.copy(id = id)
    }

    override suspend fun update(admin: Admin): Admin = hqQuery {
        HqAdminTable.update({ HqAdminTable.id eq admin.id }) {
            it[username] = admin.username
            it[passwordHash] = admin.passwordHash
            it[name] = admin.name
            it[role] = admin.role.name
            it[storeId] = admin.storeId
        }
        admin
    }

    @Suppress("PARAMETER_NAME_CHANGED_ON_OVERRIDE")
    override suspend fun delete(id: Long): Unit = hqQuery {
        HqAdminTable.deleteWhere { HqAdminTable.id eq id }
    }

    private fun ResultRow.toAdmin() = Admin(
        id = this[HqAdminTable.id],
        username = this[HqAdminTable.username],
        passwordHash = this[HqAdminTable.passwordHash],
        name = this[HqAdminTable.name],
        role = AdminRole.valueOf(this[HqAdminTable.role]),
        storeId = this[HqAdminTable.storeId]
    )
}
