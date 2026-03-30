package com.kiosk.routes

import com.kiosk.application.MenuUseCase
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject

fun Route.menuRoutes() {
    val menuUseCase by inject<MenuUseCase>()

    get("/categories") {
        val categories = menuUseCase.getCategories()
        call.respond(categories.map { it.toCategoryResponse() })
    }

    get("/categories/{id}/menus") {
        val categoryId = call.parameters["id"]?.toLongOrNull()
            ?: return@get call.respond(HttpStatusCode.BadRequest, "잘못된 카테고리 ID")
        val menus = menuUseCase.getMenusByCategory(categoryId)
        call.respond(menus.map { it.toMenuResponse() })
    }

    get("/menus/{id}") {
        val menuId = call.parameters["id"]?.toLongOrNull()
            ?: return@get call.respond(HttpStatusCode.BadRequest, "잘못된 메뉴 ID")
        val detail = menuUseCase.getMenuDetail(menuId)
        call.respond(detail.toMenuDetailResponse())
    }
}

@Serializable
data class CategoryResponse(val id: Long, val name: String, val displayOrder: Int)

@Serializable
data class MenuResponse(
    val id: Long,
    val categoryId: Long,
    val name: String,
    val description: String,
    val price: Int,
    val imageUrl: String?,
    val isSoldOut: Boolean,
    val displayOrder: Int
)

@Serializable
data class MenuDetailResponse(
    val id: Long,
    val categoryId: Long,
    val name: String,
    val description: String,
    val price: Int,
    val imageUrl: String?,
    val isSoldOut: Boolean,
    val options: List<MenuOptionResponse>
)

@Serializable
data class MenuOptionResponse(
    val id: Long,
    val name: String,
    val isRequired: Boolean,
    val maxSelection: Int,
    val items: List<MenuOptionItemResponse>
)

@Serializable
data class MenuOptionItemResponse(
    val id: Long,
    val name: String,
    val additionalPrice: Int
)

private fun com.kiosk.domain.model.Category.toCategoryResponse() =
    CategoryResponse(id, name, displayOrder)

private fun com.kiosk.domain.model.Menu.toMenuResponse() =
    MenuResponse(id, categoryId, name, description, price, imageUrl, isSoldOut, displayOrder)

private fun com.kiosk.domain.model.MenuWithOptions.toMenuDetailResponse() =
    MenuDetailResponse(
        id = menu.id,
        categoryId = menu.categoryId,
        name = menu.name,
        description = menu.description,
        price = menu.price,
        imageUrl = menu.imageUrl,
        isSoldOut = menu.isSoldOut,
        options = options.map { optWithItems ->
            MenuOptionResponse(
                id = optWithItems.option.id,
                name = optWithItems.option.name,
                isRequired = optWithItems.option.isRequired,
                maxSelection = optWithItems.option.maxSelection,
                items = optWithItems.items.map { item ->
                    MenuOptionItemResponse(item.id, item.name, item.additionalPrice)
                }
            )
        }
    )
