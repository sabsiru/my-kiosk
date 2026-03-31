package com.kiosk.routes

import com.kiosk.application.AdminUseCase
import com.kiosk.application.HqUseCase
import com.kiosk.application.SettlementUseCase
import com.kiosk.domain.model.AdminRole
import com.kiosk.domain.model.AppException
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
import org.koin.ktor.ext.inject

fun Route.hqRoutes() {
    val hqUseCase by inject<HqUseCase>()
    val adminUseCase by inject<AdminUseCase>()
    val settlementUseCase by inject<SettlementUseCase>()

    route("/api/v1/hq") {
        authenticate("admin-jwt") {
            intercept(ApplicationCallPipeline.Call) {
                val principal = call.principal<JWTPrincipal>()
                if (principal?.role() != AdminRole.HQ_ADMIN.name) {
                    throw AppException.Forbidden("본사 관리자 권한이 필요합니다")
                }
            }

            // ─── 매장 관리 ─────────────────────────────
            get("/stores") {
                call.respond(hqUseCase.getStores().map { it.toResponse() })
            }

            get("/stores/{id}") {
                call.respond(hqUseCase.getStore(call.pathId()).toResponse())
            }

            post("/stores") {
                val request = call.receive<CreateHqStoreRequest>()
                val store = hqUseCase.createStore(request.name, request.code)
                call.respond(HttpStatusCode.Created, store.toResponse())
            }

            put("/stores/{id}") {
                val request = call.receive<UpdateHqStoreRequest>()
                val status = parseEnum<com.kiosk.domain.model.StoreStatus>(request.status, "매장 상태")
                val store = hqUseCase.updateStore(call.pathId(), request.name, request.code, status)
                call.respond(store.toResponse())
            }

            delete("/stores/{id}") {
                hqUseCase.deleteStore(call.pathId())
                call.respond(HttpStatusCode.NoContent)
            }

            get("/stores/{id}/settlement") {
                val id = call.pathId()
                val date = call.queryDate("date")
                TenantContext.set(id)
                try {
                    call.respond(settlementUseCase.getDailySettlement(date).toResponse())
                } finally {
                    TenantContext.clear()
                }
            }

            // ─── 통합 통계 ──────────────────────────────
            get("/statistics/summary") {
                val stores = hqUseCase.getStores()
                val date = call.queryDate("date")

                val summaries = stores.map { store ->
                    TenantContext.set(store.id)
                    try {
                        val settlement = settlementUseCase.getDailySettlement(date)
                        StoreSummaryResponse(store.id, store.name, settlement.totalRevenue, settlement.totalOrders, settlement.isClosed)
                    } catch (_: Exception) {
                        StoreSummaryResponse(store.id, store.name, 0, 0, false)
                    } finally {
                        TenantContext.clear()
                    }
                }
                call.respond(summaries)
            }

            // ─── 관리자 계정 ────────────────────────────
            get("/admins") {
                val storeId = call.queryLong("storeId")
                val admins = if (storeId != null) adminUseCase.getAdminsByStore(storeId) else adminUseCase.getAdmins()
                call.respond(admins.map { it.toHqAdminResponse() })
            }

            post("/admins") {
                val request = call.receive<CreateAdminRequest>()
                val role = parseEnum<AdminRole>(request.role, "역할")
                val admin = adminUseCase.createAdmin(request.username, request.password, request.name, role, request.storeId)
                call.respond(HttpStatusCode.Created, admin.toHqAdminResponse())
            }

            put("/admins/{id}") {
                val request = call.receive<UpdateAdminRequest>()
                val role = parseEnum<AdminRole>(request.role, "역할")
                val admin = adminUseCase.updateAdmin(call.pathId(), request.name, role, request.storeId, request.password)
                call.respond(admin.toHqAdminResponse())
            }

            delete("/admins/{id}") {
                val principal = call.principal<JWTPrincipal>()!!
                adminUseCase.deleteAdmin(call.pathId(), principal.adminId())
                call.respond(HttpStatusCode.NoContent)
            }
        }
    }
}
