-- Axialy Admin – baseline schema
-- Compatible with MySQL 8 (DigitalOcean managed DB)

-- 1️⃣  Database -------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS `axialy_admin`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `axialy_admin`;

-- 2️⃣  Tables ---------------------------------------------------------------

-- Drop old copies if the script is reapplied on a fresh cluster
DROP TABLE IF EXISTS `admin_user_sessions`;
DROP TABLE IF EXISTS `admin_users`;

-- ── admin_users ───────────────────────────────────────────────────────────
CREATE TABLE `admin_users` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username`     VARCHAR(50)  NOT NULL,
  `password`     VARCHAR(255) NOT NULL,
  `email`        VARCHAR(255) NOT NULL,
  `is_active`    TINYINT(1)   NOT NULL DEFAULT 1,
  `is_sys_admin` TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME              DEFAULT NULL
                                      ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_admin_users_username` (`username`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- ── admin_user_sessions ───────────────────────────────────────────────────
CREATE TABLE `admin_user_sessions` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_user_id` INT UNSIGNED NOT NULL,
  `session_token` CHAR(64)     NOT NULL,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at`    DATETIME     NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_admin_user_sessions_user` (`admin_user_id`),
  CONSTRAINT `fk_admin_user_sessions_user`
    FOREIGN KEY (`admin_user_id`)
    REFERENCES `admin_users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- 3️⃣  Done ---------------------------------------------------------------
COMMIT;
