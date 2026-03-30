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
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.UUID

fun Route.adminRoutes() {
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
            call.respond(LoginResponse(
                token = token, name = admin.name, role = admin.role.name, storeId = admin.storeId
            ))
        }

        // 인증 필요한 API (매장 관리자용 - TenantContext 설정)
        authenticate("admin-jwt") {
            get("/me") {
                val principal = call.principal<JWTPrincipal>()!!
                val admin = adminUseCase.getAdmin(principal.adminId())
                call.respond(AdminResponse(admin.id, admin.username, admin.name, admin.role.name, admin.storeId))
            }

            // 매장 DB가 필요한 라우트 (TenantContext 설정)
            route("") {
                intercept(ApplicationCallPipeline.Call) {
                    val principal = call.principal<JWTPrincipal>()
                    val storeId = principal?.storeId()
                    if (storeId != null) {
                        TenantContext.set(storeId)
                    }
                    // HQ_ADMIN이 특정 매장 조회 시 storeId 쿼리 파라미터 사용
                    val queryStoreId = call.request.queryParameters["storeId"]?.toLongOrNull()
                    if (queryStoreId != null && principal?.role() == AdminRole.HQ_ADMIN.name) {
                        TenantContext.set(queryStoreId)
                    }
                }

            // 카테고리/메뉴 조회
            get("/categories") {
                val categories = menuUseCase.getCategories()
                call.respond(categories.map { CategoryResponse(it.id, it.name, it.displayOrder) })
            }

            get("/categories/{id}/menus") {
                val categoryId = call.parameters["id"]?.toLongOrNull()
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "잘못된 카테고리 ID")
                val menus = menuUseCase.getMenusByCategory(categoryId)
                call.respond(menus.map {
                    MenuResponse(it.id, it.categoryId, it.name, it.description, it.price, it.imageUrl, it.isSoldOut, it.displayOrder)
                })
            }

            // 카테고리 관리
            post("/categories") {
                val request = call.receive<CreateCategoryRequest>()
                val category = menuUseCase.createCategory(request.name, request.displayOrder)
                call.respond(HttpStatusCode.Created, CategoryResponse(category.id, category.name, category.displayOrder))
            }

            put("/categories/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val request = call.receive<UpdateCategoryRequest>()
                val category = menuUseCase.updateCategory(id, request.name, request.displayOrder)
                call.respond(CategoryResponse(category.id, category.name, category.displayOrder))
            }

            delete("/categories/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@delete call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                menuUseCase.deleteCategory(id)
                call.respond(HttpStatusCode.NoContent)
            }

            // 메뉴 관리
            post("/menus") {
                val request = call.receive<CreateMenuRequest>()
                val menu = menuUseCase.createMenu(
                    request.categoryId, request.name, request.description,
                    request.price, request.imageUrl, request.displayOrder
                )
                call.respond(HttpStatusCode.Created, MenuResponse(
                    menu.id, menu.categoryId, menu.name, menu.description,
                    menu.price, menu.imageUrl, menu.isSoldOut, menu.displayOrder
                ))
            }

            put("/menus/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val request = call.receive<UpdateMenuRequest>()
                val menu = menuUseCase.updateMenu(
                    id, request.categoryId, request.name, request.description,
                    request.price, request.imageUrl, request.displayOrder
                )
                call.respond(MenuResponse(
                    menu.id, menu.categoryId, menu.name, menu.description,
                    menu.price, menu.imageUrl, menu.isSoldOut, menu.displayOrder
                ))
            }

            delete("/menus/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@delete call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                menuUseCase.deleteMenu(id)
                call.respond(HttpStatusCode.NoContent)
            }

            put("/menus/{id}/sold-out") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val isSoldOut = menuUseCase.toggleSoldOut(id)
                call.respond(SoldOutResponse(id, isSoldOut))
            }

            // 주문 관리
            get("/orders") {
                val status = call.request.queryParameters["status"]?.let {
                    try { OrderStatus.valueOf(it) } catch (_: IllegalArgumentException) {
                        return@get call.respond(HttpStatusCode.BadRequest, "잘못된 주문 상태: $it")
                    }
                }
                val tableId = call.request.queryParameters["tableId"]?.toLongOrNull()
                val from = call.request.queryParameters["from"]?.let { LocalDate.parse(it).atStartOfDay() }
                val to = call.request.queryParameters["to"]?.let { LocalDate.parse(it).atTime(LocalTime.MAX) }
                val limit = call.request.queryParameters["limit"]?.toIntOrNull() ?: 50
                val offset = call.request.queryParameters["offset"]?.toIntOrNull() ?: 0

                val orders = orderUseCase.getOrders(status, tableId, from, to, limit, offset)
                call.respond(orders.map { it.toOrderResponse() })
            }

            get("/orders/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val order = orderUseCase.getOrderById(id)
                call.respond(order.toOrderResponse())
            }

            put("/orders/{id}/status") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val request = call.receive<UpdateStatusRequest>()
                val status = try { OrderStatus.valueOf(request.status) } catch (_: IllegalArgumentException) {
                    return@put call.respond(HttpStatusCode.BadRequest, "잘못된 주문 상태: ${request.status}")
                }
                orderUseCase.updateOrderStatus(id, status)
                call.respond(HttpStatusCode.OK)
            }

            put("/orders/{id}/cancel") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                orderUseCase.cancelOrder(id)
                call.respond(HttpStatusCode.OK)
            }

            // 테이블 관리
            get("/tables") {
                val tables = tableUseCase.getTables()
                call.respond(tables.map { TableResponse(it.id, it.tableNumber, it.deviceId, it.status.name) })
            }

            post("/tables") {
                val request = call.receive<CreateTableRequest>()
                val table = tableUseCase.createTable(request.tableNumber, request.deviceId)
                call.respond(HttpStatusCode.Created, TableResponse(table.id, table.tableNumber, table.deviceId, table.status.name))
            }

            put("/tables/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val request = call.receive<UpdateTableRequest>()
                val table = tableUseCase.updateTable(id, request.tableNumber, request.deviceId)
                call.respond(TableResponse(table.id, table.tableNumber, table.deviceId, table.status.name))
            }

            delete("/tables/{id}") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@delete call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                tableUseCase.deleteTable(id)
                call.respond(HttpStatusCode.NoContent)
            }

            post("/tables/{id}/checkout") {
                val id = call.parameters["id"]?.toLongOrNull()
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "잘못된 ID")
                val request = call.receive<CheckoutRequest>()
                val method = try { PaymentMethod.valueOf(request.method) } catch (_: IllegalArgumentException) {
                    return@post call.respond(HttpStatusCode.BadRequest, "잘못된 결제 수단: ${request.method}")
                }
                val payments = tableUseCase.checkoutTable(id, method)
                settlementUseCase.recalculateForDate(LocalDate.now())
                call.respond(CheckoutResponse(tableId = id, paymentCount = payments.size, status = "AVAILABLE"))
            }

            // 정산
            get("/settlements/daily") {
                val date = call.request.queryParameters["date"]?.let { LocalDate.parse(it) } ?: LocalDate.now()
                call.respond(settlementUseCase.getDailySettlement(date).toSettlementResponse())
            }

            get("/settlements/period") {
                val from = LocalDate.parse(call.request.queryParameters["from"] ?: LocalDate.now().minusDays(7).toString())
                val to = LocalDate.parse(call.request.queryParameters["to"] ?: LocalDate.now().toString())
                call.respond(settlementUseCase.getPeriodSettlement(from, to).map { it.toSettlementResponse() })
            }

            get("/settlements/by-payment-method") {
                val from = LocalDate.parse(call.request.queryParameters["from"] ?: LocalDate.now().minusDays(7).toString())
                val to = LocalDate.parse(call.request.queryParameters["to"] ?: LocalDate.now().toString())
                call.respond(settlementUseCase.getByPaymentMethod(from, to))
            }

            post("/settlements/close") {
                val date = call.request.queryParameters["date"]?.let { LocalDate.parse(it) } ?: LocalDate.now()
                call.respond(settlementUseCase.closeDaily(date).toSettlementResponse())
            }

            // 통계
            get("/statistics/menu-sales") {
                val from = LocalDate.parse(call.request.queryParameters["from"] ?: LocalDate.now().minusDays(30).toString())
                val to = LocalDate.parse(call.request.queryParameters["to"] ?: LocalDate.now().toString())
                call.respond(statisticsUseCase.getMenuSales(from, to).map {
                    MenuSalesResponse(it.menuId, it.menuName, it.categoryName, it.totalQuantity, it.totalRevenue)
                })
            }

            get("/statistics/revenue") {
                val from = LocalDate.parse(call.request.queryParameters["from"] ?: LocalDate.now().minusDays(30).toString())
                val to = LocalDate.parse(call.request.queryParameters["to"] ?: LocalDate.now().toString())
                call.respond(statisticsUseCase.getRevenueTrend(from, to).map {
                    RevenueResponse(it.date.toString(), it.totalRevenue, it.totalOrders)
                })
            }

            get("/statistics/hourly") {
                val date = call.request.queryParameters["date"]?.let { LocalDate.parse(it) } ?: LocalDate.now()
                call.respond(statisticsUseCase.getHourlyDistribution(date).map {
                    HourlyResponse(it.hour, it.orderCount, it.revenue)
                })
            }

            get("/statistics/category-sales") {
                val from = LocalDate.parse(call.request.queryParameters["from"] ?: LocalDate.now().minusDays(30).toString())
                val to = LocalDate.parse(call.request.queryParameters["to"] ?: LocalDate.now().toString())
                call.respond(statisticsUseCase.getCategorySales(from, to).map {
                    CategorySalesResponse(it.categoryId, it.categoryName, it.totalRevenue, it.percentage)
                })
            }

            // 매장 설정
            get("/store") {
                val store = storeUseCase.getStore()
                call.respond(StoreResponse(store.id, store.name, store.openTime.toString(), store.closeTime.toString(), store.isOpen, store.hideAdminButton))
            }

            put("/store") {
                val request = call.receive<UpdateStoreRequest>()
                val store = storeUseCase.updateStore(
                    request.name,
                    LocalTime.parse(request.openTime),
                    LocalTime.parse(request.closeTime),
                    request.isOpen,
                    request.hideAdminButton
                )
                call.respond(StoreResponse(store.id, store.name, store.openTime.toString(), store.closeTime.toString(), store.isOpen, store.hideAdminButton))
            }

            post("/store/open") {
                val store = storeUseCase.openStore()
                call.respond(StoreResponse(store.id, store.name, store.openTime.toString(), store.closeTime.toString(), store.isOpen, store.hideAdminButton))
            }

            post("/store/close") {
                val store = storeUseCase.closeStore()
                call.respond(StoreResponse(store.id, store.name, store.openTime.toString(), store.closeTime.toString(), store.isOpen, store.hideAdminButton))
            }

            // 이미지 업로드
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
                val url = fileUrl
                if (url != null) {
                    call.respond(UploadResponse(url = url))
                } else {
                    call.respond(HttpStatusCode.BadRequest, "파일이 없습니다")
                }
            }
            } // route("") - TenantContext scope
        }
    }
}

// Request DTOs
@Serializable data class LoginRequest(val username: String, val password: String)
@Serializable data class CreateCategoryRequest(val name: String, val displayOrder: Int = 0)
@Serializable data class UpdateCategoryRequest(val name: String, val displayOrder: Int)
@Serializable data class CreateMenuRequest(
    val categoryId: Long, val name: String, val description: String = "",
    val price: Int, val imageUrl: String? = null, val displayOrder: Int = 0
)
@Serializable data class UpdateMenuRequest(
    val categoryId: Long, val name: String, val description: String = "",
    val price: Int, val imageUrl: String? = null, val displayOrder: Int = 0
)
@Serializable data class UpdateStatusRequest(val status: String)
@Serializable data class CreateTableRequest(val tableNumber: Int, val deviceId: String? = null)
@Serializable data class UpdateTableRequest(val tableNumber: Int, val deviceId: String? = null)
@Serializable data class UpdateStoreRequest(val name: String, val openTime: String, val closeTime: String, val isOpen: Boolean, val hideAdminButton: Boolean = false)
@Serializable data class CheckoutRequest(val method: String)

// Response DTOs
@Serializable data class LoginResponse(val token: String, val name: String, val role: String, val storeId: Long? = null)
@Serializable data class AdminResponse(val id: Long, val username: String, val name: String, val role: String, val storeId: Long? = null)
@Serializable data class SoldOutResponse(val menuId: Long, val isSoldOut: Boolean)
@Serializable data class TableResponse(val id: Long, val tableNumber: Int, val deviceId: String?, val status: String)
@Serializable data class SettlementResponse(
    val date: String, val totalRevenue: Int, val totalOrders: Int,
    val cardAmount: Int, val cashAmount: Int, val kakaoPayAmount: Int, val naverPayAmount: Int,
    val cancelledAmount: Int, val cancelledCount: Int, val isClosed: Boolean
)
@Serializable data class MenuSalesResponse(val menuId: Long, val menuName: String, val categoryName: String, val totalQuantity: Int, val totalRevenue: Int)
@Serializable data class RevenueResponse(val date: String, val totalRevenue: Int, val totalOrders: Int)
@Serializable data class HourlyResponse(val hour: Int, val orderCount: Int, val revenue: Int)
@Serializable data class CategorySalesResponse(val categoryId: Long, val categoryName: String, val totalRevenue: Int, val percentage: Double)
@Serializable data class StoreResponse(val id: Long, val name: String, val openTime: String, val closeTime: String, val isOpen: Boolean, val hideAdminButton: Boolean = false)
@Serializable data class CheckoutResponse(val tableId: Long, val paymentCount: Int, val status: String)
@Serializable data class UploadResponse(val url: String)

private fun com.kiosk.domain.model.Settlement.toSettlementResponse() = SettlementResponse(
    date.toString(), totalRevenue, totalOrders, cardAmount, cashAmount,
    kakaoPayAmount, naverPayAmount, cancelledAmount, cancelledCount, isClosed
)
