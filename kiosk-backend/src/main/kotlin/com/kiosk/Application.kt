package com.kiosk

import com.kiosk.application.StoreUseCase
import com.kiosk.application.TableUseCase
import com.kiosk.infrastructure.db.DatabaseFactory
import com.kiosk.infrastructure.db.TenantContext
import com.kiosk.plugins.*
import com.kiosk.plugins.JwtConfig.configureAuthentication
import com.kiosk.routes.*
import com.kiosk.websocket.syncWebSocket
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.http.content.*
import io.ktor.server.netty.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.server.websocket.*
import org.koin.ktor.ext.inject
import java.io.File
import java.time.Duration

fun main(args: Array<String>): Unit = EngineMain.main(args)

fun Application.module() {
    DatabaseFactory.init()

    configureSerialization()
    configureCORS()
    configureStatusPages()
    configureAuthentication()
    configureDI()

    install(WebSockets) {
        pingPeriod = Duration.ofSeconds(15)
        timeout = Duration.ofSeconds(15)
        maxFrameSize = Long.MAX_VALUE
        masking = false
    }

    routing {
        staticFiles("/static/uploads", File("uploads"))

        // 키오스크 API (storeId 쿼리 파라미터로 TenantContext 설정)
        route("/api/v1/kiosk") {
            intercept(ApplicationCallPipeline.Call) {
                if (TenantContext.getOrNull() == null) {
                    val storeId = call.request.queryParameters["storeId"]?.toLongOrNull()
                        ?: return@intercept call.respond(HttpStatusCode.BadRequest, "storeId is required")
                    TenantContext.set(storeId)
                }
            }
            menuRoutes()
            orderRoutes()
            paymentRoutes()

            val tableUseCase by inject<TableUseCase>()
            get("/tables") {
                call.respond(tableUseCase.getTables().map { it.toKioskResponse() })
            }

            val storeUseCase by inject<StoreUseCase>()
            get("/store") {
                call.respond(storeUseCase.getStore().toKioskResponse())
            }
        }
        adminRoutes()
        hqRoutes()
        kitchenRoutes()
        syncWebSocket()
    }
}
