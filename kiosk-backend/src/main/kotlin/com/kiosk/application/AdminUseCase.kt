package com.kiosk.application

import at.favre.lib.crypto.bcrypt.BCrypt
import com.kiosk.domain.model.Admin
import com.kiosk.domain.model.AdminRole
import com.kiosk.domain.model.AppException
import com.kiosk.domain.repository.AdminRepository

class AdminUseCase(private val adminRepository: AdminRepository) {

    suspend fun login(username: String, password: String): Admin {
        val admin = adminRepository.findByUsername(username)
            ?: throw AppException.Unauthorized("아이디 또는 비밀번호가 잘못되었습니다")

        val result = BCrypt.verifyer().verify(password.toCharArray(), admin.passwordHash)
        if (!result.verified) {
            throw AppException.Unauthorized("아이디 또는 비밀번호가 잘못되었습니다")
        }

        return admin
    }

    suspend fun getAdmin(id: Long): Admin =
        adminRepository.findById(id)
            ?: throw AppException.NotFound("관리자를 찾을 수 없습니다")

    suspend fun getAdmins(): List<Admin> =
        adminRepository.findAll()

    suspend fun getAdminsByStore(storeId: Long): List<Admin> =
        adminRepository.findByStoreId(storeId)

    suspend fun createAdmin(username: String, password: String, name: String, role: AdminRole, storeId: Long?): Admin {
        val existing = adminRepository.findByUsername(username)
        if (existing != null) {
            throw AppException.Conflict("이미 존재하는 아이디입니다: $username")
        }

        val passwordHash = BCrypt.withDefaults().hashToString(12, password.toCharArray())
        return adminRepository.create(
            Admin(
                username = username,
                passwordHash = passwordHash,
                name = name,
                role = role,
                storeId = storeId
            )
        )
    }

    suspend fun updateAdmin(id: Long, name: String, role: AdminRole, storeId: Long?, password: String?): Admin {
        val admin = adminRepository.findById(id)
            ?: throw AppException.NotFound("관리자를 찾을 수 없습니다: $id")

        val passwordHash = if (password != null) {
            BCrypt.withDefaults().hashToString(12, password.toCharArray())
        } else {
            admin.passwordHash
        }

        return adminRepository.update(
            admin.copy(name = name, role = role, storeId = storeId, passwordHash = passwordHash)
        )
    }

    suspend fun deleteAdmin(id: Long, currentAdminId: Long) {
        val admin = adminRepository.findById(id)
            ?: throw AppException.NotFound("관리자를 찾을 수 없습니다: $id")

        if (admin.id == currentAdminId) {
            throw AppException.BadRequest("자기 자신은 삭제할 수 없습니다")
        }

        adminRepository.delete(id)
    }
}
