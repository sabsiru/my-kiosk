package com.kiosk.routes

import com.kiosk.application.AdminUseCase
import com.kiosk.application.HqUseCase
import com.kiosk.application.SettlementUseCase
import com.kiosk.domain.model.AdminRole
import com.kiosk.domain.model.AppException
import com.kiosk.domain.model.StoreStatus
import com.kiosk.infrastructure.db.TenantContext
import com.kiosk.plugins.adminId
import com.kiosk.plugins.role
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.time.LocalDate

fun Route.hqRoutes() {
    val hqUseCase by inject<HqUseCase>()
    val adminUseCase by inject<AdminUseCase>()
    val settlementUseCase by inject<SettlementUseCase>()

    route("/api/v1/hq") {
        authenticate("admin-jwt") {
            // HQ_ADMIN 권한 체크
            intercept(ApplicationCallPipeline.Call) {
                val principal = call.principal<JWTPrincipal>()
                if (principal?.role() != AdminRole.HQ_ADMIN.name) {
                    throw AppException.Forbidden("본사 관리자 권한이 필요합니다")
                }
            }

            // 매장 목록
            get("/stores") {
                val stores = hqUseCase.getStores()
                call.respond(stores.map {
                    HqStoreResponse(it.id, it.name, it.code, it.dbName, it.status.name, it.createdAt.toString())
                })
            }

            // 매장 상세
            get("/stores/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val store = hqUseCase.getStore(id)
                call.respond(HqStoreResponse(store.id, store.name, store.code, store.dbName, store.status.name, store.createdAt.toString()))
            }

            // 매장 생성
            post("/stores") {
                val request = call.receive<CreateHqStoreRequest>()
                val store = hqUseCase.createStore(request.name, request.code)
                call.respond(HttpStatusCode.Created,
                    HqStoreResponse(store.id, store.name, store.code, store.dbName, store.status.name, store.createdAt.toString()))
            }

            // 매장 수정
            put("/stores/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val request = call.receive<UpdateHqStoreRequest>()
                val status = try { StoreStatus.valueOf(request.status) } catch (_: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "잘못된 상태: ${request.status}")
                }
                val store = hqUseCase.updateStore(id, request.name, request.code, status)
                call.respond(HqStoreResponse(store.id, store.name, store.code, store.dbName, store.status.name, store.createdAt.toString()))
            }

            // 매장 삭제
            delete("/stores/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@delete call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                hqUseCase.deleteStore(id)
                call.respond(HttpStatusCode.NoContent)
            }

            // 특정 매장 정산 조회
            get("/stores/{id}/settlement") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val date = call.request.queryParameters["date"]?.let { LocalDate.parse(it) } ?: LocalDate.now()

                // 해당 매장 DB로 라우팅
                TenantContext.set(id)
                try {
                    val settlement = settlementUseCase.getDailySettlement(date)
                    call.respond(SettlementResponse(
                        settlement.date.toString(), settlement.totalRevenue, settlement.totalOrders,
                        settlement.cardAmount, settlement.cashAmount, settlement.kakaoPayAmount,
                        settlement.naverPayAmount, settlement.cancelledAmount, settlement.cancelledCount,
                        settlement.isClosed
                    ))
                } finally {
                    TenantContext.clear()
                }
            }

            // 전 매장 통합 매출 요약
            get("/statistics/summary") {
                val stores = hqUseCase.getStores()
                val date = call.request.queryParameters["date"]?.let { LocalDate.parse(it) } ?: LocalDate.now()

                val summaries = stores.map { store ->
                    TenantContext.set(store.id)
                    try {
                        val settlement = settlementUseCase.getDailySettlement(date)
                        StoreSummaryResponse(
                            storeId = store.id,
                            storeName = store.name,
                            totalRevenue = settlement.totalRevenue,
                            totalOrders = settlement.totalOrders,
                            isClosed = settlement.isClosed
                        )
                    } catch (_: Exception) {
                        StoreSummaryResponse(store.id, store.name, 0, 0, false)
                    } finally {
                        TenantContext.clear()
                    }
                }
                call.respond(summaries)
            }

            // 관리자 계정 관리
            get("/admins") {
                val storeId = call.request.queryParameters["storeId"]?.toLongOrNull()
                val admins = if (storeId != null) {
                    adminUseCase.getAdminsByStore(storeId)
                } else {
                    adminUseCase.getAdmins()
                }
                call.respond(admins.map { it.toHqAdminResponse() })
            }

            post("/admins") {
                val request = call.receive<CreateAdminRequest>()
                val role = try { AdminRole.valueOf(request.role) } catch (_: Exception) {
                    return@post call.respond(HttpStatusCode.BadRequest, "잘못된 역할: ${request.role}")
                }
                val admin = adminUseCase.createAdmin(
                    username = request.username,
                    password = request.password,
                    name = request.name,
                    role = role,
                    storeId = request.storeId
                )
                call.respond(HttpStatusCode.Created, admin.toHqAdminResponse())
            }

            put("/admins/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val request = call.receive<UpdateAdminRequest>()
                val role = try { AdminRole.valueOf(request.role) } catch (_: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "잘못된 역할: ${request.role}")
                }
                val admin = adminUseCase.updateAdmin(
                    id = id,
                    name = request.name,
                    role = role,
                    storeId = request.storeId,
                    password = request.password
                )
                call.respond(admin.toHqAdminResponse())
            }

            delete("/admins/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@delete call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val principal = call.principal<JWTPrincipal>()!!
                adminUseCase.deleteAdmin(id, principal.adminId())
                call.respond(HttpStatusCode.NoContent)
            }
        }
    }
}

private fun com.kiosk.domain.model.Admin.toHqAdminResponse() = HqAdminResponse(
    id = id, username = username, name = name, role = role.name, storeId = storeId
)

// Request DTOs
@Serializable data class CreateHqStoreRequest(val name: String, val code: String)
@Serializable data class UpdateHqStoreRequest(val name: String, val code: String, val status: String)
@Serializable data class CreateAdminRequest(
    val username: String, val password: String, val name: String,
    val role: String, val storeId: Long? = null
)
@Serializable data class UpdateAdminRequest(
    val name: String, val role: String, val storeId: Long? = null,
    val password: String? = null
)

// Response DTOs
@Serializable data class HqStoreResponse(
    val id: Long, val name: String, val code: String,
    val dbName: String, val status: String, val createdAt: String
)
@Serializable data class HqAdminResponse(
    val id: Long, val username: String, val name: String,
    val role: String, val storeId: Long? = null
)
@Serializable data class StoreSummaryResponse(
    val storeId: Long, val storeName: String,
    val totalRevenue: Int, val totalOrders: Int, val isClosed: Boolean
)
