package com.kiosk.application

import com.kiosk.domain.model.*
import com.kiosk.domain.repository.MenuRepository
import com.kiosk.domain.repository.OrderRepository
import java.time.LocalDate

class StatisticsUseCase(
    private val orderRepository: OrderRepository,
    private val menuRepository: MenuRepository
) {
    suspend fun getMenuSales(from: LocalDate, to: LocalDate): List<MenuSalesStatistic> {
        val orders = orderRepository.findAll(
            from = from.atStartOfDay(),
            to = to.plusDays(1).atStartOfDay(),
            limit = Int.MAX_VALUE
        ).filter { it.order.status != OrderStatus.CANCELLED }

        val categories = menuRepository.findAllCategories().associateBy { it.id }
        val allMenus = menuRepository.findAllMenus().associateBy { it.id }

        val menuSales = mutableMapOf<Long, Triple<String, String, MutableList<OrderItem>>>()
        for (order in orders) {
            for (item in order.items) {
                val menu = allMenus[item.menuId]
                val categoryName = menu?.let { categories[it.categoryId]?.name } ?: "삭제된 카테고리"
                val entry = menuSales.getOrPut(item.menuId) {
                    Triple(item.menuName, categoryName, mutableListOf())
                }
                entry.third.add(item)
            }
        }

        return menuSales.map { (menuId, triple) ->
            MenuSalesStatistic(
                menuId = menuId,
                menuName = triple.first,
                categoryName = triple.second,
                totalQuantity = triple.third.sumOf { it.quantity },
                totalRevenue = triple.third.sumOf { it.totalPrice }
            )
        }.sortedByDescending { it.totalQuantity }
    }

    suspend fun getRevenueTrend(from: LocalDate, to: LocalDate): List<RevenueStatistic> {
        val orders = orderRepository.findAll(
            from = from.atStartOfDay(),
            to = to.plusDays(1).atStartOfDay(),
            limit = Int.MAX_VALUE
        ).filter { it.order.status != OrderStatus.CANCELLED }

        return orders.groupBy { it.order.createdAt.toLocalDate() }
            .map { (date, dayOrders) ->
                RevenueStatistic(
                    date = date,
                    totalRevenue = dayOrders.sumOf { it.order.totalAmount },
                    totalOrders = dayOrders.size
                )
            }
            .sortedBy { it.date }
    }

    suspend fun getHourlyDistribution(date: LocalDate): List<HourlyStatistic> {
        val orders = orderRepository.findAll(
            from = date.atStartOfDay(),
            to = date.plusDays(1).atStartOfDay(),
            limit = Int.MAX_VALUE
        ).filter { it.order.status != OrderStatus.CANCELLED }

        return (0..23).map { hour ->
            val hourOrders = orders.filter { it.order.createdAt.hour == hour }
            HourlyStatistic(
                hour = hour,
                orderCount = hourOrders.size,
                revenue = hourOrders.sumOf { it.order.totalAmount }
            )
        }
    }

    suspend fun getCategorySales(from: LocalDate, to: LocalDate): List<CategorySalesStatistic> {
        val orders = orderRepository.findAll(
            from = from.atStartOfDay(),
            to = to.plusDays(1).atStartOfDay(),
            limit = Int.MAX_VALUE
        ).filter { it.order.status != OrderStatus.CANCELLED }

        val categories = menuRepository.findAllCategories().associateBy { it.id }
        val allMenus = menuRepository.findAllMenus().associateBy { it.id }
        val categorySales = mutableMapOf<Long, Int>()

        for (order in orders) {
            for (item in order.items) {
                val menu = allMenus[item.menuId]
                if (menu != null) {
                    categorySales[menu.categoryId] = (categorySales[menu.categoryId] ?: 0) + item.totalPrice
                }
            }
        }

        val totalRevenue = categorySales.values.sum().toDouble()
        return categorySales.map { (categoryId, revenue) ->
            CategorySalesStatistic(
                categoryId = categoryId,
                categoryName = categories[categoryId]?.name ?: "삭제된 카테고리",
                totalRevenue = revenue,
                percentage = if (totalRevenue > 0) (revenue / totalRevenue * 100) else 0.0
            )
        }.sortedByDescending { it.totalRevenue }
    }
}
