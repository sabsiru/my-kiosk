package com.kiosk.routes

import com.kiosk.application.CreateOrderItemRequest
import com.kiosk.application.OrderUseCase
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject

fun Route.orderRoutes() {
    val orderUseCase by inject<OrderUseCase>()

    get("/orders") {
        val tableId = call.queryLong("tableId")
        val orders = orderUseCase.getOrders(tableId = tableId, limit = 50)
        call.respond(orders.map { it.toResponse() })
    }

    post("/orders") {
        val request = call.receive<CreateOrderRequest>()
        val order = orderUseCase.createOrder(
            tableId = request.tableId,
            items = request.items.map {
                CreateOrderItemRequest(it.menuId, it.quantity, it.selectedOptions, it.optionAdditionalPrice)
            }
        )
        call.respond(HttpStatusCode.Created, order.toResponse())
    }

    get("/orders/{orderNumber}") {
        val orderNumber = call.parameters["orderNumber"]
            ?: throw com.kiosk.domain.model.AppException.BadRequest("주문번호 필요")
        val order = orderUseCase.getOrder(orderNumber)
        call.respond(order.toResponse())
    }
}
