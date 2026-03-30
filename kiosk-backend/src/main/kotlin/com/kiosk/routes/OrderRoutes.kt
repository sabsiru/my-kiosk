package com.kiosk.routes

import com.kiosk.application.CreateOrderItemRequest
import com.kiosk.application.OrderUseCase
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject

fun Route.orderRoutes() {
    val orderUseCase by inject<OrderUseCase>()

    get("/orders") {
        val tableId = call.request.queryParameters["tableId"]?.toLongOrNull()
        val orders = orderUseCase.getOrders(tableId = tableId, limit = 50)
        call.respond(orders.map { it.toOrderResponse() })
    }

    post("/orders") {
        val request = call.receive<CreateOrderRequest>()
        val order = orderUseCase.createOrder(
            tableId = request.tableId,
            items = request.items.map {
                CreateOrderItemRequest(
                    menuId = it.menuId,
                    quantity = it.quantity,
                    selectedOptions = it.selectedOptions,
                    optionAdditionalPrice = it.optionAdditionalPrice
                )
            }
        )
        call.respond(HttpStatusCode.Created, order.toOrderResponse())
    }

    get("/orders/{orderNumber}") {
        val orderNumber = call.parameters["orderNumber"]
            ?: return@get call.respond(HttpStatusCode.BadRequest, "주문번호 필요")
        val order = orderUseCase.getOrder(orderNumber)
        call.respond(order.toOrderResponse())
    }
}

@Serializable
data class CreateOrderRequest(
    val tableId: Long? = null,
    val items: List<OrderItemRequest>
)

@Serializable
data class OrderItemRequest(
    val menuId: Long,
    val quantity: Int,
    val selectedOptions: String = "",
    val optionAdditionalPrice: Int = 0
)

@Serializable
data class OrderResponse(
    val id: Long,
    val orderNumber: String,
    val tableId: Long?,
    val status: String,
    val totalAmount: Int,
    val items: List<OrderItemResponse>,
    val createdAt: String
)

@Serializable
data class OrderItemResponse(
    val id: Long,
    val menuId: Long,
    val menuName: String,
    val quantity: Int,
    val unitPrice: Int,
    val totalPrice: Int,
    val selectedOptions: String
)

fun com.kiosk.domain.model.OrderWithItems.toOrderResponse() = OrderResponse(
    id = order.id,
    orderNumber = order.orderNumber,
    tableId = order.tableId,
    status = order.status.name,
    totalAmount = order.totalAmount,
    items = items.map {
        OrderItemResponse(it.id, it.menuId, it.menuName, it.quantity, it.unitPrice, it.totalPrice, it.selectedOptions)
    },
    createdAt = order.createdAt.toString()
)
