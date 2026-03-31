package com.kiosk.domain.model

data class Menu(
    val id: Long = 0,
    val categoryId: Long,
    val name: String,
    val description: String = "",
    val price: Int,
    val imageUrl: String? = null,
    val isSoldOut: Boolean = false,
    val isActive: Boolean = true,
    val displayOrder: Int = 0
)

data class MenuOption(
    val id: Long = 0,
    val menuId: Long,
    val name: String,
    val isRequired: Boolean = false,
    val maxSelection: Int = 1
)

data class MenuOptionItem(
    val id: Long = 0,
    val optionId: Long,
    val name: String,
    val additionalPrice: Int = 0
)

data class MenuWithOptions(
    val menu: Menu,
    val options: List<MenuOptionWithItems>
)

data class MenuOptionWithItems(
    val option: MenuOption,
    val items: List<MenuOptionItem>
)
