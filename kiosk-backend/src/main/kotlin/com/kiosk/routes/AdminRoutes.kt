package com.kiosk.routes

import com.kiosk.application.*
import com.kiosk.domain.model.*
import com.kiosk.infrastructure.db.TenantContext
import com.kiosk.plugins.JwtConfig
import com.kiosk.plugins.adminId
import com.kiosk.plugins.role
import com.kiosk.plugins.storeId
import io.ktor.http.*
import io.ktor.http.content.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject
import java.io.File
import java.time.LocalDate
import java.time.LocalTime
import java.util.UUID

fun Route.adminRoutes() {
    val categoryUseCase by inject<CategoryUseCase>()
    val menuUseCase by inject<MenuUseCase>()
    val orderUseCase by inject<OrderUseCase>()
    val adminUseCase by inject<AdminUseCase>()
    val tableUseCase by inject<TableUseCase>()
    val settlementUseCase by inject<SettlementUseCase>()
    val statisticsUseCase by inject<StatisticsUseCase>()
    val storeUseCase by inject<StoreUseCase>()

    route("/api/v1/admin") {
        // 로그인 (인증 불필요)
        post("/login") {
            val request = call.receive<LoginRequest>()
            val admin = adminUseCase.login(request.username, request.password)
            val token = JwtConfig.generateToken(admin.id, admin.username, admin.role.name, admin.storeId)
            call.respond(LoginResponse(token = token, name = admin.name, role = admin.role.name, storeId = admin.storeId))
        }

        authenticate("admin-jwt") {
            get("/me") {
                val principal = call.principal<JWTPrincipal>()!!
                val admin = adminUseCase.getAdmin(principal.adminId())
                call.respond(admin.toAdminResponse())
            }

            // 매장 DB가 필요한 라우트 (TenantContext 설정)
            route("") {
                intercept(ApplicationCallPipeline.Call) {
                    val principal = call.principal<JWTPrincipal>()
                    val storeId = principal?.storeId()
                    if (storeId != null) TenantContext.set(storeId)
                    val queryStoreId = call.queryLong("storeId")
                    if (queryStoreId != null && principal?.role() == AdminRole.HQ_ADMIN.name) {
                        TenantContext.set(queryStoreId)
                    }
                }

                // ─── 카테고리/메뉴 ─────────────────────────
                get("/categories") {
                    call.respond(categoryUseCase.getCategories().map { it.toResponse() })
                }

                get("/categories/{id}/menus") {
                    call.respond(menuUseCase.getMenusByCategory(call.pathId()).map { it.toResponse() })
                }

                post("/categories") {
                    val request = call.receive<CreateCategoryRequest>()
                    val category = categoryUseCase.createCategory(request.name, request.displayOrder)
                    call.respond(HttpStatusCode.Created, category.toResponse())
                }

                put("/categories/{id}") {
                    val request = call.receive<UpdateCategoryRequest>()
                    val category = categoryUseCase.updateCategory(call.pathId(), request.name, request.displayOrder)
                    call.respond(category.toResponse())
                }

                delete("/categories/{id}") {
                    categoryUseCase.deleteCategory(call.pathId())
                    call.respond(HttpStatusCode.NoContent)
                }

                post("/menus") {
                    val request = call.receive<CreateMenuRequest>()
                    val menu = menuUseCase.createMenu(
                        request.categoryId, request.name, request.description,
                        request.price, request.imageUrl, request.displayOrder
                    )
                    call.respond(HttpStatusCode.Created, menu.toResponse())
                }

                put("/menus/{id}") {
                    val request = call.receive<UpdateMenuRequest>()
                    val menu = menuUseCase.updateMenu(
                        call.pathId(), request.categoryId, request.name, request.description,
                        request.price, request.imageUrl, request.displayOrder
                    )
                    call.respond(menu.toResponse())
                }

                delete("/menus/{id}") {
                    menuUseCase.deleteMenu(call.pathId())
                    call.respond(HttpStatusCode.NoContent)
                }

                put("/menus/{id}/sold-out") {
                    val id = call.pathId()
                    val isSoldOut = menuUseCase.toggleSoldOut(id)
                    call.respond(SoldOutResponse(id, isSoldOut))
                }

                // ─── 주문 ───────────────────────────────────
                get("/orders") {
                    val status = call.queryEnum<OrderStatus>("status")
                    val tableId = call.queryLong("tableId")
                    val from = call.request.queryParameters["from"]?.let { LocalDate.parse(it).atStartOfDay() }
                    val to = call.request.queryParameters["to"]?.let { LocalDate.parse(it).atTime(LocalTime.MAX) }
                    val limit = call.queryInt("limit", 50)
                    val offset = call.queryInt("offset", 0)

                    val orders = orderUseCase.getOrders(status, tableId, from, to, limit, offset)
                    call.respond(orders.map { it.toResponse() })
                }

                get("/orders/{id}") {
                    call.respond(orderUseCase.getOrderById(call.pathId()).toResponse())
                }

                put("/orders/{id}/status") {
                    val request = call.receive<UpdateStatusRequest>()
                    val status = parseEnum<OrderStatus>(request.status, "주문 상태")
                    orderUseCase.updateOrderStatus(call.pathId(), status)
                    call.respond(HttpStatusCode.OK)
                }

                put("/orders/{id}/cancel") {
                    orderUseCase.cancelOrder(call.pathId())
                    call.respond(HttpStatusCode.OK)
                }

                // ─── 테이블 ─────────────────────────────────
                get("/tables") {
                    call.respond(tableUseCase.getTables().map { it.toResponse() })
                }

                post("/tables") {
                    val request = call.receive<CreateTableRequest>()
                    val table = tableUseCase.createTable(request.tableNumber, request.deviceId)
                    call.respond(HttpStatusCode.Created, table.toResponse())
                }

                put("/tables/{id}") {
                    val request = call.receive<UpdateTableRequest>()
                    val table = tableUseCase.updateTable(call.pathId(), request.tableNumber, request.deviceId)
                    call.respond(table.toResponse())
                }

                delete("/tables/{id}") {
                    tableUseCase.deleteTable(call.pathId())
                    call.respond(HttpStatusCode.NoContent)
                }

                post("/tables/{id}/checkout") {
                    val id = call.pathId()
                    val request = call.receive<CheckoutRequest>()
                    val method = parseEnum<PaymentMethod>(request.method, "결제 수단")
                    val payments = tableUseCase.checkoutTable(id, method)
                    settlementUseCase.recalculateForDate(LocalDate.now())
                    call.respond(CheckoutResponse(tableId = id, paymentCount = payments.size, status = "AVAILABLE"))
                }

                // ─── 정산 ───────────────────────────────────
                get("/settlements/daily") {
                    val date = call.queryDate("date")
                    call.respond(settlementUseCase.getDailySettlement(date).toResponse())
                }

                get("/settlements/period") {
                    val (from, to) = call.queryDateRange()
                    call.respond(settlementUseCase.getPeriodSettlement(from, to).map { it.toResponse() })
                }

                get("/settlements/by-payment-method") {
                    val (from, to) = call.queryDateRange()
                    call.respond(settlementUseCase.getByPaymentMethod(from, to))
                }

                post("/settlements/close") {
                    val date = call.queryDate("date")
                    call.respond(settlementUseCase.closeDaily(date).toResponse())
                }

                // ─── 통계 ───────────────────────────────────
                get("/statistics/menu-sales") {
                    val (from, to) = call.queryDateRange(defaultDays = 30)
                    call.respond(statisticsUseCase.getMenuSales(from, to).map { it.toResponse() })
                }

                get("/statistics/revenue") {
                    val (from, to) = call.queryDateRange(defaultDays = 30)
                    call.respond(statisticsUseCase.getRevenueTrend(from, to).map { it.toResponse() })
                }

                get("/statistics/hourly") {
                    val date = call.queryDate("date")
                    call.respond(statisticsUseCase.getHourlyDistribution(date).map { it.toResponse() })
                }

                get("/statistics/category-sales") {
                    val (from, to) = call.queryDateRange(defaultDays = 30)
                    call.respond(statisticsUseCase.getCategorySales(from, to).map { it.toResponse() })
                }

                // ─── 매장 설정 ───────────────────────────────
                get("/store") {
                    call.respond(storeUseCase.getStore().toResponse())
                }

                put("/store") {
                    val request = call.receive<UpdateStoreRequest>()
                    val store = storeUseCase.updateStore(
                        request.name, LocalTime.parse(request.openTime),
                        LocalTime.parse(request.closeTime), request.isOpen, request.hideAdminButton
                    )
                    call.respond(store.toResponse())
                }

                post("/store/open") {
                    call.respond(storeUseCase.openStore().toResponse())
                }

                post("/store/close") {
                    call.respond(storeUseCase.closeStore().toResponse())
                }

                // ─── 이미지 업로드 ───────────────────────────
                post("/upload/image") {
                    val multipart = call.receiveMultipart()
                    var fileUrl: String? = null
                    multipart.forEachPart { part ->
                        if (part is PartData.FileItem) {
                            val ext = part.originalFileName?.substringAfterLast('.', "jpg") ?: "jpg"
                            val filename = "${UUID.randomUUID()}.$ext"
                            val uploadDir = File("uploads")
                            uploadDir.mkdirs()
                            val file = File(uploadDir, filename)
                            part.streamProvider().use { input ->
                                file.outputStream().use { output -> input.copyTo(output) }
                            }
                            fileUrl = "/static/uploads/$filename"
                        }
                        part.dispose()
                    }
                    val url = fileUrl ?: throw AppException.BadRequest("파일이 없습니다")
                    call.respond(UploadResponse(url = url))
                }
            } // route("") - TenantContext scope
        }
    }
}
