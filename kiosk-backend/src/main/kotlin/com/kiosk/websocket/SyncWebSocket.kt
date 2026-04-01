package com.kiosk.websocket

import io.ktor.server.routing.*
import io.ktor.server.websocket.*
import io.ktor.websocket.*
import kotlinx.coroutines.channels.ClosedReceiveChannelException
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.util.concurrent.ConcurrentHashMap

private data class StoreConnection(val storeId: Long, val session: WebSocketServerSession)

object SyncManager {
    private val logger = LoggerFactory.getLogger(SyncManager::class.java)

    private val kioskConnections = ConcurrentHashMap<String, StoreConnection>()
    private val kitchenConnections = ConcurrentHashMap<String, StoreConnection>()
    private val orderStatusConnections = ConcurrentHashMap<String, StoreConnection>()

    fun addKioskConnection(id: String, storeId: Long, session: WebSocketServerSession) {
        kioskConnections[id] = StoreConnection(storeId, session)
    }

    fun removeKioskConnection(id: String) {
        kioskConnections.remove(id)
    }

    fun addKitchenConnection(id: String, storeId: Long, session: WebSocketServerSession) {
        kitchenConnections[id] = StoreConnection(storeId, session)
    }

    fun removeKitchenConnection(id: String) {
        kitchenConnections.remove(id)
    }

    fun addOrderStatusConnection(id: String, storeId: Long, session: WebSocketServerSession) {
        orderStatusConnections[id] = StoreConnection(storeId, session)
    }

    fun removeOrderStatusConnection(id: String) {
        orderStatusConnections.remove(id)
    }

    suspend fun broadcastToKiosks(storeId: Long, event: SyncEvent) {
        broadcast(kioskConnections, storeId, event)
    }

    suspend fun broadcastToKitchen(storeId: Long, event: SyncEvent) {
        broadcast(kitchenConnections, storeId, event)
    }

    suspend fun broadcastOrderStatus(storeId: Long, event: SyncEvent) {
        broadcast(orderStatusConnections, storeId, event)
    }

    private suspend fun broadcast(
        connections: ConcurrentHashMap<String, StoreConnection>,
        storeId: Long,
        event: SyncEvent
    ) {
        val message = Json.encodeToString(event)
        val deadConnections = mutableListOf<String>()

        connections.forEach { (id, conn) ->
            if (conn.storeId == storeId) {
                try {
                    conn.session.send(Frame.Text(message))
                } catch (e: Exception) {
                    logger.warn("WebSocket broadcast 실패 (connectionId=$id, storeId=$storeId): ${e.message}")
                    deadConnections.add(id)
                }
            }
        }

        deadConnections.forEach { connections.remove(it) }
    }
}

enum class SyncEventType {
    NEW_ORDER,
    ORDER_STATUS_CHANGED,
    TABLE_CHECKOUT,
    MENU_UPDATED,
    STORE_UPDATED
}

@Serializable
data class SyncEvent(
    val type: String,
    val data: String
) {
    constructor(type: SyncEventType, data: String) : this(type.name, data)
}

fun Route.syncWebSocket() {
    webSocket("/ws/sync") {
        val storeId = call.request.queryParameters["storeId"]?.toLongOrNull() ?: return@webSocket close(
            CloseReason(CloseReason.Codes.VIOLATED_POLICY, "storeId required")
        )
        val connectionId = java.util.UUID.randomUUID().toString()
        SyncManager.addKioskConnection(connectionId, storeId, this)
        try {
            for (frame in incoming) { /* 키오스크는 주로 수신만 */ }
        } catch (_: ClosedReceiveChannelException) {
        } finally {
            SyncManager.removeKioskConnection(connectionId)
        }
    }

    webSocket("/ws/kitchen") {
        val storeId = call.request.queryParameters["storeId"]?.toLongOrNull() ?: return@webSocket close(
            CloseReason(CloseReason.Codes.VIOLATED_POLICY, "storeId required")
        )
        val connectionId = java.util.UUID.randomUUID().toString()
        SyncManager.addKitchenConnection(connectionId, storeId, this)
        try {
            for (frame in incoming) { /* 주방도 주로 수신 */ }
        } catch (_: ClosedReceiveChannelException) {
        } finally {
            SyncManager.removeKitchenConnection(connectionId)
        }
    }

    webSocket("/ws/order-status") {
        val storeId = call.request.queryParameters["storeId"]?.toLongOrNull() ?: return@webSocket close(
            CloseReason(CloseReason.Codes.VIOLATED_POLICY, "storeId required")
        )
        val connectionId = java.util.UUID.randomUUID().toString()
        SyncManager.addOrderStatusConnection(connectionId, storeId, this)
        try {
            for (frame in incoming) { /* 주문 상태 수신 */ }
        } catch (_: ClosedReceiveChannelException) {
        } finally {
            SyncManager.removeOrderStatusConnection(connectionId)
        }
    }
}
