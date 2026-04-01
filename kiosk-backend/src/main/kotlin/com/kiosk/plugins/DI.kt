package com.kiosk.plugins

import com.kiosk.application.*
import com.kiosk.domain.repository.*
import com.kiosk.infrastructure.repository.*
import io.ktor.server.application.*
import org.koin.dsl.module
import org.koin.ktor.plugin.Koin
import org.koin.logger.slf4jLogger

fun Application.configureDI() {
    install(Koin) {
        slf4jLogger()
        modules(appModule)
    }
}

val appModule = module {
    // Repositories
    single<CategoryRepository> { CategoryRepositoryImpl() }
    single<MenuOptionRepository> { MenuOptionRepositoryImpl() }
    single<MenuRepository> { MenuRepositoryImpl() }
    single<OrderRepository> { OrderRepositoryImpl() }
    single<PaymentRepository> { PaymentRepositoryImpl() }
    single<TableRepository> { TableRepositoryImpl() }
    single<SettlementRepository> { SettlementRepositoryImpl() }
    single<AdminRepository> { AdminRepositoryImpl() }
    single<StoreRepository> { StoreRepositoryImpl() }
    single<HqStoreRepository> { HqStoreRepositoryImpl() }
    single<StoreDbRepository> { StoreDbRepositoryImpl() }

    // UseCases
    single { CategoryUseCase(get()) }
    single { MenuUseCase(get(), get()) }
    single { OrderUseCase(get(), get(), get()) }
    single { PaymentUseCase(get(), get()) }
    single { TableUseCase(get(), get(), get()) }
    single { SettlementUseCase(get(), get(), get()) }
    single { StatisticsUseCase(get(), get(), get()) }
    single { AdminUseCase(get()) }
    single { StoreUseCase(get(), get()) }
    single { HqUseCase(get(), get()) }
}
