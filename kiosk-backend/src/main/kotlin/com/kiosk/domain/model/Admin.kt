package com.kiosk.domain.model

data class Admin(
    val id: Long = 0,
    val username: String,
    val passwordHash: String,
    val name: String,
    val role: AdminRole = AdminRole.STORE_MANAGER,
    val storeId: Long? = null
)

enum class AdminRole {
    HQ_ADMIN,
    STORE_OWNER,
    STORE_MANAGER
}
