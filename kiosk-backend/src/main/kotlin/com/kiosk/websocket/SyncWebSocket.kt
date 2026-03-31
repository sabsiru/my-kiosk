package com.kiosk.websocket

import io.ktor.server.routing.*
import io.ktor.server.websocket.*
import io.ktor.websocket.*
import kotlinx.coroutines.channels.ClosedReceiveChannelException
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

object SyncManager {
    private val kioskConnections = ConcurrentHashMap<String, WebSocketServerSession>()
    private val kitchenConnections = ConcurrentHashMap<String, WebSocketServerSession>()
    private val orderStatusConnections = ConcurrentHashMap<String, WebSocketServerSession>()

    fun addKioskConnection(id: String, session: WebSocketServerSession) {
        kioskConnections[id] = session
    }

    fun removeKioskConnection(id: String) {
        kioskConnections.remove(id)
    }

    fun addKitchenConnection(id: String, session: WebSocketServerSession) {
        kitchenConnections[id] = session
    }

    fun removeKitchenConnection(id: String) {
        kitchenConnections.remove(id)
    }

    fun addOrderStatusConnection(id: String, session: WebSocketServerSession) {
        orderStatusConnections[id] = session
    }

    fun removeOrderStatusConnection(id: String) {
        orderStatusConnections.remove(id)
    }

    suspend fun broadcastToKiosks(event: SyncEvent) {
        val message = Json.encodeToString(event)
        kioskConnections.values.forEach { session ->
            try {
                session.send(Frame.Text(message))
            } catch (_: Exception) {}
        }
    }

    suspend fun broadcastToKitchen(event: SyncEvent) {
        val message = Json.encodeToString(event)
        kitchenConnections.values.forEach { session ->
            try {
                session.send(Frame.Text(message))
            } catch (_: Exception) {}
        }
    }

    suspend fun broadcastOrderStatus(event: SyncEvent) {
        val message = Json.encodeToString(event)
        orderStatusConnections.values.forEach { session ->
            try {
                session.send(Frame.Text(message))
            } catch (_: Exception) {}
        }
    }
}

@Serializable
data class SyncEvent(
    val type: String,  // MENU_UPDATED, SOLD_OUT_CHANGED, STORE_UPDATED, NEW_ORDER, ORDER_STATUS_CHANGED
    val data: String   // JSON payload
)

fun Route.syncWebSocket() {
    webSocket("/ws/sync") {
        val connectionId = java.util.UUID.randomUUID().toString()
        SyncManager.addKioskConnection(connectionId, this)
        try {
            for (frame in incoming) {
                // 키오스크는 주로 수신만 함
            }
        } catch (_: ClosedReceiveChannelException) {
        } finally {
            SyncManager.removeKioskConnection(connectionId)
        }
    }

    webSocket("/ws/kitchen") {
        val connectionId = java.util.UUID.randomUUID().toString()
        SyncManager.addKitchenConnection(connectionId, this)
        try {
            for (frame in incoming) {
                // 주방도 주로 수신
            }
        } catch (_: ClosedReceiveChannelException) {
        } finally {
            SyncManager.removeKitchenConnection(connectionId)
        }
    }

    webSocket("/ws/order-status") {
        val connectionId = java.util.UUID.randomUUID().toString()
        SyncManager.addOrderStatusConnection(connectionId, this)
        try {
            for (frame in incoming) {
                // 주문 상태 수신
            }
        } catch (_: ClosedReceiveChannelException) {
        } finally {
            SyncManager.removeOrderStatusConnection(connectionId)
        }
    }
}
