package com.kiosk.infrastructure.repository

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.OrderRepository
import com.kiosk.infrastructure.db.OrderItemTable
import com.kiosk.infrastructure.db.OrderTable
import com.kiosk.infrastructure.db.storeDbQuery
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction
import java.time.LocalDate
import java.time.LocalDateTime

class OrderRepositoryImpl : OrderRepository {

    private suspend fun <T> dbQuery(block: suspend () -> T): T = storeDbQuery(block)

    override suspend fun create(order: Order, items: List<OrderItem>): OrderWithItems = dbQuery {
        val orderId = OrderTable.insert {
            it[orderNumber] = order.orderNumber
            it[tableId] = order.tableId
            it[status] = order.status.name
            it[totalAmount] = order.totalAmount
            it[createdAt] = order.createdAt
            it[updatedAt] = order.updatedAt
        }[OrderTable.id]

        val savedItems = items.map { item ->
            val itemId = OrderItemTable.insert {
                it[OrderItemTable.orderId] = orderId
                it[menuId] = item.menuId
                it[menuName] = item.menuName
                it[quantity] = item.quantity
                it[unitPrice] = item.unitPrice
                it[totalPrice] = item.totalPrice
                it[selectedOptions] = item.selectedOptions
            }[OrderItemTable.id]
            item.copy(id = itemId, orderId = orderId)
        }

        OrderWithItems(order.copy(id = orderId), savedItems)
    }

    override suspend fun findById(id: Long): OrderWithItems? = dbQuery {
        val order = OrderTable.select { OrderTable.id eq id }
            .map { it.toOrder() }
            .singleOrNull() ?: return@dbQuery null

        val items = OrderItemTable.select { OrderItemTable.orderId eq id }
            .map { it.toOrderItem() }

        OrderWithItems(order, items)
    }

    override suspend fun findByOrderNumber(orderNumber: String): OrderWithItems? = dbQuery {
        val order = OrderTable.select { OrderTable.orderNumber eq orderNumber }
            .map { it.toOrder() }
            .singleOrNull() ?: return@dbQuery null

        val items = OrderItemTable.select { OrderItemTable.orderId eq order.id }
            .map { it.toOrderItem() }

        OrderWithItems(order, items)
    }

    override suspend fun findAll(
        status: OrderStatus?,
        tableId: Long?,
        from: LocalDateTime?,
        to: LocalDateTime?,
        limit: Int,
        offset: Int
    ): List<OrderWithItems> = dbQuery {
        val query = OrderTable.selectAll()

        status?.let { s -> query.andWhere { OrderTable.status eq s.name } }
        tableId?.let { t -> query.andWhere { OrderTable.tableId eq t } }
        from?.let { f -> query.andWhere { OrderTable.createdAt greaterEq f } }
        to?.let { t -> query.andWhere { OrderTable.createdAt lessEq t } }

        val orders = query
            .orderBy(OrderTable.createdAt, SortOrder.DESC)
            .limit(limit, offset.toLong())
            .map { it.toOrder() }

        orders.map { order ->
            val items = OrderItemTable.select { OrderItemTable.orderId eq order.id }
                .map { it.toOrderItem() }
            OrderWithItems(order, items)
        }
    }

    override suspend fun updateStatus(id: Long, status: OrderStatus): Boolean = dbQuery {
        OrderTable.update({ OrderTable.id eq id }) {
            it[OrderTable.status] = status.name
            it[updatedAt] = LocalDateTime.now()
        } > 0
    }

    override suspend fun findActiveKitchenOrders(): List<OrderWithItems> = dbQuery {
        val activeStatuses = listOf(
            OrderStatus.PENDING.name,
            OrderStatus.ACCEPTED.name,
            OrderStatus.PREPARING.name
        )

        val orders = OrderTable.select { OrderTable.status inList activeStatuses }
            .orderBy(OrderTable.createdAt, SortOrder.ASC)
            .map { it.toOrder() }

        orders.map { order ->
            val items = OrderItemTable.select { OrderItemTable.orderId eq order.id }
                .map { it.toOrderItem() }
            OrderWithItems(order, items)
        }
    }

    override suspend fun countByDateRange(from: LocalDate, to: LocalDate): Int = dbQuery {
        OrderTable.select {
            (OrderTable.createdAt greaterEq from.atStartOfDay()) and
            (OrderTable.createdAt less to.plusDays(1).atStartOfDay())
        }.count().toInt()
    }

    private fun ResultRow.toOrder() = Order(
        id = this[OrderTable.id],
        orderNumber = this[OrderTable.orderNumber],
        tableId = this[OrderTable.tableId],
        status = OrderStatus.valueOf(this[OrderTable.status]),
        totalAmount = this[OrderTable.totalAmount],
        createdAt = this[OrderTable.createdAt],
        updatedAt = this[OrderTable.updatedAt]
    )

    private fun ResultRow.toOrderItem() = OrderItem(
        id = this[OrderItemTable.id],
        orderId = this[OrderItemTable.orderId],
        menuId = this[OrderItemTable.menuId],
        menuName = this[OrderItemTable.menuName],
        quantity = this[OrderItemTable.quantity],
        unitPrice = this[OrderItemTable.unitPrice],
        totalPrice = this[OrderItemTable.totalPrice],
        selectedOptions = this[OrderItemTable.selectedOptions]
    )
}
