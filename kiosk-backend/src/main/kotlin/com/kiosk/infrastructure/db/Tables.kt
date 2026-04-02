package com.kiosk.infrastructure.db

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.javatime.date
import org.jetbrains.exposed.sql.javatime.datetime
import org.jetbrains.exposed.sql.javatime.time

object CategoryTable : Table("categories") {
    val id = long("id").autoIncrement()
    val name = varchar("name", 100)
    val displayOrder = integer("display_order").default(0)
    val isActive = bool("is_active").default(true)
    override val primaryKey = PrimaryKey(id)
}

object MenuTable : Table("menus") {
    val id = long("id").autoIncrement()
    val categoryId = long("category_id")
    val name = varchar("name", 200)
    val description = varchar("description", 500).default("")
    val price = integer("price")
    val imageUrl = varchar("image_url", 500).nullable()
    val isSoldOut = bool("is_sold_out").default(false)
    val isActive = bool("is_active").default(true)
    val displayOrder = integer("display_order").default(0)
    override val primaryKey = PrimaryKey(id)

    init {
        index(false, categoryId)
    }
}

object MenuOptionTable : Table("menu_options") {
    val id = long("id").autoIncrement()
    val menuId = long("menu_id")
    val name = varchar("name", 100)
    val isRequired = bool("is_required").default(false)
    val maxSelection = integer("max_selection").default(1)
    override val primaryKey = PrimaryKey(id)
}

object MenuOptionItemTable : Table("menu_option_items") {
    val id = long("id").autoIncrement()
    val optionId = long("option_id")
    val name = varchar("name", 100)
    val additionalPrice = integer("additional_price").default(0)
    override val primaryKey = PrimaryKey(id)
}

object KioskTableTable : Table("kiosk_tables") {
    val id = long("id").autoIncrement()
    val tableNumber = integer("table_number").uniqueIndex()
    val deviceId = varchar("device_id", 100).nullable()
    val status = varchar("status", 20).default("AVAILABLE")
    val isActive = bool("is_active").default(true)
    override val primaryKey = PrimaryKey(id)
}

object OrderTable : Table("orders") {
    val id = long("id").autoIncrement()
    val orderNumber = varchar("order_number", 20).uniqueIndex()
    val tableId = long("table_id").nullable()
    val status = varchar("status", 20).default("PENDING")
    val totalAmount = integer("total_amount")
    val createdAt = datetime("created_at")
    val updatedAt = datetime("updated_at")
    override val primaryKey = PrimaryKey(id)

    init {
        index(false, status)
    }
}

object OrderItemTable : Table("order_items") {
    val id = long("id").autoIncrement()
    val orderId = long("order_id")
    val menuId = long("menu_id")
    val menuName = varchar("menu_name", 200)
    val quantity = integer("quantity")
    val unitPrice = integer("unit_price")
    val totalPrice = integer("total_price")
    val selectedOptions = varchar("selected_options", 1000).default("")
    override val primaryKey = PrimaryKey(id)

    init {
        index(false, menuId)
    }
}

object PaymentTable : Table("payments") {
    val id = long("id").autoIncrement()
    val orderId = long("order_id")
    val method = varchar("method", 20)
    val amount = integer("amount")
    val status = varchar("status", 20).default("PENDING")
    val approvalNumber = varchar("approval_number", 50).nullable()
    val pgTransactionId = varchar("pg_transaction_id", 100).nullable()
    val createdAt = datetime("created_at")
    override val primaryKey = PrimaryKey(id)

    init {
        index(false, status)
    }
}

object SettlementTable : Table("settlements") {
    val id = long("id").autoIncrement()
    val date = date("date").uniqueIndex()
    val totalRevenue = integer("total_revenue")
    val totalOrders = integer("total_orders")
    val cardAmount = integer("card_amount").default(0)
    val cashAmount = integer("cash_amount").default(0)
    val kakaoPayAmount = integer("kakao_pay_amount").default(0)
    val naverPayAmount = integer("naver_pay_amount").default(0)
    val cancelledAmount = integer("cancelled_amount").default(0)
    val cancelledCount = integer("cancelled_count").default(0)
    val isClosed = bool("is_closed").default(false)
    val closedAt = datetime("closed_at").nullable()
    override val primaryKey = PrimaryKey(id)
}

object StoreTable : Table("store_settings") {
    val id = long("id").autoIncrement()
    val name = varchar("name", 200)
    val openTime = time("open_time")
    val closeTime = time("close_time")
    val isOpen = bool("is_open").default(false)
    val hideAdminButton = bool("hide_admin_button").default(false)
    override val primaryKey = PrimaryKey(id)
}
