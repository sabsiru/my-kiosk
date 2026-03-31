package com.kiosk.domain.model

import java.time.LocalDate

data class MenuSalesStatistic(
    val menuId: Long,
    val menuName: String,
    val categoryName: String,
    val totalQuantity: Int,
    val totalRevenue: Int
)

data class RevenueStatistic(
    val date: LocalDate,
    val totalRevenue: Int,
    val totalOrders: Int
)

data class HourlyStatistic(
    val hour: Int,
    val orderCount: Int,
    val revenue: Int
)

data class CategorySalesStatistic(
    val categoryId: Long,
    val categoryName: String,
    val totalRevenue: Int,
    val percentage: Double
)
