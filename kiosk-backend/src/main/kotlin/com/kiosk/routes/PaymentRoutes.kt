package com.kiosk.routes

import com.kiosk.application.PaymentUseCase
import com.kiosk.domain.model.PaymentMethod
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject

fun Route.paymentRoutes() {
    val paymentUseCase by inject<PaymentUseCase>()

    post("/payments") {
        val request = call.receive<CreatePaymentRequest>()
        val payment = paymentUseCase.createPayment(
            orderId = request.orderId,
            method = PaymentMethod.valueOf(request.method)
        )
        call.respond(HttpStatusCode.Created, payment.toPaymentResponse())
    }

    post("/payments/{id}/cancel") {
        val id = call.parameters["id"]?.toLongOrNull()
            ?: return@post call.respond(HttpStatusCode.BadRequest, "잘못된 결제 ID")
        val payment = paymentUseCase.cancelPayment(id)
        call.respond(payment.toPaymentResponse())
    }

    get("/payments/{id}/status") {
        val id = call.parameters["id"]?.toLongOrNull()
            ?: return@get call.respond(HttpStatusCode.BadRequest, "잘못된 결제 ID")
        val payment = paymentUseCase.getPaymentStatus(id)
        call.respond(payment.toPaymentResponse())
    }
}

@Serializable
data class CreatePaymentRequest(
    val orderId: Long,
    val method: String
)

@Serializable
data class PaymentResponse(
    val id: Long,
    val orderId: Long,
    val method: String,
    val amount: Int,
    val status: String,
    val approvalNumber: String?,
    val createdAt: String
)

private fun com.kiosk.domain.model.Payment.toPaymentResponse() = PaymentResponse(
    id = id,
    orderId = orderId,
    method = method.name,
    amount = amount,
    status = status.name,
    approvalNumber = approvalNumber,
    createdAt = createdAt.toString()
)
