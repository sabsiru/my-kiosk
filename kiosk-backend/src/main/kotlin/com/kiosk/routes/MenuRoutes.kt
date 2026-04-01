package com.kiosk.routes

import com.kiosk.application.CategoryUseCase
import com.kiosk.application.MenuUseCase
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject

fun Route.menuRoutes() {
    val categoryUseCase by inject<CategoryUseCase>()
    val menuUseCase by inject<MenuUseCase>()

    get("/categories") {
        val categories = categoryUseCase.getCategories()
        call.respond(categories.map { it.toResponse() })
    }

    get("/categories/{id}/menus") {
        val categoryId = call.pathId()
        val menus = menuUseCase.getMenusByCategory(categoryId)
        call.respond(menus.map { it.toResponse() })
    }

    get("/menus/{id}") {
        val menuId = call.pathId()
        val detail = menuUseCase.getMenuDetail(menuId)
        call.respond(detail.toDetailResponse())
    }
}
