package com.kiosk.infrastructure.db

import at.favre.lib.crypto.bcrypt.BCrypt
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.SchemaUtils
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.LocalDateTime
import java.time.LocalTime

object DatabaseFactory {

    private val mysqlHost = System.getenv("MYSQL_HOST") ?: "localhost"
    private val mysqlPort = System.getenv("MYSQL_PORT") ?: "13307"
    private val mysqlUser = System.getenv("MYSQL_USER") ?: "root"
    private val mysqlPassword = System.getenv("MYSQL_PASSWORD") ?: "kiosk1234"

    private lateinit var hqDatabase: Database
    private val storeDataSources = mutableMapOf<String, Database>()

    // 매장 DB 테이블 목록
    private val storeTables = arrayOf(
        CategoryTable, MenuTable, MenuOptionTable, MenuOptionItemTable,
        OrderTable, OrderItemTable, PaymentTable,
        KioskTableTable, SettlementTable, StoreTable
    )

    fun init() {
        // 1. 본사 DB 연결 + 스키마 생성
        hqDatabase = connectMysql("kiosk_hq")
        transaction(hqDatabase) {
            SchemaUtils.create(HqStoreTable, HqAdminTable)
        }

        // 2. 시드 데이터 삽입
        seedHqData()

        // 3. 기존 매장 DB 연결
        transaction(hqDatabase) {
            HqStoreTable.selectAll().forEach { row ->
                val dbName = row[HqStoreTable.dbName]
                connectStoreDb(dbName)
            }
        }
    }

    fun getHqDatabase(): Database = hqDatabase

    fun getStoreDatabase(storeId: Long): Database {
        val dbName = "kiosk_store_$storeId"
        return storeDataSources[dbName]
            ?: throw IllegalArgumentException("매장 DB를 찾을 수 없습니다: $dbName")
    }

    fun getStoreDatabaseByName(dbName: String): Database {
        return storeDataSources[dbName]
            ?: throw IllegalArgumentException("매장 DB를 찾을 수 없습니다: $dbName")
    }

    fun createStoreDb(storeId: Long): Database {
        val dbName = "kiosk_store_$storeId"
        return connectStoreDb(dbName)
    }

    private fun connectStoreDb(dbName: String): Database {
        val db = connectMysql(dbName)
        transaction(db) {
            SchemaUtils.createMissingTablesAndColumns(*storeTables)
        }
        // 매장 기본 설정 삽입
        transaction(db) {
            if (StoreTable.selectAll().empty()) {
                StoreTable.insert {
                    it[name] = "새 매장"
                    it[openTime] = LocalTime.of(9, 0)
                    it[closeTime] = LocalTime.of(22, 0)
                    it[isOpen] = false
                }
            }
        }
        storeDataSources[dbName] = db
        return db
    }

    private fun connectMysql(dbName: String): Database {
        // MySQL에서 DB가 없으면 생성
        val rootDb = Database.connect(
            url = "jdbc:mysql://$mysqlHost:$mysqlPort?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul",
            driver = "com.mysql.cj.jdbc.Driver",
            user = mysqlUser,
            password = mysqlPassword
        )
        transaction(rootDb) {
            exec("CREATE DATABASE IF NOT EXISTS `$dbName` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
        }

        return Database.connect(
            url = "jdbc:mysql://$mysqlHost:$mysqlPort/$dbName?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul",
            driver = "com.mysql.cj.jdbc.Driver",
            user = mysqlUser,
            password = mysqlPassword
        )
    }

    private fun seedHqData() {
        transaction(hqDatabase) {
            // 관리자 계정이 없으면 시드 삽입
            if (HqAdminTable.selectAll().empty()) {
                val passwordHash = BCrypt.withDefaults().hashToString(12, "admin123".toCharArray())

                // 본사 관리자
                HqAdminTable.insert {
                    it[username] = "admin"
                    it[HqAdminTable.passwordHash] = passwordHash
                    it[name] = "본사 관리자"
                    it[role] = "HQ_ADMIN"
                    it[storeId] = null
                }

                // 매장1 생성
                val store1Id = HqStoreTable.insert {
                    it[name] = "쿠로치쿠 강남역점"
                    it[code] = "GANGNAM"
                    it[dbName] = "kiosk_store_1"
                    it[status] = "ACTIVE"
                    it[createdAt] = LocalDateTime.now()
                }[HqStoreTable.id]

                HqAdminTable.insert {
                    it[username] = "store1"
                    it[HqAdminTable.passwordHash] = passwordHash
                    it[name] = "강남점 관리자"
                    it[role] = "STORE_OWNER"
                    it[storeId] = store1Id
                }

                // 매장2 생성
                val store2Id = HqStoreTable.insert {
                    it[name] = "쿠로치쿠 홍대입구점"
                    it[code] = "HONGDAE"
                    it[dbName] = "kiosk_store_2"
                    it[status] = "ACTIVE"
                    it[createdAt] = LocalDateTime.now()
                }[HqStoreTable.id]

                HqAdminTable.insert {
                    it[username] = "store2"
                    it[HqAdminTable.passwordHash] = passwordHash
                    it[name] = "홍대점 관리자"
                    it[role] = "STORE_OWNER"
                    it[storeId] = store2Id
                }
            }
        }
    }
}
