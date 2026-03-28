package com.kiosk.infrastructure.db

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.javatime.datetime

object HqStoreTable : Table("stores") {
    val id = long("id").autoIncrement()
    val name = varchar("name", 100)
    val code = varchar("code", 50).uniqueIndex()
    val dbName = varchar("db_name", 100).uniqueIndex()
    val status = varchar("status", 20).default("ACTIVE")
    val createdAt = datetime("created_at")
    override val primaryKey = PrimaryKey(id)
}

object HqAdminTable : Table("admins") {
    val id = long("id").autoIncrement()
    val username = varchar("username", 50).uniqueIndex()
    val passwordHash = varchar("password_hash", 200)
    val name = varchar("name", 100)
    val role = varchar("role", 20).default("STORE_MANAGER")
    val storeId = long("store_id").nullable()
    override val primaryKey = PrimaryKey(id)
}
