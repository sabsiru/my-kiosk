package com.kiosk.routes

import com.kiosk.application.PaymentUseCase
import com.kiosk.domain.model.PaymentMethod
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject

fun Route.paymentRoutes() {
    val paymentUseCase by inject<PaymentUseCase>()

    post("/payments") {
        val request = call.receive<CreatePaymentRequest>()
        val method = parseEnum<PaymentMethod>(request.method, "결제 수단")
        val payment = paymentUseCase.createPayment(orderId = request.orderId, method = method)
        call.respond(HttpStatusCode.Created, payment.toResponse())
    }

    post("/payments/{id}/cancel") {
        val id = call.pathId()
        val payment = paymentUseCase.cancelPayment(id)
        call.respond(payment.toResponse())
    }

    get("/payments/{id}/status") {
        val id = call.pathId()
        val payment = paymentUseCase.getPaymentStatus(id)
        call.respond(payment.toResponse())
    }
}
