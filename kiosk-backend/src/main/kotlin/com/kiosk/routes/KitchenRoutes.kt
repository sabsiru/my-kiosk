package com.kiosk.routes

import com.kiosk.application.OrderUseCase
import com.kiosk.domain.model.OrderStatus
import com.kiosk.infrastructure.db.TenantContext
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject

fun Route.kitchenRoutes() {
    val orderUseCase by inject<OrderUseCase>()

    route("/api/v1/kitchen") {
        intercept(ApplicationCallPipeline.Call) {
            val storeId = call.request.queryParameters["storeId"]?.toLongOrNull()
                ?: return@intercept call.respond(HttpStatusCode.BadRequest, "storeId is required")
            if (TenantContext.getOrNull() == null) TenantContext.set(storeId)
        }

        get("/orders") {
            val orders = orderUseCase.getActiveKitchenOrders()
            call.respond(orders.map { it.toOrderResponse() })
        }

        put("/orders/{id}/status") {
            val id = call.parameters["id"]?.toLongOrNull()
                ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
            val request = call.receive<UpdateStatusRequest>()
            val status = OrderStatus.valueOf(request.status)
            orderUseCase.updateOrderStatus(id, status)
            call.respond(HttpStatusCode.OK)
        }
    }
}
