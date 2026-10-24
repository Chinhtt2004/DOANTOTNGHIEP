-- TEST FIXTURE ONLY: frozen original V5 for migration regression tests.
-- Do not use this file for deployment; use database/schema.sql instead.
-- Core workflow design 2026-10-23; exactly 39 business/support tables, no AI storage.
-- CREATE A NEW DATABASE ONLY. This is not a Flyway migration or an upgrade script.
-- MySQL 8.0.16+ / InnoDB; recommended MySQL 8.4. Do not use --force when importing.
-- Never change the USE target to the old database; keep the existing migrations intact.
CREATE DATABASE `room_rental_v5_20261023` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `room_rental_v5_20261023`;
SET time_zone = '+00:00';

-- Tài khoản chung; role là vai trò hiển thị, quyền thực tế lấy từ các bảng vai trò.
CREATE TABLE `users` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(150),
  `phone_number` VARCHAR(20),
  `password_hash` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(150) NOT NULL,
  `role` VARCHAR(40) NOT NULL DEFAULT 'TENANT',
  `status` VARCHAR(40) NOT NULL DEFAULT 'ACTIVE',
  `phone_verified_at` DATETIME(6),
  `locked_at` DATETIME(6),
  `in_app_enabled` BOOLEAN NOT NULL DEFAULT TRUE,
  `email_enabled` BOOLEAN NOT NULL DEFAULT FALSE,
  `push_enabled` BOOLEAN NOT NULL DEFAULT FALSE,
  `lock_reason` VARCHAR(1000),
  `locked_by_id` BIGINT,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_users_email` (`email`),
  UNIQUE KEY `uq_users_phone` (`phone_number`),
  KEY `ix_users_status` (`status`),
  CONSTRAINT `ck_users_role` CHECK (role IN ('TENANT', 'LANDLORD', 'ADMIN')),
  CONSTRAINT `ck_users_status` CHECK (status IN ('ACTIVE', 'LOCKED', 'DISABLED')),
  CONSTRAINT `ck_users_bool_in_app_enabled` CHECK (in_app_enabled IN (0,1)),
  CONSTRAINT `ck_users_bool_email_enabled` CHECK (email_enabled IN (0,1)),
  CONSTRAINT `ck_users_bool_push_enabled` CHECK (push_enabled IN (0,1)),
  CONSTRAINT `ck_users_contact` CHECK (email IS NOT NULL OR phone_number IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Một user có thể có nhiều dòng vai trò; không dùng kế thừa loại trừ nhau.
CREATE TABLE `tenants` (
  `id` BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Một user có thể có nhiều dòng vai trò; không dùng kế thừa loại trừ nhau.
CREATE TABLE `landlords` (
  `id` BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Một user có thể có nhiều dòng vai trò; không dùng kế thừa loại trừ nhau.
CREATE TABLE `admins` (
  `id` BIGINT NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Hồ sơ cá nhân; thông tin riêng tư không mặc định công khai.
CREATE TABLE `personal_profiles` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `avatar_file_id` BIGINT,
  `address` VARCHAR(500),
  `gender` VARCHAR(30),
  `occupation` VARCHAR(150),
  `university` VARCHAR(200),
  `bio` TEXT,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_profiles_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Metadata file; kho file riêng tư. Ba FK ngữ cảnh hỗ trợ nhiều bằng chứng/ảnh/tài liệu chứng minh.
CREATE TABLE `files` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `owner_user_id` BIGINT NOT NULL,
  `storage_key` VARCHAR(500) NOT NULL,
  `original_name` VARCHAR(255) NOT NULL,
  `mime_type` VARCHAR(150) NOT NULL,
  `size_bytes` BIGINT NOT NULL,
  `sha256` CHAR(64) NOT NULL,
  `purpose` VARCHAR(40) NOT NULL,
  `visibility` VARCHAR(40) NOT NULL DEFAULT 'PRIVATE',
  `status` VARCHAR(40) NOT NULL DEFAULT 'STAGED',
  `report_id` BIGINT,
  `chat_message_id` BIGINT,
  `landlord_verification_id` BIGINT,
  `expires_at` DATETIME(6),
  `deleted_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_files_storage` (`storage_key`),
  KEY `ix_files_owner` (`owner_user_id`, `purpose`),
  CONSTRAINT `ck_files_purpose` CHECK (purpose IN ('AVATAR', 'POST_IMAGE', 'IDENTITY', 'LANDLORD_PROOF', 'CONTRACT', 'REPORT_EVIDENCE', 'CHAT_IMAGE')),
  CONSTRAINT `ck_files_visibility` CHECK (visibility IN ('PUBLIC', 'PRIVATE')),
  CONSTRAINT `ck_files_status` CHECK (status IN ('STAGED', 'ACTIVE', 'ARCHIVED', 'DELETED')),
  CONSTRAINT `ck_files_size` CHECK (size_bytes >= 0),
  CONSTRAINT `ck_files_parent_count` CHECK ((report_id IS NOT NULL) + (chat_message_id IS NOT NULL) + (landlord_verification_id IS NOT NULL) <= 1),
  CONSTRAINT `ck_files_private_documents` CHECK (purpose IN ('AVATAR','POST_IMAGE') OR visibility = 'PRIVATE')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Người nộp tham chiếu users vì chưa có quyền landlord; tài liệu quyền cho thuê liên kết qua files.
CREATE TABLE `landlord_verifications` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `applicant_user_id` BIGINT NOT NULL,
  `identity_number` VARCHAR(30) NOT NULL,
  `identity_file_id` BIGINT NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'PENDING',
  `rejection_reason` VARCHAR(1000),
  `reviewed_by_id` BIGINT,
  `reviewed_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `pending_applicant_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status = 'PENDING' THEN applicant_user_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_landlord_pending` (`pending_applicant_id`),
  KEY `ix_landlord_applicant` (`applicant_user_id`, `created_at`),
  CONSTRAINT `ck_landlord_verifications_status` CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN')),
  CONSTRAINT `ck_landlord_verifications_review` CHECK (status NOT IN ('APPROVED','REJECTED') OR (reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL)),
  CONSTRAINT `ck_landlord_verifications_rejected` CHECK (status <> 'REJECTED' OR rejection_reason IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Xét căn cước tùy chọn; không tự cấp quyền chủ trọ hoặc xác thực nhà nước.
CREATE TABLE `tenant_identity_verifications` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` BIGINT NOT NULL,
  `identity_number` VARCHAR(30) NOT NULL,
  `identity_file_id` BIGINT NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'PENDING',
  `reviewed_by_id` BIGINT,
  `rejection_reason` VARCHAR(1000),
  `reviewed_at` DATETIME(6),
  `retention_until` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `pending_tenant_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status = 'PENDING' THEN tenant_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_tenant_identity_pending` (`pending_tenant_id`),
  KEY `ix_tenant_identity_tenant` (`tenant_id`, `created_at`),
  CONSTRAINT `ck_tenant_identity_verifications_status` CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN')),
  CONSTRAINT `ck_tenant_identity_verifications_review` CHECK (status NOT IN ('APPROVED','REJECTED') OR (reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL)),
  CONSTRAINT `ck_tenant_identity_verifications_rejected` CHECK (status <> 'REJECTED' OR rejection_reason IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Phiên có thể thu hồi; JWT phải chứa session_key và máy chủ kiểm tra phiên mỗi request.
CREATE TABLE `auth_sessions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `session_key` CHAR(36) NOT NULL,
  `refresh_token_hash` CHAR(64),
  `expires_at` DATETIME(6) NOT NULL,
  `last_seen_at` DATETIME(6),
  `revoked_at` DATETIME(6),
  `revocation_reason` VARCHAR(500),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_sessions_key` (`session_key`),
  UNIQUE KEY `uq_sessions_refresh` (`refresh_token_hash`),
  KEY `ix_sessions_user` (`user_id`, `revoked_at`),
  CONSTRAINT `ck_auth_sessions_expiry` CHECK (expires_at > created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Mã dùng một lần: lưu HMAC/hash có bí mật máy chủ, không lưu OTP/token nguyên văn.
CREATE TABLE `verification_tokens` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `selector` CHAR(36) NOT NULL,
  `token_hash` CHAR(64) NOT NULL,
  `purpose` VARCHAR(40) NOT NULL,
  `target_value` VARCHAR(255),
  `target_room_tenant_id` BIGINT,
  `attempt_count` INT NOT NULL DEFAULT 0,
  `max_attempts` INT NOT NULL DEFAULT 5,
  `expires_at` DATETIME(6) NOT NULL,
  `consumed_at` DATETIME(6),
  `revoked_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_tokens_selector` (`selector`),
  KEY `ix_tokens_lookup` (`user_id`, `purpose`, `created_at`),
  KEY `ix_tokens_expiry` (`expires_at`),
  CONSTRAINT `ck_verification_tokens_purpose` CHECK (purpose IN ('PHONE_VERIFICATION', 'PASSWORD_RESET_OTP', 'PASSWORD_RESET_GRANT', 'OCCUPANT_LINK')),
  CONSTRAINT `ck_verification_tokens_attempts` CHECK (attempt_count >= 0 AND max_attempts > 0 AND attempt_count <= max_attempts),
  CONSTRAINT `ck_verification_tokens_expiry` CHECK (expires_at > created_at),
  CONSTRAINT `ck_verification_tokens_link_target` CHECK ((purpose = 'OCCUPANT_LINK' AND target_room_tenant_id IS NOT NULL) OR (purpose <> 'OCCUPANT_LINK' AND target_room_tenant_id IS NULL)),
  CONSTRAINT `ck_verification_tokens_phone_target` CHECK (purpose <> 'PHONE_VERIFICATION' OR target_value IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tọa độ nhà dùng chung cho các phòng; giữ nguyên chuỗi địa chỉ để hiển thị.
CREATE TABLE `rental_houses` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `landlord_id` BIGINT NOT NULL,
  `address` VARCHAR(500) NOT NULL,
  `province_code` VARCHAR(30) NOT NULL,
  `locality_code` VARCHAR(30),
  `area_label` VARCHAR(150),
  `latitude` DECIMAL(10,7),
  `longitude` DECIMAL(10,7),
  `notes` VARCHAR(2000),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_houses_id_landlord` (`id`, `landlord_id`),
  KEY `ix_houses_landlord` (`landlord_id`),
  KEY `ix_houses_location` (`province_code`, `locality_code`),
  CONSTRAINT `ck_rental_houses_coordinates` CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Phòng và bảng giá tham khảo hiện tại; không dùng status để thay danh sách người ở.
CREATE TABLE `rooms` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `house_id` BIGINT NOT NULL,
  `room_number` VARCHAR(100) NOT NULL,
  `area` DECIMAL(10,2) NOT NULL,
  `rent_price` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `deposit_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `max_occupants` INT NOT NULL,
  `allow_additional_occupants` BOOLEAN NOT NULL DEFAULT FALSE,
  `status` VARCHAR(40) NOT NULL DEFAULT 'AVAILABLE',
  `notes` VARCHAR(2000),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_rooms_number` (`house_id`, `room_number`),
  UNIQUE KEY `uq_rooms_id_house` (`id`, `house_id`),
  KEY `ix_rooms_status` (`status`),
  CONSTRAINT `ck_rooms_rent_price` CHECK (rent_price >= 0),
  CONSTRAINT `ck_rooms_deposit_amount` CHECK (deposit_amount >= 0),
  CONSTRAINT `ck_rooms_bool_allow_additional_occupants` CHECK (allow_additional_occupants IN (0,1)),
  CONSTRAINT `ck_rooms_status` CHECK (status IN ('AVAILABLE', 'RESERVED', 'OCCUPIED', 'MAINTENANCE')),
  CONSTRAINT `ck_rooms_area` CHECK (area > 0),
  CONSTRAINT `ck_rooms_capacity` CHECK (max_occupants > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Danh mục dịch vụ mẫu toàn hệ thống; mỗi nhà có thể chọn mẫu hoặc tạo dịch vụ riêng.
CREATE TABLE `rental_services` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `unit` VARCHAR(30) NOT NULL,
  `default_calculation_method` VARCHAR(40) NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_services_name` (`name`),
  CONSTRAINT `ck_rental_services_default_calculation_method` CHECK (default_calculation_method IN ('METERED', 'PER_PERSON', 'PER_ROOM'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dịch vụ thuộc một nhà; tên, đơn vị và giá mặc định có thể khác giữa các nhà.
-- Không xóa vật lý dịch vụ đã từng được dùng; is_active chỉ dừng áp dụng về sau.
CREATE TABLE `house_services` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `house_id` BIGINT NOT NULL,
  `catalog_service_id` BIGINT,
  `name` VARCHAR(100) NOT NULL,
  `unit` VARCHAR(30) NOT NULL,
  `default_unit_price` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `default_calculation_method` VARCHAR(40) NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_house_services_name` (`house_id`, `name`),
  UNIQUE KEY `uq_house_services_catalog` (`house_id`, `catalog_service_id`),
  UNIQUE KEY `uq_house_services_id_house` (`id`, `house_id`),
  CONSTRAINT `ck_house_services_default_unit_price` CHECK (default_unit_price >= 0),
  CONSTRAINT `ck_house_services_default_method` CHECK (default_calculation_method IN ('METERED', 'PER_PERSON', 'PER_ROOM')),
  CONSTRAINT `ck_house_services_bool_active` CHECK (is_active IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dịch vụ áp dụng cho từng phòng; NULL nghĩa là kế thừa cấu hình hiện tại của nhà.
-- Khi ngừng dùng tại phòng, đặt is_active = FALSE để giữ nguồn của hóa đơn lịch sử.
CREATE TABLE `room_services` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `room_id` BIGINT NOT NULL,
  `house_id` BIGINT NOT NULL,
  `house_service_id` BIGINT NOT NULL,
  `unit_price_override` DECIMAL(15,2),
  `calculation_method_override` VARCHAR(40),
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_room_services` (`room_id`, `house_service_id`),
  UNIQUE KEY `uq_room_services_id_room` (`id`, `room_id`),
  KEY `ix_room_services_room_house` (`room_id`, `house_id`),
  KEY `ix_room_services_house_service` (`house_service_id`, `house_id`),
  CONSTRAINT `ck_room_services_unit_price_override` CHECK (unit_price_override IS NULL OR unit_price_override >= 0),
  CONSTRAINT `ck_room_services_method_override` CHECK (calculation_method_override IS NULL OR calculation_method_override IN ('METERED', 'PER_PERSON', 'PER_ROOM')),
  CONSTRAINT `ck_room_services_bool_active` CHECK (is_active IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Chỉ tin cho thuê phòng; tình trạng còn phòng tách khỏi kiểm duyệt. Không có SHARED_SLOT.
CREATE TABLE `posts` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `landlord_id` BIGINT NOT NULL,
  `house_id` BIGINT NOT NULL,
  `room_id` BIGINT NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `content` TEXT,
  `status` VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
  `availability_status` VARCHAR(40) NOT NULL DEFAULT 'STALE',
  `availability_confirmed_at` DATETIME(6),
  `availability_expires_at` DATETIME(6),
  `published_at` DATETIME(6),
  `reviewed_at` DATETIME(6),
  `hidden_at` DATETIME(6),
  `reviewed_by_id` BIGINT,
  `rejection_reason` VARCHAR(1000),
  `hidden_by_id` BIGINT,
  `hidden_reason` VARCHAR(1000),
  `content_version` BIGINT NOT NULL DEFAULT 1,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `live_room_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('PENDING_REVIEW','APPROVED') THEN room_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_posts_live_room` (`live_room_id`),
  UNIQUE KEY `uq_posts_id_room` (`id`, `room_id`),
  KEY `ix_posts_room_house` (`room_id`, `house_id`),
  KEY `ix_posts_house_landlord` (`house_id`, `landlord_id`),
  KEY `ix_posts_search` (`status`, `availability_status`, `availability_expires_at`),
  KEY `ix_posts_landlord` (`landlord_id`),
  CONSTRAINT `ck_posts_status` CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'HIDDEN')),
  CONSTRAINT `ck_posts_availability_status` CHECK (availability_status IN ('OPEN', 'FULL', 'STALE')),
  CONSTRAINT `ck_posts_version` CHECK (content_version > 0),
  CONSTRAINT `ck_posts_availability` CHECK (availability_status <> 'OPEN' OR (availability_confirmed_at IS NOT NULL AND availability_expires_at IS NOT NULL AND availability_expires_at > availability_confirmed_at))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Ảnh qua file do hệ thống quản lý hoặc URL HTTPS bên ngoài; đúng một nguồn.
CREATE TABLE `post_images` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `post_id` BIGINT NOT NULL,
  `file_id` BIGINT,
  `external_url` VARCHAR(500),
  `position` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_post_images_position` (`post_id`, `position`),
  UNIQUE KEY `uq_post_images_file` (`post_id`, `file_id`),
  UNIQUE KEY `uq_post_images_url` (`post_id`, `external_url`),
  CONSTRAINT `ck_post_images_source` CHECK ((file_id IS NOT NULL AND external_url IS NULL) OR (file_id IS NULL AND external_url IS NOT NULL)),
  CONSTRAINT `ck_post_images_position` CHECK (position >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tiện ích của tin, dùng để hiển thị và lọc tìm kiếm.
CREATE TABLE `post_amenities` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `post_id` BIGINT NOT NULL,
  `amenity` VARCHAR(100) NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_post_amenities` (`post_id`, `amenity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tin được người dùng chủ động lưu; không phải lịch sử hành vi để cá nhân hóa.
CREATE TABLE `favorite_posts` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `post_id` BIGINT NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_favorite_posts` (`user_id`, `post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Khi đặt/đổi lịch: trong cùng giao dịch khóa rooms.id, kiểm tra khoảng giờ SCHEDULED giao nhau rồi mới ghi.
CREATE TABLE `room_viewing_requests` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `room_id` BIGINT NOT NULL,
  `house_id` BIGINT NOT NULL,
  `conversation_id` BIGINT NOT NULL,
  `tenant_id` BIGINT NOT NULL,
  `created_by_id` BIGINT NOT NULL,
  `starts_at` DATETIME(6) NOT NULL,
  `ends_at` DATETIME(6) NOT NULL,
  `notes` VARCHAR(2000),
  `status` VARCHAR(40) NOT NULL DEFAULT 'SCHEDULED',
  `attendance_confirmed_by_id` BIGINT,
  `attendance_confirmed_at` DATETIME(6),
  `cancelled_at` DATETIME(6),
  `cancelled_by_id` BIGINT,
  `cancellation_reason` VARCHAR(1000),
  `rental_decision` VARCHAR(40) NOT NULL DEFAULT 'WAITING',
  `rental_decided_by_id` BIGINT,
  `rental_decided_at` DATETIME(6),
  `rental_withdrawn_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_viewings_id_room` (`id`, `room_id`),
  UNIQUE KEY `uq_viewings_id_room_tenant` (`id`, `room_id`, `tenant_id`),
  KEY `ix_viewings_calendar` (`room_id`, `status`, `starts_at`, `ends_at`),
  KEY `ix_viewings_tenant` (`tenant_id`, `starts_at`),
  KEY `ix_viewings_room_house` (`room_id`, `house_id`),
  KEY `ix_viewings_house_creator` (`house_id`, `created_by_id`),
  KEY `ix_viewings_conversation_room` (`conversation_id`, `room_id`),
  KEY `ix_viewings_conversation_tenant` (`conversation_id`, `tenant_id`),
  KEY `ix_viewings_conversation_creator` (`conversation_id`, `created_by_id`),
  CONSTRAINT `ck_room_viewing_requests_status` CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
  CONSTRAINT `ck_room_viewing_requests_rental_decision` CHECK (rental_decision IN ('WAITING', 'AGREED', 'DECLINED', 'WITHDRAWN')),
  CONSTRAINT `ck_room_viewing_requests_time_range` CHECK (ends_at > starts_at),
  CONSTRAINT `ck_room_viewing_requests_completed` CHECK (status <> 'COMPLETED' OR (attendance_confirmed_by_id IS NOT NULL AND attendance_confirmed_by_id = created_by_id AND attendance_confirmed_at IS NOT NULL)),
  CONSTRAINT `ck_room_viewing_requests_decision` CHECK ((rental_decision = 'WAITING' AND rental_decided_by_id IS NULL AND rental_decided_at IS NULL AND rental_withdrawn_at IS NULL) OR (rental_decision IN ('AGREED','DECLINED') AND status = 'COMPLETED' AND rental_decided_by_id IS NOT NULL AND rental_decided_by_id = tenant_id AND rental_decided_at IS NOT NULL AND rental_withdrawn_at IS NULL) OR (rental_decision = 'WITHDRAWN' AND status = 'COMPLETED' AND rental_decided_by_id IS NOT NULL AND rental_decided_by_id = tenant_id AND rental_decided_at IS NOT NULL AND rental_withdrawn_at IS NOT NULL AND rental_withdrawn_at >= rental_decided_at)),
  CONSTRAINT `ck_room_viewing_requests_cancelled` CHECK (status <> 'CANCELLED' OR (cancelled_at IS NOT NULL AND cancelled_by_id IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Mỗi dòng là một phiên bản mẫu; nội dung mẫu đã dùng không sửa đè.
CREATE TABLE `contract_templates` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `created_by_id` BIGINT NOT NULL,
  `name` VARCHAR(200) NOT NULL,
  `version` INT NOT NULL,
  `content` LONGTEXT NOT NULL,
  `active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_contract_template_version` (`name`, `version`),
  CONSTRAINT `ck_contract_templates_bool_active` CHECK (active IN (0,1)),
  CONSTRAINT `ck_contract_templates_version` CHECK (version > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Đầu mối hợp đồng; đại diện là một room_tenants thuộc chính hợp đồng. DRAFT cho phép chưa gắn đại diện/phiên bản.
CREATE TABLE `contracts` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `contract_number` VARCHAR(100) NOT NULL,
  `room_id` BIGINT NOT NULL,
  `house_id` BIGINT NOT NULL,
  `landlord_id` BIGINT NOT NULL,
  `representative_room_tenant_id` BIGINT,
  `current_revision_id` BIGINT,
  `viewing_id` BIGINT,
  `viewing_tenant_id` BIGINT,
  `previous_contract_id` BIGINT,
  `paper_document_file_id` BIGINT,
  `source` VARCHAR(40) NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `rent_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `deposit_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `activated_at` DATETIME(6),
  `closed_at` DATETIME(6),
  `closure_reason` VARCHAR(1000),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `live_room_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('PENDING_CONFIRMATION','CONFIRMED','ACTIVE') THEN room_id ELSE NULL END) STORED,
  `live_viewing_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE') THEN viewing_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_contract_number` (`contract_number`),
  UNIQUE KEY `uq_contract_id_room` (`id`, `room_id`),
  UNIQUE KEY `uq_contract_id_landlord` (`id`, `landlord_id`),
  UNIQUE KEY `uq_contract_id_room_previous` (`id`, `room_id`, `previous_contract_id`),
  UNIQUE KEY `uq_contract_live_room` (`live_room_id`),
  UNIQUE KEY `uq_contract_live_viewing` (`live_viewing_id`),
  KEY `ix_contract_landlord` (`landlord_id`, `status`),
  KEY `ix_contract_room_house` (`room_id`, `house_id`),
  KEY `ix_contract_house_landlord` (`house_id`, `landlord_id`),
  KEY `ix_contract_viewing_tenant` (`viewing_id`, `room_id`, `viewing_tenant_id`),
  KEY `ix_contract_viewing_representative` (`id`, `representative_room_tenant_id`, `viewing_tenant_id`),
  CONSTRAINT `ck_contracts_source` CHECK (source IN ('NEW_RENTAL', 'PAPER_IMPORT', 'TRANSFER', 'REPLACEMENT')),
  CONSTRAINT `ck_contracts_status` CHECK (status IN ('DRAFT', 'PENDING_CONFIRMATION', 'CONFIRMED', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'CANCELLED')),
  CONSTRAINT `ck_contracts_rent_amount` CHECK (rent_amount >= 0),
  CONSTRAINT `ck_contracts_deposit_amount` CHECK (deposit_amount >= 0),
  CONSTRAINT `ck_contracts_dates` CHECK (end_date >= start_date),
  CONSTRAINT `ck_contracts_source_evidence` CHECK ((source = 'NEW_RENTAL' AND viewing_id IS NOT NULL AND viewing_tenant_id IS NOT NULL AND previous_contract_id IS NULL) OR (source = 'PAPER_IMPORT' AND viewing_id IS NULL AND viewing_tenant_id IS NULL AND previous_contract_id IS NULL AND paper_document_file_id IS NOT NULL) OR (source IN ('TRANSFER','REPLACEMENT') AND viewing_id IS NULL AND viewing_tenant_id IS NULL AND previous_contract_id IS NOT NULL)),
  CONSTRAINT `ck_contracts_representative` CHECK (status IN ('DRAFT','CANCELLED') OR (representative_room_tenant_id IS NOT NULL AND current_revision_id IS NOT NULL)),
  CONSTRAINT `ck_contracts_activated` CHECK (status <> 'ACTIVE' OR activated_at IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Một lượt thành viên gắn hợp đồng/phòng; tenant_id trống chỉ khi người nhập giấy chưa liên kết tài khoản. Vai trò đại diện suy từ contracts.
CREATE TABLE `room_tenants` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `contract_id` BIGINT NOT NULL,
  `room_id` BIGINT NOT NULL,
  `tenant_id` BIGINT,
  `full_name` VARCHAR(150) NOT NULL,
  `phone_number` VARCHAR(20),
  `identity_number` VARCHAR(30),
  `date_of_birth` DATE,
  `gender` VARCHAR(30),
  `permanent_address` VARCHAR(500),
  `status` VARCHAR(40) NOT NULL DEFAULT 'PLANNED',
  `intake_source` VARCHAR(40) NOT NULL,
  `join_request_id` BIGINT,
  `planned_move_in_date` DATE,
  `move_in_date` DATE,
  `move_out_date` DATE,
  `move_in_confirmed_by_id` BIGINT,
  `move_out_confirmed_by_id` BIGINT,
  `move_in_confirmed_at` DATETIME(6),
  `move_out_confirmed_at` DATETIME(6),
  `account_linked_at` DATETIME(6),
  `account_linked_by_id` BIGINT,
  `cancellation_reason` VARCHAR(1000),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `active_tenant_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status = 'ACTIVE' THEN tenant_id ELSE NULL END) STORED,
  `open_tenant_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('PLANNED','ACTIVE') THEN tenant_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_occupants_contract_id` (`contract_id`, `id`),
  UNIQUE KEY `uq_occupants_contract_id_tenant` (`contract_id`, `id`, `tenant_id`),
  UNIQUE KEY `uq_occupants_review_evidence` (`id`, `contract_id`, `room_id`, `tenant_id`),
  UNIQUE KEY `uq_occupants_id_tenant` (`id`, `tenant_id`),
  UNIQUE KEY `uq_occupants_join_completion` (`join_request_id`, `contract_id`, `tenant_id`, `id`),
  UNIQUE KEY `uq_occupants_active_account` (`active_tenant_id`),
  UNIQUE KEY `uq_occupants_open_member` (`contract_id`, `open_tenant_id`),
  UNIQUE KEY `uq_occupants_join_request` (`join_request_id`),
  KEY `ix_occupants_export` (`room_id`, `status`, `move_in_date`, `move_out_date`),
  KEY `ix_occupants_move_in_owner` (`contract_id`, `move_in_confirmed_by_id`),
  KEY `ix_occupants_move_out_owner` (`contract_id`, `move_out_confirmed_by_id`),
  CONSTRAINT `ck_room_tenants_status` CHECK (status IN ('PLANNED', 'ACTIVE', 'LEFT', 'CANCELLED')),
  CONSTRAINT `ck_room_tenants_intake_source` CHECK (intake_source IN ('INITIAL_CONTRACT', 'APPROVED_JOIN', 'PAPER_IMPORT', 'TRANSFER')),
  CONSTRAINT `ck_room_tenants_stay_dates` CHECK ((status = 'PLANNED' AND planned_move_in_date IS NOT NULL AND move_in_date IS NULL AND move_out_date IS NULL) OR (status = 'ACTIVE' AND move_in_date IS NOT NULL AND move_out_date IS NULL) OR (status = 'LEFT' AND move_in_date IS NOT NULL AND move_out_date IS NOT NULL AND move_out_date >= move_in_date) OR (status = 'CANCELLED' AND move_in_date IS NULL AND move_out_date IS NULL)),
  CONSTRAINT `ck_room_tenants_join_source` CHECK ((intake_source = 'APPROVED_JOIN' AND join_request_id IS NOT NULL AND tenant_id IS NOT NULL) OR (intake_source <> 'APPROVED_JOIN' AND join_request_id IS NULL)),
  CONSTRAINT `ck_room_tenants_confirmed_stay` CHECK (status NOT IN ('ACTIVE','LEFT') OR (move_in_confirmed_by_id IS NOT NULL AND move_in_confirmed_at IS NOT NULL)),
  CONSTRAINT `ck_room_tenants_confirmed_left` CHECK (status <> 'LEFT' OR (move_out_confirmed_by_id IS NOT NULL AND move_out_confirmed_at IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Phiên bản nội dung và xác nhận riêng; snapshot thành viên/giá không sửa sau khi gửi. PAPER_IMPORT không giả xác nhận tài khoản.
CREATE TABLE `contract_revisions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `contract_id` BIGINT NOT NULL,
  `revision_number` INT NOT NULL,
  `template_id` BIGINT,
  `created_by_id` BIGINT NOT NULL,
  `kind` VARCHAR(40) NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `effective_from` DATE NOT NULL,
  `rent_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `deposit_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `content` LONGTEXT NOT NULL,
  `members_snapshot` JSON NOT NULL,
  `service_terms_snapshot` JSON,
  `document_file_id` BIGINT,
  `representative_room_tenant_id` BIGINT NOT NULL,
  `landlord_confirmed_by_id` BIGINT,
  `tenant_confirmed_by_id` BIGINT,
  `landlord_confirmed_at` DATETIME(6),
  `tenant_confirmed_at` DATETIME(6),
  `sent_at` DATETIME(6),
  `applied_at` DATETIME(6),
  `tenant_feedback` VARCHAR(2000),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_revisions_number` (`contract_id`, `revision_number`),
  UNIQUE KEY `uq_revisions_contract_id` (`contract_id`, `id`),
  KEY `ix_revisions_landlord_confirmation` (`contract_id`, `landlord_confirmed_by_id`),
  KEY `ix_revisions_tenant_confirmation` (`representative_room_tenant_id`, `tenant_confirmed_by_id`),
  CONSTRAINT `ck_contract_revisions_kind` CHECK (kind IN ('INITIAL', 'RENEWAL', 'TERMINATION', 'TRANSFER', 'REPLACEMENT', 'PAPER_IMPORT')),
  CONSTRAINT `ck_contract_revisions_status` CHECK (status IN ('DRAFT', 'PENDING_CONFIRMATION', 'CONFIRMED', 'IMPORTED', 'SUPERSEDED', 'CANCELLED')),
  CONSTRAINT `ck_contract_revisions_rent_amount` CHECK (rent_amount >= 0),
  CONSTRAINT `ck_contract_revisions_deposit_amount` CHECK (deposit_amount >= 0),
  CONSTRAINT `ck_contract_revisions_number` CHECK (revision_number > 0),
  CONSTRAINT `ck_contract_revisions_dates` CHECK (end_date >= start_date),
  CONSTRAINT `ck_contract_revisions_confirmed` CHECK (status <> 'CONFIRMED' OR (landlord_confirmed_by_id IS NOT NULL AND landlord_confirmed_at IS NOT NULL AND tenant_confirmed_by_id IS NOT NULL AND tenant_confirmed_at IS NOT NULL)),
  CONSTRAINT `ck_contract_revisions_imported` CHECK (status <> 'IMPORTED' OR (kind = 'PAPER_IMPORT' AND document_file_id IS NOT NULL AND tenant_confirmed_by_id IS NULL AND tenant_confirmed_at IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Yêu cầu điều chỉnh, xác nhận và áp dụng; đổi phòng trả result_contract_id thay vì đổi room_id của hợp đồng cũ.
CREATE TABLE `contract_change_requests` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `contract_id` BIGINT NOT NULL,
  `requested_by_id` BIGINT NOT NULL,
  `representative_room_tenant_id` BIGINT NOT NULL,
  `base_revision_id` BIGINT NOT NULL,
  `proposed_revision_id` BIGINT,
  `target_room_id` BIGINT,
  `result_contract_id` BIGINT,
  `type` VARCHAR(40) NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'PENDING',
  `requested_effective_date` DATE NOT NULL,
  `proposal_snapshot` JSON NOT NULL,
  `message` VARCHAR(2000),
  `reviewed_by_id` BIGINT,
  `rejection_reason` VARCHAR(1000),
  `tenant_confirmed_by_id` BIGINT,
  `applied_by_id` BIGINT,
  `reviewed_at` DATETIME(6),
  `tenant_confirmed_at` DATETIME(6),
  `applied_at` DATETIME(6),
  `expires_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `open_contract_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('PENDING','APPROVED_WAITING_CONFIRMATION','READY_TO_APPLY') THEN contract_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_change_open_contract` (`open_contract_id`),
  KEY `ix_changes_contract` (`contract_id`, `created_at`),
  KEY `ix_changes_requester_rep` (`representative_room_tenant_id`, `requested_by_id`),
  KEY `ix_changes_tenant_confirmation` (`representative_room_tenant_id`, `tenant_confirmed_by_id`),
  KEY `ix_changes_transfer_result` (`result_contract_id`, `target_room_id`, `contract_id`),
  KEY `ix_changes_owner_review` (`contract_id`, `reviewed_by_id`),
  KEY `ix_changes_owner_apply` (`contract_id`, `applied_by_id`),
  CONSTRAINT `ck_contract_change_requests_type` CHECK (type IN ('RENEWAL', 'TERMINATION', 'TRANSFER')),
  CONSTRAINT `ck_contract_change_requests_status` CHECK (status IN ('PENDING', 'APPROVED_WAITING_CONFIRMATION', 'READY_TO_APPLY', 'COMPLETED', 'REJECTED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT `ck_contract_change_requests_target` CHECK ((type = 'TRANSFER' AND target_room_id IS NOT NULL) OR (type <> 'TRANSFER' AND target_room_id IS NULL)),
  CONSTRAINT `ck_contract_change_requests_result_type` CHECK (type = 'TRANSFER' OR result_contract_id IS NULL),
  CONSTRAINT `ck_contract_change_requests_rejected` CHECK (status <> 'REJECTED' OR (rejection_reason IS NOT NULL AND reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL)),
  CONSTRAINT `ck_contract_change_requests_ready` CHECK (status NOT IN ('READY_TO_APPLY','COMPLETED') OR (reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL AND tenant_confirmed_by_id IS NOT NULL AND tenant_confirmed_at IS NOT NULL)),
  CONSTRAINT `ck_contract_change_requests_completed` CHECK (status <> 'COMPLETED' OR (applied_by_id IS NOT NULL AND applied_at IS NOT NULL AND (type <> 'TRANSFER' OR result_contract_id IS NOT NULL)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Đủ đồng thuận rồi chủ trọ xét; APPROVED chỉ giữ chỗ có hạn, COMPLETED mới liên kết lượt vào ở.
CREATE TABLE `occupant_join_requests` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `contract_id` BIGINT NOT NULL,
  `source_roommate_request_id` BIGINT,
  `applicant_id` BIGINT NOT NULL,
  `requested_by_id` BIGINT NOT NULL,
  `representative_room_tenant_id` BIGINT NOT NULL,
  `planned_move_in_date` DATE NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'PENDING_CONSENT',
  `representative_consented_by_id` BIGINT,
  `representative_consented_at` DATETIME(6),
  `applicant_consented_by_id` BIGINT,
  `applicant_consented_at` DATETIME(6),
  `reviewed_at` DATETIME(6),
  `hold_expires_at` DATETIME(6),
  `completed_at` DATETIME(6),
  `cancelled_at` DATETIME(6),
  `reviewed_by_id` BIGINT,
  `rejection_reason` VARCHAR(1000),
  `completed_room_tenant_id` BIGINT,
  `message` VARCHAR(2000),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `open_applicant_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('PENDING_CONSENT','PENDING_LANDLORD','APPROVED') THEN applicant_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_join_applicant_open` (`contract_id`, `open_applicant_id`),
  UNIQUE KEY `uq_join_evidence` (`id`, `contract_id`, `applicant_id`),
  UNIQUE KEY `uq_join_completed_occupant` (`completed_room_tenant_id`),
  KEY `ix_join_hold` (`status`, `hold_expires_at`),
  KEY `ix_join_source_roommate` (`source_roommate_request_id`, `contract_id`),
  KEY `ix_join_representative_consent` (`representative_room_tenant_id`, `representative_consented_by_id`),
  KEY `ix_join_owner_review` (`contract_id`, `reviewed_by_id`),
  CONSTRAINT `ck_occupant_join_requests_status` CHECK (status IN ('PENDING_CONSENT', 'PENDING_LANDLORD', 'APPROVED', 'COMPLETED', 'REJECTED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT `ck_occupant_join_requests_different_people` CHECK (applicant_id <> requested_by_id),
  CONSTRAINT `ck_occupant_join_requests_representative_consent` CHECK ((representative_consented_by_id IS NULL AND representative_consented_at IS NULL) OR (representative_consented_by_id IS NOT NULL AND representative_consented_at IS NOT NULL)),
  CONSTRAINT `ck_occupant_join_requests_applicant_consent` CHECK ((applicant_consented_by_id IS NULL AND applicant_consented_at IS NULL) OR (applicant_consented_by_id IS NOT NULL AND applicant_consented_by_id = applicant_id AND applicant_consented_at IS NOT NULL)),
  CONSTRAINT `ck_occupant_join_requests_consents` CHECK (status NOT IN ('PENDING_LANDLORD','APPROVED','COMPLETED') OR (representative_consented_by_id IS NOT NULL AND applicant_consented_by_id IS NOT NULL)),
  CONSTRAINT `ck_occupant_join_requests_approved` CHECK (status NOT IN ('APPROVED','COMPLETED') OR (reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL AND hold_expires_at IS NOT NULL AND hold_expires_at > reviewed_at)),
  CONSTRAINT `ck_occupant_join_requests_rejected` CHECK (status <> 'REJECTED' OR (reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL AND rejection_reason IS NOT NULL)),
  CONSTRAINT `ck_occupant_join_requests_completed` CHECK ((status = 'COMPLETED' AND completed_room_tenant_id IS NOT NULL AND completed_at IS NOT NULL) OR (status <> 'COMPLETED' AND completed_room_tenant_id IS NULL AND completed_at IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Ba tình trạng nhà ở; trọ ngoài chỉ là ngữ cảnh tự khai tối thiểu, không có hồ sơ quản lý trọ ngoài.
CREATE TABLE `roommate_profiles` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` BIGINT NOT NULL,
  `housing_status` VARCHAR(40) NOT NULL,
  `current_room_tenant_id` BIGINT,
  `external_context` VARCHAR(1000),
  `available_from` DATE NOT NULL,
  `budget_min` DECIMAL(15,2),
  `budget_max` DECIMAL(15,2),
  `preferred_location` VARCHAR(500),
  `preferred_gender` VARCHAR(30),
  `requirements_snapshot` JSON,
  `profile_version` BIGINT NOT NULL DEFAULT 1,
  `active` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_roommate_profile_tenant` (`tenant_id`),
  KEY `ix_roommate_profiles_active` (`active`, `housing_status`),
  CONSTRAINT `ck_roommate_profiles_housing_status` CHECK (housing_status IN ('NO_ACCOMMODATION', 'IN_SYSTEM', 'EXTERNAL')),
  CONSTRAINT `ck_roommate_profiles_budget_min` CHECK (budget_min >= 0),
  CONSTRAINT `ck_roommate_profiles_budget_max` CHECK (budget_max >= 0),
  CONSTRAINT `ck_roommate_profiles_bool_active` CHECK (active IN (0,1)),
  CONSTRAINT `ck_roommate_profiles_housing` CHECK ((housing_status = 'IN_SYSTEM' AND current_room_tenant_id IS NOT NULL AND external_context IS NULL) OR (housing_status <> 'IN_SYSTEM' AND current_room_tenant_id IS NULL)),
  CONSTRAINT `ck_roommate_profiles_budget` CHECK (budget_min IS NULL OR budget_max IS NULL OR budget_max >= budget_min),
  CONSTRAINT `ck_roommate_profiles_version` CHECK (profile_version > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Danh mục tiêu chí và thói quen do người thuê khai báo để tìm bạn ở ghép.
CREATE TABLE `lifestyle_criteria` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(80) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(100) NOT NULL,
  `value_type` VARCHAR(40) NOT NULL,
  `allowed_values` JSON,
  `active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_lifestyle_code` (`code`),
  CONSTRAINT `ck_lifestyle_criteria_value_type` CHECK (value_type IN ('BOOLEAN', 'NUMBER', 'CATEGORY', 'TIME', 'RANGE')),
  CONSTRAINT `ck_lifestyle_criteria_bool_active` CHECK (active IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Giá trị của bản thân, mong muốn và mức độ quan trọng của từng tiêu chí.
CREATE TABLE `profile_lifestyles` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `profile_id` BIGINT NOT NULL,
  `criterion_id` BIGINT NOT NULL,
  `self_value` JSON,
  `preferred_value` JSON,
  `is_mandatory` BOOLEAN NOT NULL DEFAULT FALSE,
  `importance` INT NOT NULL DEFAULT 1,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_profile_lifestyle` (`profile_id`, `criterion_id`),
  CONSTRAINT `ck_profile_lifestyles_bool_is_mandatory` CHECK (is_mandatory IN (0,1)),
  CONSTRAINT `ck_profile_lifestyles_values` CHECK (self_value IS NOT NULL OR preferred_value IS NOT NULL),
  CONSTRAINT `ck_profile_lifestyles_mandatory` CHECK (is_mandatory = FALSE OR preferred_value IS NOT NULL),
  CONSTRAINT `ck_profile_lifestyles_importance` CHECK (importance BETWEEN 0 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Lời mời kết nối giữa hai người; không phải yêu cầu chủ trọ tiếp nhận.
CREATE TABLE `roommate_requests` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `sender_id` BIGINT NOT NULL,
  `receiver_id` BIGINT NOT NULL,
  `scenario` VARCHAR(40) NOT NULL,
  `target_contract_id` BIGINT,
  `status` VARCHAR(40) NOT NULL DEFAULT 'PENDING',
  `message` VARCHAR(2000),
  `responded_at` DATETIME(6),
  `ended_at` DATETIME(6),
  `end_reason` VARCHAR(1000),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `pair_low_id` BIGINT GENERATED ALWAYS AS (LEAST(sender_id, receiver_id)) STORED,
  `pair_high_id` BIGINT GENERATED ALWAYS AS (GREATEST(sender_id, receiver_id)) STORED,
  `open_pair_key` INT GENERATED ALWAYS AS (CASE WHEN status = 'PENDING' OR (status = 'ACCEPTED' AND ended_at IS NULL) THEN 1 ELSE NULL END) STORED,
  UNIQUE KEY `uq_roommate_open_pair` (`pair_low_id`, `pair_high_id`, `open_pair_key`),
  UNIQUE KEY `uq_roommate_request_contract` (`id`, `target_contract_id`),
  KEY `ix_roommate_requests_receiver` (`receiver_id`, `status`, `created_at`),
  CONSTRAINT `ck_roommate_requests_scenario` CHECK (scenario IN ('SEARCH_TOGETHER', 'JOIN_SYSTEM_ROOM', 'JOIN_EXTERNAL_HOME')),
  CONSTRAINT `ck_roommate_requests_status` CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED')),
  CONSTRAINT `ck_roommate_requests_different_people` CHECK (sender_id <> receiver_id),
  CONSTRAINT `ck_roommate_requests_scenario_context` CHECK ((scenario = 'JOIN_SYSTEM_ROOM' AND target_contract_id IS NOT NULL) OR (scenario <> 'JOIN_SYSTEM_ROOM' AND target_contract_id IS NULL)),
  CONSTRAINT `ck_roommate_requests_ended` CHECK (ended_at IS NULL OR status = 'ACCEPTED')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Người trả được chốt tại kỳ; từng khoản tiền nằm trong invoice_items.
-- DRAFT cho phép thêm dòng trước khi phát hành. Một bản chưa hủy cho mỗi hợp đồng/tháng.
CREATE TABLE `invoices` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `contract_id` BIGINT NOT NULL,
  `room_id` BIGINT NOT NULL,
  `contract_revision_id` BIGINT NOT NULL,
  `payer_room_tenant_id` BIGINT NOT NULL,
  `payer_snapshot` JSON NOT NULL,
  `billing_period` DATE NOT NULL,
  `due_date` DATE NOT NULL,
  `occupant_count_at_billing` INT NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
  `created_by_id` BIGINT NOT NULL,
  `paid_by_id` BIGINT,
  `cancelled_by_id` BIGINT,
  `cancellation_reason` VARCHAR(1000),
  `replacement_of_id` BIGINT,
  `paid_at` DATETIME(6),
  `cancelled_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `open_period_key` INT GENERATED ALWAYS AS (CASE WHEN status <> 'CANCELLED' THEN 1 ELSE NULL END) STORED,
  UNIQUE KEY `uq_invoice_open_period` (`contract_id`, `billing_period`, `open_period_key`),
  UNIQUE KEY `uq_invoice_replacement_context` (`id`, `contract_id`, `billing_period`),
  UNIQUE KEY `uq_invoice_id_room` (`id`, `room_id`),
  KEY `ix_invoice_status` (`status`, `due_date`),
  CONSTRAINT `ck_invoices_status` CHECK (status IN ('DRAFT', 'UNPAID', 'PAID', 'OVERDUE', 'CANCELLED')),
  CONSTRAINT `ck_invoices_period` CHECK (DAY(billing_period) = 1),
  CONSTRAINT `ck_invoices_occupant_count` CHECK (occupant_count_at_billing >= 0),
  CONSTRAINT `ck_invoices_paid` CHECK ((status = 'PAID' AND paid_by_id IS NOT NULL AND paid_at IS NOT NULL) OR (status <> 'PAID' AND paid_by_id IS NULL AND paid_at IS NULL)),
  CONSTRAINT `ck_invoices_cancelled` CHECK (status <> 'CANCELLED' OR (cancelled_by_id IS NOT NULL AND cancelled_at IS NOT NULL AND cancellation_reason IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Snapshot bất biến sau phát hành: tiền thuê, điện/nước/dịch vụ, khoản khác và giảm trừ.
-- Chỉ dòng SERVICE mới tham chiếu cấu hình phòng; các giá trị snapshot giữ nguyên khi giá dịch vụ đổi.
CREATE TABLE `invoice_items` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` BIGINT NOT NULL,
  `room_id` BIGINT NOT NULL,
  `room_service_id` BIGINT,
  `position` INT NOT NULL,
  `item_type` VARCHAR(40) NOT NULL,
  `name_snapshot` VARCHAR(200) NOT NULL,
  `unit_snapshot` VARCHAR(30) NOT NULL,
  `calculation_method_snapshot` VARCHAR(40),
  `quantity` DECIMAL(12,3) NOT NULL,
  `unit_price_snapshot` DECIMAL(15,2) NOT NULL,
  `previous_reading` DECIMAL(12,3),
  `current_reading` DECIMAL(12,3),
  `amount` DECIMAL(15,2) NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_invoice_items_position` (`invoice_id`, `position`),
  UNIQUE KEY `uq_invoice_items_service` (`invoice_id`, `room_service_id`),
  KEY `ix_invoice_items_invoice_room` (`invoice_id`, `room_id`),
  KEY `ix_invoice_items_room_service` (`room_service_id`, `room_id`),
  CONSTRAINT `ck_invoice_items_position` CHECK (position >= 0),
  CONSTRAINT `ck_invoice_items_type` CHECK (item_type IN ('RENT', 'SERVICE', 'OTHER', 'DISCOUNT')),
  CONSTRAINT `ck_invoice_items_source` CHECK ((item_type = 'SERVICE' AND room_service_id IS NOT NULL AND calculation_method_snapshot IS NOT NULL AND calculation_method_snapshot IN ('METERED', 'PER_PERSON', 'PER_ROOM')) OR (item_type <> 'SERVICE' AND room_service_id IS NULL AND calculation_method_snapshot IS NULL)),
  CONSTRAINT `ck_invoice_items_price` CHECK (quantity >= 0 AND unit_price_snapshot >= 0 AND amount = ROUND(quantity * unit_price_snapshot, 2)),
  CONSTRAINT `ck_invoice_items_meter` CHECK ((item_type = 'SERVICE' AND calculation_method_snapshot = 'METERED' AND previous_reading IS NOT NULL AND current_reading IS NOT NULL AND previous_reading >= 0 AND current_reading >= previous_reading AND quantity = current_reading - previous_reading) OR ((item_type <> 'SERVICE' OR calculation_method_snapshot <> 'METERED') AND previous_reading IS NULL AND current_reading IS NULL)),
  CONSTRAINT `ck_invoice_items_quantity` CHECK ((item_type <> 'SERVICE' OR calculation_method_snapshot <> 'PER_ROOM' OR quantity = 1) AND (item_type <> 'SERVICE' OR calculation_method_snapshot <> 'PER_PERSON' OR quantity = FLOOR(quantity)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Chỉ người có lượt thực tế ở được đánh giá. Chủ trọ không duyệt/xác nhận đánh giá sau xem.
CREATE TABLE `reviews` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `reviewer_id` BIGINT NOT NULL,
  `room_id` BIGINT NOT NULL,
  `contract_id` BIGINT NOT NULL,
  `room_tenant_id` BIGINT NOT NULL,
  `rating` TINYINT NOT NULL,
  `content` TEXT,
  `status` VARCHAR(40) NOT NULL DEFAULT 'PUBLISHED',
  `hidden_by_id` BIGINT,
  `hidden_reason` VARCHAR(1000),
  `hidden_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_review_tenancy` (`reviewer_id`, `room_id`, `contract_id`),
  KEY `ix_reviews_room` (`room_id`, `status`),
  CONSTRAINT `ck_reviews_status` CHECK (status IN ('PUBLISHED', 'HIDDEN', 'DELETED')),
  CONSTRAINT `ck_reviews_rating` CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Hội thoại hỏi thuê hoặc gắn kết nối ở ghép; đọc/gửi theo thành viên.
CREATE TABLE `conversations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `type` VARCHAR(40) NOT NULL,
  `room_id` BIGINT,
  `post_id` BIGINT,
  `roommate_request_id` BIGINT,
  `last_message_id` BIGINT,
  `last_message_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_conversation_roommate` (`roommate_request_id`),
  UNIQUE KEY `uq_conversation_id_room` (`id`, `room_id`),
  KEY `ix_conversation_post_room` (`post_id`, `room_id`),
  CONSTRAINT `ck_conversations_type` CHECK (type IN ('ROOM_INQUIRY', 'ROOMMATE')),
  CONSTRAINT `ck_conversations_context` CHECK ((type = 'ROOM_INQUIRY' AND room_id IS NOT NULL AND post_id IS NOT NULL AND roommate_request_id IS NULL) OR (type = 'ROOMMATE' AND roommate_request_id IS NOT NULL AND room_id IS NULL AND post_id IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Trạng thái đọc/ẩn/tắt thông báo theo từng người; không xóa tin của người còn lại.
CREATE TABLE `conversation_participants` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `conversation_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `joined_at` DATETIME(6) NOT NULL,
  `last_read_at` DATETIME(6),
  `left_at` DATETIME(6),
  `muted` BOOLEAN NOT NULL DEFAULT FALSE,
  `archived` BOOLEAN NOT NULL DEFAULT FALSE,
  `deleted` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_conversation_member` (`conversation_id`, `user_id`),
  CONSTRAINT `ck_conversation_participants_bool_muted` CHECK (muted IN (0,1)),
  CONSTRAINT `ck_conversation_participants_bool_archived` CHECK (archived IN (0,1)),
  CONSTRAINT `ck_conversation_participants_bool_deleted` CHECK (deleted IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tin đã lưu; client_message_key chống gửi lặp. Ảnh đính kèm qua files.chat_message_id.
CREATE TABLE `chat_messages` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `conversation_id` BIGINT NOT NULL,
  `sender_id` BIGINT NOT NULL,
  `client_message_key` CHAR(36) NOT NULL,
  `message_type` VARCHAR(40) NOT NULL DEFAULT 'TEXT',
  `content` TEXT,
  `sent_at` DATETIME(6) NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_message_client_key` (`sender_id`, `client_message_key`),
  UNIQUE KEY `uq_messages_conversation_id` (`conversation_id`, `id`),
  KEY `ix_messages_time` (`conversation_id`, `sent_at`, `id`),
  CONSTRAINT `ck_chat_messages_message_type` CHECK (message_type IN ('TEXT', 'IMAGE', 'SYSTEM')),
  CONSTRAINT `ck_chat_messages_text` CHECK (message_type <> 'TEXT' OR content IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Feed thông báo trong ứng dụng; đọc không thay xác nhận nghiệp vụ.
CREATE TABLE `notifications` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `type` VARCHAR(60) NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `content` TEXT NOT NULL,
  `resource_type` VARCHAR(60),
  `resource_id` BIGINT,
  `event_key` VARCHAR(150) NOT NULL,
  `is_read` BOOLEAN NOT NULL DEFAULT FALSE,
  `read_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY `uq_notification_event` (`user_id`, `event_key`),
  KEY `ix_notifications_feed` (`user_id`, `is_read`, `created_at`),
  CONSTRAINT `ck_notifications_bool_is_read` CHECK (is_read IN (0,1)),
  CONSTRAINT `ck_notifications_resource` CHECK ((resource_type IS NULL AND resource_id IS NULL) OR (resource_type IS NOT NULL AND resource_id IS NOT NULL)),
  CONSTRAINT `ck_notifications_read` CHECK ((is_read = FALSE AND read_at IS NULL) OR (is_read = TRUE AND read_at IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Một đối tượng chính mỗi báo cáo; bằng chứng qua files.report_id. Tranh chấp không tự đóng hợp đồng.
CREATE TABLE `reports` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `reporter_id` BIGINT NOT NULL,
  `type` VARCHAR(40) NOT NULL,
  `reported_user_id` BIGINT,
  `reported_post_id` BIGINT,
  `contract_id` BIGINT,
  `roommate_request_id` BIGINT,
  `reason` TEXT NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'PENDING',
  `resolution` TEXT,
  `handled_by_id` BIGINT,
  `handled_at` DATETIME(6),
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY `ix_reports_queue` (`status`, `created_at`),
  KEY `ix_reports_reporter` (`reporter_id`, `created_at`),
  CONSTRAINT `ck_reports_type` CHECK (type IN ('VIOLATION', 'DISPUTE')),
  CONSTRAINT `ck_reports_status` CHECK (status IN ('PENDING', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')),
  CONSTRAINT `ck_reports_subject` CHECK ((reported_user_id IS NOT NULL) + (reported_post_id IS NOT NULL) + (contract_id IS NOT NULL) + (roommate_request_id IS NOT NULL) = 1),
  CONSTRAINT `ck_reports_closed` CHECK (status NOT IN ('RESOLVED','DISMISSED') OR (resolution IS NOT NULL AND handled_by_id IS NOT NULL AND handled_at IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Nhật ký nối tiếp các lần khóa/mở tài khoản, ẩn/mở tin và xử lý hồ sơ/báo cáo; không sửa đè lần trước.
CREATE TABLE `moderation_actions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `actor_user_id` BIGINT NOT NULL,
  `target_user_id` BIGINT,
  `target_post_id` BIGINT,
  `target_report_id` BIGINT,
  `target_landlord_verification_id` BIGINT,
  `target_tenant_verification_id` BIGINT,
  `related_report_id` BIGINT,
  `action` VARCHAR(80) NOT NULL,
  `reason` TEXT NOT NULL,
  `before_snapshot` JSON,
  `after_snapshot` JSON,
  `occurred_at` DATETIME(6) NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY `ix_moderation_user` (`target_user_id`, `occurred_at`),
  KEY `ix_moderation_post` (`target_post_id`, `occurred_at`),
  KEY `ix_moderation_report` (`target_report_id`, `occurred_at`),
  CONSTRAINT `ck_moderation_actions_target` CHECK ((target_user_id IS NOT NULL) + (target_post_id IS NOT NULL) + (target_report_id IS NOT NULL) + (target_landlord_verification_id IS NOT NULL) + (target_tenant_verification_id IS NOT NULL) = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Add FK constraints after every table exists, including circular draft relationships.
-- No cascading delete/update; default RESTRICT/NO ACTION preserves history.
ALTER TABLE `users` ADD CONSTRAINT `fk_users_locked_by` FOREIGN KEY (`locked_by_id`) REFERENCES `users` (`id`);
ALTER TABLE `tenants` ADD CONSTRAINT `fk_tenants_user` FOREIGN KEY (`id`) REFERENCES `users` (`id`);
ALTER TABLE `landlords` ADD CONSTRAINT `fk_landlords_user` FOREIGN KEY (`id`) REFERENCES `users` (`id`);
ALTER TABLE `admins` ADD CONSTRAINT `fk_admins_user` FOREIGN KEY (`id`) REFERENCES `users` (`id`);
ALTER TABLE `personal_profiles` ADD CONSTRAINT `fk_profiles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `personal_profiles` ADD CONSTRAINT `fk_profiles_avatar` FOREIGN KEY (`avatar_file_id`) REFERENCES `files` (`id`);
ALTER TABLE `files` ADD CONSTRAINT `fk_files_owner_user_id` FOREIGN KEY (`owner_user_id`) REFERENCES `users` (`id`);
ALTER TABLE `files` ADD CONSTRAINT `fk_files_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`);
ALTER TABLE `files` ADD CONSTRAINT `fk_files_chat_message_id` FOREIGN KEY (`chat_message_id`) REFERENCES `chat_messages` (`id`);
ALTER TABLE `files` ADD CONSTRAINT `fk_files_landlord_verification_id` FOREIGN KEY (`landlord_verification_id`) REFERENCES `landlord_verifications` (`id`);
ALTER TABLE `landlord_verifications` ADD CONSTRAINT `fk_landlord_applicant` FOREIGN KEY (`applicant_user_id`) REFERENCES `users` (`id`);
ALTER TABLE `landlord_verifications` ADD CONSTRAINT `fk_landlord_identity` FOREIGN KEY (`identity_file_id`) REFERENCES `files` (`id`);
ALTER TABLE `landlord_verifications` ADD CONSTRAINT `fk_landlord_reviewer` FOREIGN KEY (`reviewed_by_id`) REFERENCES `admins` (`id`);
ALTER TABLE `tenant_identity_verifications` ADD CONSTRAINT `fk_identity_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `tenant_identity_verifications` ADD CONSTRAINT `fk_identity_file` FOREIGN KEY (`identity_file_id`) REFERENCES `files` (`id`);
ALTER TABLE `tenant_identity_verifications` ADD CONSTRAINT `fk_identity_reviewer` FOREIGN KEY (`reviewed_by_id`) REFERENCES `admins` (`id`);
ALTER TABLE `auth_sessions` ADD CONSTRAINT `fk_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `verification_tokens` ADD CONSTRAINT `fk_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `verification_tokens` ADD CONSTRAINT `fk_tokens_occupant` FOREIGN KEY (`target_room_tenant_id`) REFERENCES `room_tenants` (`id`);
ALTER TABLE `rental_houses` ADD CONSTRAINT `fk_houses_landlord` FOREIGN KEY (`landlord_id`) REFERENCES `landlords` (`id`);
ALTER TABLE `rooms` ADD CONSTRAINT `fk_rooms_house` FOREIGN KEY (`house_id`) REFERENCES `rental_houses` (`id`);
ALTER TABLE `house_services` ADD CONSTRAINT `fk_house_services_house` FOREIGN KEY (`house_id`) REFERENCES `rental_houses` (`id`);
ALTER TABLE `house_services` ADD CONSTRAINT `fk_house_services_catalog` FOREIGN KEY (`catalog_service_id`) REFERENCES `rental_services` (`id`);
ALTER TABLE `room_services` ADD CONSTRAINT `fk_room_services_room_house` FOREIGN KEY (`room_id`, `house_id`) REFERENCES `rooms` (`id`, `house_id`);
ALTER TABLE `room_services` ADD CONSTRAINT `fk_room_services_house_service` FOREIGN KEY (`house_service_id`, `house_id`) REFERENCES `house_services` (`id`, `house_id`);
ALTER TABLE `posts` ADD CONSTRAINT `fk_posts_house_owner` FOREIGN KEY (`house_id`, `landlord_id`) REFERENCES `rental_houses` (`id`, `landlord_id`);
ALTER TABLE `posts` ADD CONSTRAINT `fk_posts_room_house` FOREIGN KEY (`room_id`, `house_id`) REFERENCES `rooms` (`id`, `house_id`);
ALTER TABLE `posts` ADD CONSTRAINT `fk_posts_reviewer` FOREIGN KEY (`reviewed_by_id`) REFERENCES `admins` (`id`);
ALTER TABLE `posts` ADD CONSTRAINT `fk_posts_hidden_by` FOREIGN KEY (`hidden_by_id`) REFERENCES `users` (`id`);
ALTER TABLE `post_images` ADD CONSTRAINT `fk_post_images_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`);
ALTER TABLE `post_images` ADD CONSTRAINT `fk_post_images_file` FOREIGN KEY (`file_id`) REFERENCES `files` (`id`);
ALTER TABLE `post_amenities` ADD CONSTRAINT `fk_post_amenities_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`);
ALTER TABLE `favorite_posts` ADD CONSTRAINT `fk_favorites_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `favorite_posts` ADD CONSTRAINT `fk_favorites_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_room_house` FOREIGN KEY (`room_id`, `house_id`) REFERENCES `rooms` (`id`, `house_id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_house_owner` FOREIGN KEY (`house_id`, `created_by_id`) REFERENCES `rental_houses` (`id`, `landlord_id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_conversation_room` FOREIGN KEY (`conversation_id`, `room_id`) REFERENCES `conversations` (`id`, `room_id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_conversation_tenant` FOREIGN KEY (`conversation_id`, `tenant_id`) REFERENCES `conversation_participants` (`conversation_id`, `user_id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_conversation_creator` FOREIGN KEY (`conversation_id`, `created_by_id`) REFERENCES `conversation_participants` (`conversation_id`, `user_id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_attendance` FOREIGN KEY (`attendance_confirmed_by_id`) REFERENCES `landlords` (`id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_rental_decider` FOREIGN KEY (`rental_decided_by_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `room_viewing_requests` ADD CONSTRAINT `fk_viewings_cancelled_by` FOREIGN KEY (`cancelled_by_id`) REFERENCES `users` (`id`);
ALTER TABLE `contract_templates` ADD CONSTRAINT `fk_templates_creator` FOREIGN KEY (`created_by_id`) REFERENCES `admins` (`id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_room_house` FOREIGN KEY (`room_id`, `house_id`) REFERENCES `rooms` (`id`, `house_id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_house_owner` FOREIGN KEY (`house_id`, `landlord_id`) REFERENCES `rental_houses` (`id`, `landlord_id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_viewing_tenant` FOREIGN KEY (`viewing_id`, `room_id`, `viewing_tenant_id`) REFERENCES `room_viewing_requests` (`id`, `room_id`, `tenant_id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_previous` FOREIGN KEY (`previous_contract_id`) REFERENCES `contracts` (`id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_paper` FOREIGN KEY (`paper_document_file_id`) REFERENCES `files` (`id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_representative` FOREIGN KEY (`id`, `representative_room_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_viewing_representative` FOREIGN KEY (`id`, `representative_room_tenant_id`, `viewing_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`, `tenant_id`);
ALTER TABLE `contracts` ADD CONSTRAINT `fk_contract_current_revision` FOREIGN KEY (`id`, `current_revision_id`) REFERENCES `contract_revisions` (`contract_id`, `id`);
ALTER TABLE `room_tenants` ADD CONSTRAINT `fk_occupants_contract_room` FOREIGN KEY (`contract_id`, `room_id`) REFERENCES `contracts` (`id`, `room_id`);
ALTER TABLE `room_tenants` ADD CONSTRAINT `fk_occupants_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `room_tenants` ADD CONSTRAINT `fk_occupants_approved_join` FOREIGN KEY (`join_request_id`, `contract_id`, `tenant_id`) REFERENCES `occupant_join_requests` (`id`, `contract_id`, `applicant_id`);
ALTER TABLE `room_tenants` ADD CONSTRAINT `fk_occupants_move_in_owner` FOREIGN KEY (`contract_id`, `move_in_confirmed_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `room_tenants` ADD CONSTRAINT `fk_occupants_move_out_owner` FOREIGN KEY (`contract_id`, `move_out_confirmed_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `room_tenants` ADD CONSTRAINT `fk_occupants_linked_by` FOREIGN KEY (`account_linked_by_id`) REFERENCES `users` (`id`);
ALTER TABLE `contract_revisions` ADD CONSTRAINT `fk_revisions_contract` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`);
ALTER TABLE `contract_revisions` ADD CONSTRAINT `fk_revisions_template` FOREIGN KEY (`template_id`) REFERENCES `contract_templates` (`id`);
ALTER TABLE `contract_revisions` ADD CONSTRAINT `fk_revisions_creator` FOREIGN KEY (`created_by_id`) REFERENCES `users` (`id`);
ALTER TABLE `contract_revisions` ADD CONSTRAINT `fk_revisions_representative` FOREIGN KEY (`contract_id`, `representative_room_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`);
ALTER TABLE `contract_revisions` ADD CONSTRAINT `fk_revisions_landlord_confirmation` FOREIGN KEY (`contract_id`, `landlord_confirmed_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `contract_revisions` ADD CONSTRAINT `fk_revisions_tenant_confirmation` FOREIGN KEY (`representative_room_tenant_id`, `tenant_confirmed_by_id`) REFERENCES `room_tenants` (`id`, `tenant_id`);
ALTER TABLE `contract_revisions` ADD CONSTRAINT `fk_revisions_document` FOREIGN KEY (`document_file_id`) REFERENCES `files` (`id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_contract` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_requester` FOREIGN KEY (`representative_room_tenant_id`, `requested_by_id`) REFERENCES `room_tenants` (`id`, `tenant_id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_representative` FOREIGN KEY (`contract_id`, `representative_room_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_base_revision_id` FOREIGN KEY (`contract_id`, `base_revision_id`) REFERENCES `contract_revisions` (`contract_id`, `id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_proposed_revision_id` FOREIGN KEY (`contract_id`, `proposed_revision_id`) REFERENCES `contract_revisions` (`contract_id`, `id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_target` FOREIGN KEY (`target_room_id`) REFERENCES `rooms` (`id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_result` FOREIGN KEY (`result_contract_id`, `target_room_id`, `contract_id`) REFERENCES `contracts` (`id`, `room_id`, `previous_contract_id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_reviewer` FOREIGN KEY (`contract_id`, `reviewed_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_tenant_confirmation` FOREIGN KEY (`representative_room_tenant_id`, `tenant_confirmed_by_id`) REFERENCES `room_tenants` (`id`, `tenant_id`);
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_applier` FOREIGN KEY (`contract_id`, `applied_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_contract` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_source_roommate` FOREIGN KEY (`source_roommate_request_id`, `contract_id`) REFERENCES `roommate_requests` (`id`, `target_contract_id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_applicant` FOREIGN KEY (`applicant_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_requester` FOREIGN KEY (`requested_by_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_representative` FOREIGN KEY (`contract_id`, `representative_room_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_representative_consent` FOREIGN KEY (`representative_room_tenant_id`, `representative_consented_by_id`) REFERENCES `room_tenants` (`id`, `tenant_id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_applicant_consent` FOREIGN KEY (`applicant_consented_by_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_reviewer` FOREIGN KEY (`contract_id`, `reviewed_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_completed` FOREIGN KEY (`id`, `contract_id`, `applicant_id`, `completed_room_tenant_id`) REFERENCES `room_tenants` (`join_request_id`, `contract_id`, `tenant_id`, `id`);
ALTER TABLE `roommate_profiles` ADD CONSTRAINT `fk_roommate_profile_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `roommate_profiles` ADD CONSTRAINT `fk_roommate_profile_stay` FOREIGN KEY (`current_room_tenant_id`, `tenant_id`) REFERENCES `room_tenants` (`id`, `tenant_id`);
ALTER TABLE `profile_lifestyles` ADD CONSTRAINT `fk_profile_lifestyle_profile` FOREIGN KEY (`profile_id`) REFERENCES `roommate_profiles` (`id`);
ALTER TABLE `profile_lifestyles` ADD CONSTRAINT `fk_profile_lifestyle_criterion` FOREIGN KEY (`criterion_id`) REFERENCES `lifestyle_criteria` (`id`);
ALTER TABLE `roommate_requests` ADD CONSTRAINT `fk_roommate_request_sender` FOREIGN KEY (`sender_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `roommate_requests` ADD CONSTRAINT `fk_roommate_request_receiver` FOREIGN KEY (`receiver_id`) REFERENCES `tenants` (`id`);
ALTER TABLE `roommate_requests` ADD CONSTRAINT `fk_roommate_request_contract` FOREIGN KEY (`target_contract_id`) REFERENCES `contracts` (`id`);
ALTER TABLE `invoices` ADD CONSTRAINT `fk_invoice_contract_room` FOREIGN KEY (`contract_id`, `room_id`) REFERENCES `contracts` (`id`, `room_id`);
ALTER TABLE `invoices` ADD CONSTRAINT `fk_invoice_revision` FOREIGN KEY (`contract_id`, `contract_revision_id`) REFERENCES `contract_revisions` (`contract_id`, `id`);
ALTER TABLE `invoices` ADD CONSTRAINT `fk_invoice_payer` FOREIGN KEY (`contract_id`, `payer_room_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`);
ALTER TABLE `invoices` ADD CONSTRAINT `fk_invoice_replacement` FOREIGN KEY (`replacement_of_id`, `contract_id`, `billing_period`) REFERENCES `invoices` (`id`, `contract_id`, `billing_period`);
ALTER TABLE `invoices` ADD CONSTRAINT `fk_invoice_created_by_id` FOREIGN KEY (`created_by_id`) REFERENCES `landlords` (`id`);
ALTER TABLE `invoices` ADD CONSTRAINT `fk_invoice_paid_by_id` FOREIGN KEY (`paid_by_id`) REFERENCES `landlords` (`id`);
ALTER TABLE `invoices` ADD CONSTRAINT `fk_invoice_cancelled_by_id` FOREIGN KEY (`cancelled_by_id`) REFERENCES `landlords` (`id`);
ALTER TABLE `invoice_items` ADD CONSTRAINT `fk_invoice_items_invoice_room` FOREIGN KEY (`invoice_id`, `room_id`) REFERENCES `invoices` (`id`, `room_id`);
ALTER TABLE `invoice_items` ADD CONSTRAINT `fk_invoice_items_room_service` FOREIGN KEY (`room_service_id`, `room_id`) REFERENCES `room_services` (`id`, `room_id`);
ALTER TABLE `reviews` ADD CONSTRAINT `fk_review_stay` FOREIGN KEY (`room_tenant_id`, `contract_id`, `room_id`, `reviewer_id`) REFERENCES `room_tenants` (`id`, `contract_id`, `room_id`, `tenant_id`);
ALTER TABLE `reviews` ADD CONSTRAINT `fk_review_hidden_by` FOREIGN KEY (`hidden_by_id`) REFERENCES `admins` (`id`);
ALTER TABLE `conversations` ADD CONSTRAINT `fk_conversation_room` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`);
ALTER TABLE `conversations` ADD CONSTRAINT `fk_conversation_post_room` FOREIGN KEY (`post_id`, `room_id`) REFERENCES `posts` (`id`, `room_id`);
ALTER TABLE `conversations` ADD CONSTRAINT `fk_conversation_roommate` FOREIGN KEY (`roommate_request_id`) REFERENCES `roommate_requests` (`id`);
ALTER TABLE `conversations` ADD CONSTRAINT `fk_conversation_last_message` FOREIGN KEY (`id`, `last_message_id`) REFERENCES `chat_messages` (`conversation_id`, `id`);
ALTER TABLE `conversation_participants` ADD CONSTRAINT `fk_participants_conversation` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`);
ALTER TABLE `conversation_participants` ADD CONSTRAINT `fk_participants_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `chat_messages` ADD CONSTRAINT `fk_messages_participant` FOREIGN KEY (`conversation_id`, `sender_id`) REFERENCES `conversation_participants` (`conversation_id`, `user_id`);
ALTER TABLE `notifications` ADD CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `reports` ADD CONSTRAINT `fk_reports_reporter_id` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`);
ALTER TABLE `reports` ADD CONSTRAINT `fk_reports_reported_user_id` FOREIGN KEY (`reported_user_id`) REFERENCES `users` (`id`);
ALTER TABLE `reports` ADD CONSTRAINT `fk_reports_reported_post_id` FOREIGN KEY (`reported_post_id`) REFERENCES `posts` (`id`);
ALTER TABLE `reports` ADD CONSTRAINT `fk_reports_contract_id` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`);
ALTER TABLE `reports` ADD CONSTRAINT `fk_reports_roommate_request_id` FOREIGN KEY (`roommate_request_id`) REFERENCES `roommate_requests` (`id`);
ALTER TABLE `reports` ADD CONSTRAINT `fk_reports_handled_by_id` FOREIGN KEY (`handled_by_id`) REFERENCES `admins` (`id`);
ALTER TABLE `moderation_actions` ADD CONSTRAINT `fk_moderation_actor_user_id` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`);
ALTER TABLE `moderation_actions` ADD CONSTRAINT `fk_moderation_target_user_id` FOREIGN KEY (`target_user_id`) REFERENCES `users` (`id`);
ALTER TABLE `moderation_actions` ADD CONSTRAINT `fk_moderation_target_post_id` FOREIGN KEY (`target_post_id`) REFERENCES `posts` (`id`);
ALTER TABLE `moderation_actions` ADD CONSTRAINT `fk_moderation_target_report_id` FOREIGN KEY (`target_report_id`) REFERENCES `reports` (`id`);
ALTER TABLE `moderation_actions` ADD CONSTRAINT `fk_moderation_related_report_id` FOREIGN KEY (`related_report_id`) REFERENCES `reports` (`id`);
ALTER TABLE `moderation_actions` ADD CONSTRAINT `fk_moderation_target_landlord_verification_id` FOREIGN KEY (`target_landlord_verification_id`) REFERENCES `landlord_verifications` (`id`);
ALTER TABLE `moderation_actions` ADD CONSTRAINT `fk_moderation_target_tenant_verification_id` FOREIGN KEY (`target_tenant_verification_id`) REFERENCES `tenant_identity_verifications` (`id`);

-- Cấu hình hiệu lực: chỉ dịch vụ còn bật ở cả nhà và phòng mới được tính cho kỳ mới.
CREATE VIEW `active_room_services` AS
SELECT
  rs.id AS room_service_id,
  rs.room_id,
  rs.house_id,
  hs.id AS house_service_id,
  hs.name,
  hs.unit,
  COALESCE(rs.unit_price_override, hs.default_unit_price) AS unit_price,
  COALESCE(rs.calculation_method_override, hs.default_calculation_method) AS calculation_method
FROM `room_services` AS rs
JOIN `house_services` AS hs ON hs.id = rs.house_service_id AND hs.house_id = rs.house_id
WHERE rs.is_active = TRUE AND hs.is_active = TRUE;

-- Tổng tiền đọc trực tiếp từ các dòng đã chốt; DISCOUNT là số dương được trừ khỏi tổng.
CREATE VIEW `invoice_totals` AS
SELECT
  i.id AS invoice_id,
  COALESCE(SUM(CASE WHEN item.item_type = 'RENT' THEN item.amount ELSE 0 END), 0) AS rent_amount,
  COALESCE(SUM(CASE WHEN item.item_type = 'SERVICE' THEN item.amount ELSE 0 END), 0) AS service_amount,
  COALESCE(SUM(CASE WHEN item.item_type = 'OTHER' THEN item.amount ELSE 0 END), 0) AS other_amount,
  COALESCE(SUM(CASE WHEN item.item_type = 'DISCOUNT' THEN item.amount ELSE 0 END), 0) AS discount_amount,
  COALESCE(SUM(CASE WHEN item.item_type = 'DISCOUNT' THEN -item.amount ELSE item.amount END), 0) AS total_amount
FROM `invoices` AS i
LEFT JOIN `invoice_items` AS item ON item.invoice_id = i.id
GROUP BY i.id;

-- Tạo DRAFT, thêm/sửa các dòng, sau đó chuyển sang UNPAID trong cùng giao dịch.
-- Các trạng thái đã phát hành chỉ đổi trạng thái xử lý; nội dung và dòng tiền là bất biến.
DELIMITER $$

CREATE TRIGGER `trg_viewings_before_update`
BEFORE UPDATE ON `room_viewing_requests` FOR EACH ROW
BEGIN
  DECLARE live_contract_id BIGINT DEFAULT NULL;
  IF OLD.rental_decision = 'AGREED' AND NEW.rental_decision <> 'AGREED' THEN
    SELECT id INTO live_contract_id FROM `contracts`
    WHERE viewing_id = OLD.id AND status IN ('DRAFT', 'PENDING_CONFIRMATION', 'CONFIRMED', 'ACTIVE')
    LIMIT 1 FOR UPDATE;
    IF live_contract_id IS NOT NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cancel the linked contract before changing the rental decision';
    END IF;
  END IF;
END$$

CREATE TRIGGER `trg_contracts_before_insert`
BEFORE INSERT ON `contracts` FOR EACH ROW
BEGIN
  DECLARE viewing_status VARCHAR(40) DEFAULT NULL;
  DECLARE viewing_decision VARCHAR(40) DEFAULT NULL;
  IF NEW.source = 'NEW_RENTAL' THEN
    SELECT status, rental_decision INTO viewing_status, viewing_decision
    FROM `room_viewing_requests` WHERE id = NEW.viewing_id FOR UPDATE;
    IF viewing_status IS NULL OR viewing_status <> 'COMPLETED' OR viewing_decision <> 'AGREED' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New rental requires a completed and agreed viewing';
    END IF;
  END IF;
END$$

CREATE TRIGGER `trg_contracts_before_update`
BEFORE UPDATE ON `contracts` FOR EACH ROW
BEGIN
  DECLARE viewing_status VARCHAR(40) DEFAULT NULL;
  DECLARE viewing_decision VARCHAR(40) DEFAULT NULL;
  DECLARE revision_status VARCHAR(40) DEFAULT NULL;
  DECLARE active_representative_count BIGINT DEFAULT 0;
  IF NEW.source = 'NEW_RENTAL' AND NEW.status IN ('DRAFT', 'PENDING_CONFIRMATION', 'CONFIRMED', 'ACTIVE') THEN
    SELECT status, rental_decision INTO viewing_status, viewing_decision
    FROM `room_viewing_requests` WHERE id = NEW.viewing_id FOR UPDATE;
    IF viewing_status IS NULL OR viewing_status <> 'COMPLETED' OR viewing_decision <> 'AGREED' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Live rental contract requires an agreed viewing';
    END IF;
  END IF;
  IF NEW.status IN ('CONFIRMED', 'ACTIVE') THEN
    SELECT status INTO revision_status FROM `contract_revisions`
    WHERE id = NEW.current_revision_id AND contract_id = NEW.id;
    IF revision_status IS NULL
      OR (NEW.source = 'PAPER_IMPORT' AND revision_status <> 'IMPORTED')
      OR (NEW.source <> 'PAPER_IMPORT' AND revision_status <> 'CONFIRMED') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract requires its confirmed current revision';
    END IF;
  END IF;
  IF NEW.status = 'ACTIVE' THEN
    SELECT COUNT(*) INTO active_representative_count FROM `room_tenants`
    WHERE id = NEW.representative_room_tenant_id AND contract_id = NEW.id
      AND status = 'ACTIVE' AND move_in_date BETWEEN NEW.start_date AND NEW.end_date
      AND move_in_confirmed_at <= NEW.activated_at;
    IF active_representative_count = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract activation requires confirmed representative move-in';
    END IF;
  END IF;
END$$

CREATE TRIGGER `trg_invoices_before_insert`
BEFORE INSERT ON `invoices` FOR EACH ROW
BEGIN
  IF NEW.status <> 'DRAFT' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New invoices must start as DRAFT';
  END IF;
END$$

CREATE TRIGGER `trg_invoices_before_update`
BEFORE UPDATE ON `invoices` FOR EACH ROW
BEGIN
  DECLARE item_count BIGINT DEFAULT 0;
  DECLARE invoice_total DECIMAL(20,2) DEFAULT 0;

  IF OLD.status IN ('PAID', 'CANCELLED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Final invoices cannot be changed';
  END IF;

  IF (OLD.status = 'DRAFT' AND NEW.status NOT IN ('DRAFT', 'UNPAID', 'CANCELLED'))
    OR (OLD.status = 'UNPAID' AND NEW.status NOT IN ('UNPAID', 'OVERDUE', 'PAID', 'CANCELLED'))
    OR (OLD.status = 'OVERDUE' AND NEW.status NOT IN ('OVERDUE', 'PAID', 'CANCELLED')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid invoice status transition';
  END IF;

  IF OLD.status <> 'DRAFT' AND (
    OLD.contract_id <> NEW.contract_id OR OLD.room_id <> NEW.room_id
    OR OLD.contract_revision_id <> NEW.contract_revision_id
    OR OLD.payer_room_tenant_id <> NEW.payer_room_tenant_id
    OR OLD.payer_snapshot <> NEW.payer_snapshot
    OR OLD.billing_period <> NEW.billing_period OR OLD.due_date <> NEW.due_date
    OR OLD.occupant_count_at_billing <> NEW.occupant_count_at_billing
    OR OLD.created_by_id <> NEW.created_by_id
    OR NOT (OLD.replacement_of_id <=> NEW.replacement_of_id)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Issued invoice content cannot be changed';
  END IF;

  IF OLD.status = 'DRAFT' AND NEW.status = 'UNPAID' THEN
    SELECT COUNT(*), COALESCE(SUM(CASE WHEN item_type = 'DISCOUNT' THEN -amount ELSE amount END), 0)
      INTO item_count, invoice_total
    FROM `invoice_items` WHERE invoice_id = NEW.id;
    IF item_count = 0 OR invoice_total < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invoice needs items and nonnegative total';
    END IF;
  END IF;
END$$

CREATE TRIGGER `trg_invoice_items_before_insert`
BEFORE INSERT ON `invoice_items` FOR EACH ROW
BEGIN
  DECLARE invoice_status VARCHAR(40);
  SELECT status INTO invoice_status FROM `invoices` WHERE id = NEW.invoice_id;
  IF invoice_status IS NULL OR invoice_status <> 'DRAFT' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invoice items can only be added to DRAFT';
  END IF;
END$$

CREATE TRIGGER `trg_invoice_items_before_update`
BEFORE UPDATE ON `invoice_items` FOR EACH ROW
BEGIN
  DECLARE invoice_status VARCHAR(40);
  IF NEW.invoice_id <> OLD.invoice_id OR NEW.room_id <> OLD.room_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invoice items cannot move between invoices or rooms';
  END IF;
  SELECT status INTO invoice_status FROM `invoices` WHERE id = OLD.invoice_id;
  IF invoice_status IS NULL OR invoice_status <> 'DRAFT' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Issued invoice items cannot be changed';
  END IF;
END$$

CREATE TRIGGER `trg_invoice_items_before_delete`
BEFORE DELETE ON `invoice_items` FOR EACH ROW
BEGIN
  DECLARE invoice_status VARCHAR(40);
  SELECT status INTO invoice_status FROM `invoices` WHERE id = OLD.invoice_id;
  IF invoice_status IS NULL OR invoice_status <> 'DRAFT' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Issued invoice items cannot be deleted';
  END IF;
END$$

DELIMITER ;
