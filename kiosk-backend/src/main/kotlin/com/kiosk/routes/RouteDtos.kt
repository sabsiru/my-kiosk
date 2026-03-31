package com.kiosk.routes

import com.kiosk.domain.model.*
import kotlinx.serialization.Serializable

// ─── Auth ────────────────────────────────────────────
@Serializable data class LoginRequest(val username: String, val password: String)
@Serializable data class LoginResponse(val token: String, val name: String, val role: String, val storeId: Long? = null)
@Serializable data class AdminResponse(val id: Long, val username: String, val name: String, val role: String, val storeId: Long? = null)

// ─── Menu ────────────────────────────────────────────
@Serializable data class CategoryResponse(val id: Long, val name: String, val displayOrder: Int)
@Serializable data class MenuResponse(
    val id: Long, val categoryId: Long, val name: String, val description: String,
    val price: Int, val imageUrl: String?, val isSoldOut: Boolean, val displayOrder: Int
)
@Serializable data class MenuDetailResponse(
    val id: Long, val categoryId: Long, val name: String, val description: String,
    val price: Int, val imageUrl: String?, val isSoldOut: Boolean, val options: List<MenuOptionResponse>
)
@Serializable data class MenuOptionResponse(val id: Long, val name: String, val isRequired: Boolean, val maxSelection: Int, val items: List<MenuOptionItemResponse>)
@Serializable data class MenuOptionItemResponse(val id: Long, val name: String, val additionalPrice: Int)
@Serializable data class SoldOutResponse(val menuId: Long, val isSoldOut: Boolean)

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

// ─── Order ───────────────────────────────────────────
@Serializable data class OrderResponse(
    val id: Long, val orderNumber: String, val tableId: Long?, val status: String,
    val totalAmount: Int, val items: List<OrderItemResponse>, val createdAt: String
)
@Serializable data class OrderItemResponse(
    val id: Long, val menuId: Long, val menuName: String, val quantity: Int,
    val unitPrice: Int, val totalPrice: Int, val selectedOptions: String
)
@Serializable data class CreateOrderRequest(val tableId: Long? = null, val items: List<OrderItemRequest>)
@Serializable data class OrderItemRequest(val menuId: Long, val quantity: Int, val selectedOptions: String = "", val optionAdditionalPrice: Int = 0)
@Serializable data class UpdateStatusRequest(val status: String)

// ─── Payment ─────────────────────────────────────────
@Serializable data class PaymentResponse(
    val id: Long, val orderId: Long, val method: String, val amount: Int,
    val status: String, val approvalNumber: String?, val createdAt: String
)
@Serializable data class CreatePaymentRequest(val orderId: Long, val method: String)

// ─── Table ───────────────────────────────────────────
@Serializable data class TableResponse(val id: Long, val tableNumber: Int, val deviceId: String?, val status: String)
@Serializable data class KioskTableResponse(val id: Long, val tableNumber: Int, val status: String)
@Serializable data class CreateTableRequest(val tableNumber: Int, val deviceId: String? = null)
@Serializable data class UpdateTableRequest(val tableNumber: Int, val deviceId: String? = null)
@Serializable data class CheckoutRequest(val method: String)
@Serializable data class CheckoutResponse(val tableId: Long, val paymentCount: Int, val status: String)

// ─── Settlement ──────────────────────────────────────
@Serializable data class SettlementResponse(
    val date: String, val totalRevenue: Int, val totalOrders: Int,
    val cardAmount: Int, val cashAmount: Int, val kakaoPayAmount: Int, val naverPayAmount: Int,
    val cancelledAmount: Int, val cancelledCount: Int, val isClosed: Boolean
)

// ─── Statistics ──────────────────────────────────────
@Serializable data class MenuSalesResponse(val menuId: Long, val menuName: String, val categoryName: String, val totalQuantity: Int, val totalRevenue: Int)
@Serializable data class RevenueResponse(val date: String, val totalRevenue: Int, val totalOrders: Int)
@Serializable data class HourlyResponse(val hour: Int, val orderCount: Int, val revenue: Int)
@Serializable data class CategorySalesResponse(val categoryId: Long, val categoryName: String, val totalRevenue: Int, val percentage: Double)

// ─── Store ───────────────────────────────────────────
@Serializable data class StoreResponse(val id: Long, val name: String, val openTime: String, val closeTime: String, val isOpen: Boolean, val hideAdminButton: Boolean = false)
@Serializable data class KioskStoreResponse(val id: Long, val name: String, val openTime: String, val closeTime: String, val isOpen: Boolean, val hideAdminButton: Boolean)
@Serializable data class UpdateStoreRequest(val name: String, val openTime: String, val closeTime: String, val isOpen: Boolean, val hideAdminButton: Boolean = false)
@Serializable data class UploadResponse(val url: String)

// ─── HQ ──────────────────────────────────────────────
@Serializable data class HqStoreResponse(val id: Long, val name: String, val code: String, val dbName: String, val status: String, val createdAt: String)
@Serializable data class CreateHqStoreRequest(val name: String, val code: String)
@Serializable data class UpdateHqStoreRequest(val name: String, val code: String, val status: String)
@Serializable data class HqAdminResponse(val id: Long, val username: String, val name: String, val role: String, val storeId: Long? = null)
@Serializable data class CreateAdminRequest(val username: String, val password: String, val name: String, val role: String, val storeId: Long? = null)
@Serializable data class UpdateAdminRequest(val name: String, val role: String, val storeId: Long? = null, val password: String? = null)
@Serializable data class StoreSummaryResponse(val storeId: Long, val storeName: String, val totalRevenue: Int, val totalOrders: Int, val isClosed: Boolean)

// ─── Domain → Response 변환 ──────────────────────────

fun Category.toResponse() = CategoryResponse(id, name, displayOrder)

fun Menu.toResponse() = MenuResponse(id, categoryId, name, description, price, imageUrl, isSoldOut, displayOrder)

fun MenuWithOptions.toDetailResponse() = MenuDetailResponse(
    id = menu.id, categoryId = menu.categoryId, name = menu.name,
    description = menu.description, price = menu.price, imageUrl = menu.imageUrl,
    isSoldOut = menu.isSoldOut,
    options = options.map { opt ->
        MenuOptionResponse(
            id = opt.option.id, name = opt.option.name,
            isRequired = opt.option.isRequired, maxSelection = opt.option.maxSelection,
            items = opt.items.map { MenuOptionItemResponse(it.id, it.name, it.additionalPrice) }
        )
    }
)

fun OrderWithItems.toResponse() = OrderResponse(
    id = order.id, orderNumber = order.orderNumber, tableId = order.tableId,
    status = order.status.name, totalAmount = order.totalAmount,
    items = items.map { OrderItemResponse(it.id, it.menuId, it.menuName, it.quantity, it.unitPrice, it.totalPrice, it.selectedOptions) },
    createdAt = order.createdAt.toString()
)

fun Payment.toResponse() = PaymentResponse(
    id = id, orderId = orderId, method = method.name, amount = amount,
    status = status.name, approvalNumber = approvalNumber, createdAt = createdAt.toString()
)

fun KioskTable.toResponse() = TableResponse(id, tableNumber, deviceId, status.name)

fun KioskTable.toKioskResponse() = KioskTableResponse(id, tableNumber, status.name)

fun Settlement.toResponse() = SettlementResponse(
    date.toString(), totalRevenue, totalOrders, cardAmount, cashAmount,
    kakaoPayAmount, naverPayAmount, cancelledAmount, cancelledCount, isClosed
)

fun Store.toResponse() = StoreResponse(id, name, openTime.toString(), closeTime.toString(), isOpen, hideAdminButton)

fun Store.toKioskResponse() = KioskStoreResponse(id, name, openTime.toString(), closeTime.toString(), isOpen, hideAdminButton)

fun HqStore.toResponse() = HqStoreResponse(id, name, code, dbName, status.name, createdAt.toString())

fun Admin.toAdminResponse() = AdminResponse(id, username, name, role.name, storeId)

fun Admin.toHqAdminResponse() = HqAdminResponse(id, username, name, role.name, storeId)

fun MenuSalesStatistic.toResponse() = MenuSalesResponse(menuId, menuName, categoryName, totalQuantity, totalRevenue)

fun RevenueStatistic.toResponse() = RevenueResponse(date.toString(), totalRevenue, totalOrders)

fun HourlyStatistic.toResponse() = HourlyResponse(hour, orderCount, revenue)

fun CategorySalesStatistic.toResponse() = CategorySalesResponse(categoryId, categoryName, totalRevenue, percentage)
