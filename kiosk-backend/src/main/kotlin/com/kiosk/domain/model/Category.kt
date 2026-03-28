package com.kiosk.domain.model

data class Category(
    val id: Long = 0,
    val name: String,
    val displayOrder: Int = 0,
    val isActive: Boolean = true
)
