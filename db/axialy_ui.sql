-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 24, 2025 at 10:56 AM
-- Server version: 10.6.22-MariaDB-cll-lve
-- PHP Version: 8.3.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

SET SESSION sql_require_primary_key = 0;

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `Axialy_UI`
--

-- --------------------------------------------------------

--
-- Table structure for table `analysis_package_focus_areas`
--

CREATE TABLE `analysis_package_focus_areas` (
  `id` int(10) UNSIGNED NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED NOT NULL,
  `current_analysis_package_focus_area_versions_id` int(10) UNSIGNED DEFAULT NULL,
  `focus_area_name` varchar(255) NOT NULL,
  `focus_area_value` text DEFAULT NULL,
  `collaboration_approach` text DEFAULT NULL,
  `focus_area_abstract` text DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT 0,
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `analysis_package_focus_area_records`
--

CREATE TABLE `analysis_package_focus_area_records` (
  `id` int(10) UNSIGNED NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED DEFAULT NULL,
  `analysis_package_focus_areas_id` int(10) UNSIGNED DEFAULT NULL,
  `analysis_package_focus_area_versions_id` int(10) UNSIGNED NOT NULL,
  `grid_index` int(11) DEFAULT NULL,
  `display_order` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `is_deleted` tinyint(1) NOT NULL DEFAULT 0,
  `input_text_summaries_id` int(10) UNSIGNED DEFAULT NULL,
  `properties` longtext NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `analysis_package_focus_area_versions`
--

CREATE TABLE `analysis_package_focus_area_versions` (
  `id` int(10) UNSIGNED NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED DEFAULT NULL,
  `analysis_package_focus_areas_id` int(10) UNSIGNED NOT NULL,
  `focus_area_version_number` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `focus_area_revision_summary` text DEFAULT NULL,
  `focus_area_name_override` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `analysis_package_headers`
--

CREATE TABLE `analysis_package_headers` (
  `id` int(10) UNSIGNED NOT NULL,
  `package_name` varchar(255) NOT NULL,
  `short_summary` text DEFAULT NULL,
  `long_description` longtext DEFAULT NULL,
  `axialy_outputs_id` int(10) UNSIGNED DEFAULT NULL,
  `default_organization_id` int(11) NOT NULL,
  `custom_organization_id` int(11) DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT 0,
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `axialy_outputs`
--

CREATE TABLE `axialy_outputs` (
  `id` int(10) UNSIGNED NOT NULL,
  `input_text_summaries_id` int(10) UNSIGNED NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED NOT NULL,
  `axialy_scenario_title` varchar(255) NOT NULL,
  `axialy_output_document` longtext NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `custom_organizations`
--

CREATE TABLE `custom_organizations` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `custom_organization_name` varchar(255) NOT NULL,
  `point_of_contact` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `organization_notes` text DEFAULT NULL,
  `logo_path` varchar(255) DEFAULT NULL,
  `image_file` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `default_organizations`
--

CREATE TABLE `default_organizations` (
  `id` int(11) NOT NULL,
  `default_organization_name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `documents`
--

CREATE TABLE `documents` (
  `id` int(10) UNSIGNED NOT NULL,
  `doc_key` varchar(100) NOT NULL,
  `doc_name` varchar(255) NOT NULL,
  `active_version_id` int(10) UNSIGNED DEFAULT NULL,
  `axia_customer_docs` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL,
  `file_pdf_data` longblob DEFAULT NULL,
  `file_docx_data` longblob DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `document_versions`
--

CREATE TABLE `document_versions` (
  `id` int(10) UNSIGNED NOT NULL,
  `documents_id` int(10) UNSIGNED NOT NULL,
  `version_number` int(11) NOT NULL DEFAULT 0,
  `file_content` longtext DEFAULT NULL,
  `file_content_format` enum('md','html','json','xml') NOT NULL DEFAULT 'md',
  `file_pdf_data` longblob DEFAULT NULL,
  `file_docx_data` longblob DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_verifications`
--

CREATE TABLE `email_verifications` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `focus_organization`
--

CREATE TABLE `focus_organization` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `custom_organization_id` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `input_text_summaries`
--

CREATE TABLE `input_text_summaries` (
  `id` int(10) UNSIGNED NOT NULL,
  `input_text_title` varchar(255) NOT NULL,
  `input_text_summary` text DEFAULT NULL,
  `input_text` longtext NOT NULL,
  `ui_datetime` datetime NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `issues`
--

CREATE TABLE `issues` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(11) NOT NULL,
  `issue_title` varchar(255) NOT NULL,
  `issue_description` text NOT NULL,
  `status` enum('New','Reviewed','Open','In Progress','Resolved','Closed') NOT NULL DEFAULT 'Open',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `promo_codes`
--

CREATE TABLE `promo_codes` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `code_type` enum('unlimited','limited') NOT NULL DEFAULT 'unlimited',
  `limited_days` int(10) UNSIGNED DEFAULT NULL,
  `statement_required` tinyint(1) NOT NULL DEFAULT 0,
  `statement` text DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `usage_limit` int(10) UNSIGNED DEFAULT NULL,
  `usage_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `promo_code_redemptions`
--

CREATE TABLE `promo_code_redemptions` (
  `id` int(10) UNSIGNED NOT NULL,
  `promo_code_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(11) NOT NULL,
  `redeemed_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stakeholder_experience_feedback`
--

CREATE TABLE `stakeholder_experience_feedback` (
  `id` int(11) NOT NULL,
  `stakeholder_feedback_details_id` int(11) NOT NULL,
  `feedback_text` text NOT NULL,
  `experience_feedback_text` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stakeholder_feedback_headers`
--

CREATE TABLE `stakeholder_feedback_headers` (
  `id` int(11) NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED NOT NULL,
  `analysis_package_focus_areas_id` int(10) UNSIGNED NOT NULL,
  `analysis_package_focus_area_versions_id` int(10) UNSIGNED NOT NULL,
  `stakeholder_email` varchar(255) NOT NULL,
  `email_personal_message` varchar(255) NOT NULL,
  `form_type` enum('General','Itemized') NOT NULL DEFAULT 'General',
  `primary_response_option` varchar(255) DEFAULT NULL,
  `secondary_response_option` varchar(255) DEFAULT NULL,
  `stakeholder_request_grid_indexes` varchar(255) NOT NULL DEFAULT '',
  `feedback_target` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `pin` int(11) NOT NULL,
  `responded_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stakeholder_feedback_header_requests`
--

CREATE TABLE `stakeholder_feedback_header_requests` (
  `id` int(11) NOT NULL,
  `stakeholder_email` varchar(255) NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED NOT NULL,
  `focus_areas_id` int(10) UNSIGNED NOT NULL,
  `message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stakeholder_general_feedback`
--

CREATE TABLE `stakeholder_general_feedback` (
  `id` int(11) NOT NULL,
  `stakeholder_feedback_headers_id` int(11) NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED DEFAULT NULL,
  `analysis_package_focus_areas_id` int(10) UNSIGNED DEFAULT NULL,
  `analysis_package_focus_area_versions_id` int(10) UNSIGNED NOT NULL,
  `stakeholder_feedback_text` text NOT NULL,
  `resolved_action` varchar(255) DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stakeholder_itemized_feedback`
--

CREATE TABLE `stakeholder_itemized_feedback` (
  `id` int(11) NOT NULL,
  `stakeholder_feedback_headers_id` int(11) NOT NULL,
  `analysis_package_headers_id` int(10) UNSIGNED NOT NULL,
  `analysis_package_focus_areas_id` int(10) UNSIGNED NOT NULL,
  `analysis_package_focus_area_versions_id` int(10) UNSIGNED NOT NULL,
  `grid_index` int(11) NOT NULL,
  `feedback_item_response` varchar(255) NOT NULL,
  `stakeholder_feedback_text` text DEFAULT NULL,
  `resolved_action` varchar(255) DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stakeholder_sessions`
--

CREATE TABLE `stakeholder_sessions` (
  `id` int(11) NOT NULL,
  `stakeholder_feedback_headers_id` int(11) NOT NULL,
  `session_token` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ui_users`
--

CREATE TABLE `ui_users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `user_email` varchar(255) NOT NULL,
  `default_organization_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `subscription_active` tinyint(1) NOT NULL DEFAULT 0,
  `subscription_id` varchar(255) DEFAULT NULL,
  `trial_end_date` datetime DEFAULT NULL,
  `subscription_plan_type` varchar(10) DEFAULT NULL,
  `sys_admin` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ui_user_sessions`
--

CREATE TABLE `ui_user_sessions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `session_token` varchar(255) NOT NULL,
  `product` varchar(10) NOT NULL DEFAULT 'ui',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_agreement_acceptances`
--

CREATE TABLE `user_agreement_acceptances` (
  `id` int(11) UNSIGNED NOT NULL,
  `user_id` int(11) NOT NULL,
  `document_versions_id` int(10) UNSIGNED NOT NULL,
  `accepted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_focus_organizations`
--

CREATE TABLE `user_focus_organizations` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `focus_org_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `analysis_package_focus_areas`
--
ALTER TABLE `analysis_package_focus_areas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_package_deleted` (`analysis_package_headers_id`,`is_deleted`),
  ADD KEY `idx_current_version` (`current_analysis_package_focus_area_versions_id`),
  ADD KEY `idx_headers_id` (`analysis_package_headers_id`);

--
-- Indexes for table `analysis_package_focus_area_records`
--
ALTER TABLE `analysis_package_focus_area_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `analysis_package_headers_id` (`analysis_package_headers_id`),
  ADD KEY `ai_feedback_data_ibfk_1` (`input_text_summaries_id`),
  ADD KEY `idx_version_deleted` (`analysis_package_focus_area_versions_id`,`is_deleted`),
  ADD KEY `idx_apfa_id` (`analysis_package_focus_areas_id`);

--
-- Indexes for table `analysis_package_focus_area_versions`
--
ALTER TABLE `analysis_package_focus_area_versions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_area_version` (`analysis_package_focus_areas_id`,`focus_area_version_number`),
  ADD KEY `idx_focus_areas_id` (`analysis_package_focus_areas_id`),
  ADD KEY `idx_apfav_aph_id` (`analysis_package_headers_id`);

--
-- Indexes for table `analysis_package_headers`
--
ALTER TABLE `analysis_package_headers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `analysis_package_headers_ibfk_1` (`default_organization_id`),
  ADD KEY `analysis_package_headers_custom_org_fk` (`custom_organization_id`),
  ADD KEY `fk_analysis_package_headers_axialy_outputs` (`axialy_outputs_id`);

--
-- Indexes for table `axialy_outputs`
--
ALTER TABLE `axialy_outputs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `custom_organizations`
--
ALTER TABLE `custom_organizations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_org_name` (`custom_organization_name`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `default_organizations`
--
ALTER TABLE `default_organizations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_organization_name` (`default_organization_name`);

--
-- Indexes for table `documents`
--
ALTER TABLE `documents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_doc_key` (`doc_key`);

--
-- Indexes for table `document_versions`
--
ALTER TABLE `document_versions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_documents_id` (`documents_id`);

--
-- Indexes for table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `email` (`email`);

--
-- Indexes for table `focus_organization`
--
ALTER TABLE `focus_organization`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `custom_organization_id` (`custom_organization_id`);

--
-- Indexes for table `input_text_summaries`
--
ALTER TABLE `input_text_summaries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `issues`
--
ALTER TABLE `issues`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_issue_user` (`user_id`);

--
-- Indexes for table `promo_codes`
--
ALTER TABLE `promo_codes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `promo_code_redemptions`
--
ALTER TABLE `promo_code_redemptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `promo_code_id_idx` (`promo_code_id`),
  ADD KEY `user_id_idx` (`user_id`);

--
-- Indexes for table `stakeholder_experience_feedback`
--
ALTER TABLE `stakeholder_experience_feedback`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stakeholder_feedback_details_id` (`stakeholder_feedback_details_id`);

--
-- Indexes for table `stakeholder_feedback_headers`
--
ALTER TABLE `stakeholder_feedback_headers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `analysis_package_headers_id` (`analysis_package_headers_id`),
  ADD KEY `stakeholder_feedback_headers_apfav_fk` (`analysis_package_focus_area_versions_id`),
  ADD KEY `idx_headers_apfa_id` (`analysis_package_focus_areas_id`);

--
-- Indexes for table `stakeholder_feedback_header_requests`
--
ALTER TABLE `stakeholder_feedback_header_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `analysis_package_headers_id` (`analysis_package_headers_id`),
  ADD KEY `stakeholder_feedback_header_requests_fa_fk` (`focus_areas_id`);

--
-- Indexes for table `stakeholder_general_feedback`
--
ALTER TABLE `stakeholder_general_feedback`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stakeholder_feedback_headers_id` (`stakeholder_feedback_headers_id`),
  ADD KEY `stakeholder_feedback_details_apfav_fk` (`analysis_package_focus_area_versions_id`),
  ADD KEY `idx_sfd_af_id` (`analysis_package_focus_areas_id`),
  ADD KEY `idx_sfd_aph_id` (`analysis_package_headers_id`);

--
-- Indexes for table `stakeholder_itemized_feedback`
--
ALTER TABLE `stakeholder_itemized_feedback`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stakeholder_feedback_headers_id` (`stakeholder_feedback_headers_id`),
  ADD KEY `idx_feedback_resolved` (`resolved_at`),
  ADD KEY `idx_focus_area_versions_id` (`analysis_package_focus_area_versions_id`),
  ADD KEY `idx_apfa_id` (`analysis_package_focus_areas_id`);

--
-- Indexes for table `stakeholder_sessions`
--
ALTER TABLE `stakeholder_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stakeholder_feedback_headers_id` (`stakeholder_feedback_headers_id`);

--
-- Indexes for table `ui_users`
--
ALTER TABLE `ui_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `user_email` (`user_email`),
  ADD KEY `default_organization_id` (`default_organization_id`),
  ADD KEY `idx_subscription_active` (`subscription_active`),
  ADD KEY `idx_subscription_id` (`subscription_id`),
  ADD KEY `idx_trial_end_date` (`trial_end_date`);

--
-- Indexes for table `ui_user_sessions`
--
ALTER TABLE `ui_user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `session_token` (`session_token`);

--
-- Indexes for table `user_agreement_acceptances`
--
ALTER TABLE `user_agreement_acceptances`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_user_document_ver` (`user_id`,`document_versions_id`),
  ADD KEY `user_agreement_acceptances_doc_version_fk` (`document_versions_id`);

--
-- Indexes for table `user_focus_organizations`
--
ALTER TABLE `user_focus_organizations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id_unique` (`user_id`),
  ADD KEY `focus_org_id` (`focus_org_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `analysis_package_focus_areas`
--
ALTER TABLE `analysis_package_focus_areas`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `analysis_package_focus_area_records`
--
ALTER TABLE `analysis_package_focus_area_records`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `analysis_package_focus_area_versions`
--
ALTER TABLE `analysis_package_focus_area_versions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `analysis_package_headers`
--
ALTER TABLE `analysis_package_headers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `axialy_outputs`
--
ALTER TABLE `axialy_outputs`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `custom_organizations`
--
ALTER TABLE `custom_organizations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `default_organizations`
--
ALTER TABLE `default_organizations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `documents`
--
ALTER TABLE `documents`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `document_versions`
--
ALTER TABLE `document_versions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_verifications`
--
ALTER TABLE `email_verifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `focus_organization`
--
ALTER TABLE `focus_organization`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `input_text_summaries`
--
ALTER TABLE `input_text_summaries`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `issues`
--
ALTER TABLE `issues`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `promo_codes`
--
ALTER TABLE `promo_codes`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `promo_code_redemptions`
--
ALTER TABLE `promo_code_redemptions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stakeholder_experience_feedback`
--
ALTER TABLE `stakeholder_experience_feedback`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stakeholder_feedback_headers`
--
ALTER TABLE `stakeholder_feedback_headers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stakeholder_feedback_header_requests`
--
ALTER TABLE `stakeholder_feedback_header_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stakeholder_general_feedback`
--
ALTER TABLE `stakeholder_general_feedback`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stakeholder_itemized_feedback`
--
ALTER TABLE `stakeholder_itemized_feedback`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stakeholder_sessions`
--
ALTER TABLE `stakeholder_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ui_users`
--
ALTER TABLE `ui_users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ui_user_sessions`
--
ALTER TABLE `ui_user_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_agreement_acceptances`
--
ALTER TABLE `user_agreement_acceptances`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_focus_organizations`
--
ALTER TABLE `user_focus_organizations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `analysis_package_focus_areas`
--
ALTER TABLE `analysis_package_focus_areas`
  ADD CONSTRAINT `fk_apfa_current_version` FOREIGN KEY (`current_analysis_package_focus_area_versions_id`) REFERENCES `analysis_package_focus_area_versions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_apfa_headers` FOREIGN KEY (`analysis_package_headers_id`) REFERENCES `analysis_package_headers` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `analysis_package_focus_area_records`
--
ALTER TABLE `analysis_package_focus_area_records`
  ADD CONSTRAINT `analysis_package_focus_area_records_apfa_fk` FOREIGN KEY (`analysis_package_focus_areas_id`) REFERENCES `analysis_package_focus_areas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `analysis_package_focus_area_records_ibfk_1` FOREIGN KEY (`input_text_summaries_id`) REFERENCES `input_text_summaries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `analysis_package_focus_area_records_ibfk_2` FOREIGN KEY (`analysis_package_headers_id`) REFERENCES `analysis_package_headers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_apfar_versions` FOREIGN KEY (`analysis_package_focus_area_versions_id`) REFERENCES `analysis_package_focus_area_versions` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `analysis_package_focus_area_versions`
--
ALTER TABLE `analysis_package_focus_area_versions`
  ADD CONSTRAINT `analysis_package_focus_area_versions_aph_fk` FOREIGN KEY (`analysis_package_headers_id`) REFERENCES `analysis_package_headers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_apfav_focus_areas` FOREIGN KEY (`analysis_package_focus_areas_id`) REFERENCES `analysis_package_focus_areas` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `analysis_package_headers`
--
ALTER TABLE `analysis_package_headers`
  ADD CONSTRAINT `analysis_package_headers_custom_org_fk` FOREIGN KEY (`custom_organization_id`) REFERENCES `custom_organizations` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `analysis_package_headers_ibfk_1` FOREIGN KEY (`default_organization_id`) REFERENCES `default_organizations` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_analysis_package_headers_axialy_outputs` FOREIGN KEY (`axialy_outputs_id`) REFERENCES `axialy_outputs` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `custom_organizations`
--
ALTER TABLE `custom_organizations`
  ADD CONSTRAINT `custom_organizations_user_fk` FOREIGN KEY (`user_id`) REFERENCES `ui_users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `document_versions`
--
ALTER TABLE `document_versions`
  ADD CONSTRAINT `document_versions_fk_1` FOREIGN KEY (`documents_id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `focus_organization`
--
ALTER TABLE `focus_organization`
  ADD CONSTRAINT `focus_organization_custom_org_fk` FOREIGN KEY (`custom_organization_id`) REFERENCES `custom_organizations` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `focus_organization_user_fk` FOREIGN KEY (`user_id`) REFERENCES `ui_users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `issues`
--
ALTER TABLE `issues`
  ADD CONSTRAINT `fk_issues_user` FOREIGN KEY (`user_id`) REFERENCES `ui_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `promo_code_redemptions`
--
ALTER TABLE `promo_code_redemptions`
  ADD CONSTRAINT `promo_code_redemptions_code_fk` FOREIGN KEY (`promo_code_id`) REFERENCES `promo_codes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `promo_code_redemptions_user_fk` FOREIGN KEY (`user_id`) REFERENCES `ui_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stakeholder_experience_feedback`
--
ALTER TABLE `stakeholder_experience_feedback`
  ADD CONSTRAINT `stakeholder_experience_feedback_ibfk_1` FOREIGN KEY (`stakeholder_feedback_details_id`) REFERENCES `stakeholder_general_feedback` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stakeholder_feedback_headers`
--
ALTER TABLE `stakeholder_feedback_headers`
  ADD CONSTRAINT `stakeholder_feedback_headers_apfa_fk` FOREIGN KEY (`analysis_package_focus_areas_id`) REFERENCES `analysis_package_focus_areas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_feedback_headers_apfav_fk` FOREIGN KEY (`analysis_package_focus_area_versions_id`) REFERENCES `analysis_package_focus_area_versions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_feedback_headers_ibfk_1` FOREIGN KEY (`analysis_package_headers_id`) REFERENCES `analysis_package_headers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stakeholder_feedback_header_requests`
--
ALTER TABLE `stakeholder_feedback_header_requests`
  ADD CONSTRAINT `stakeholder_feedback_header_requests_fa_fk` FOREIGN KEY (`focus_areas_id`) REFERENCES `analysis_package_focus_areas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_feedback_header_requests_ibfk_1` FOREIGN KEY (`analysis_package_headers_id`) REFERENCES `analysis_package_headers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stakeholder_general_feedback`
--
ALTER TABLE `stakeholder_general_feedback`
  ADD CONSTRAINT `stakeholder_feedback_details_apfa_fk` FOREIGN KEY (`analysis_package_focus_areas_id`) REFERENCES `analysis_package_focus_areas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_feedback_details_apfav_fk` FOREIGN KEY (`analysis_package_focus_area_versions_id`) REFERENCES `analysis_package_focus_area_versions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_feedback_details_aph_fk` FOREIGN KEY (`analysis_package_headers_id`) REFERENCES `analysis_package_headers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_general_feedback_ibfk_1` FOREIGN KEY (`stakeholder_feedback_headers_id`) REFERENCES `stakeholder_feedback_headers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stakeholder_itemized_feedback`
--
ALTER TABLE `stakeholder_itemized_feedback`
  ADD CONSTRAINT `stakeholder_feedback_records_apfa_fk` FOREIGN KEY (`analysis_package_focus_areas_id`) REFERENCES `analysis_package_focus_areas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_feedback_records_fav_fk` FOREIGN KEY (`analysis_package_focus_area_versions_id`) REFERENCES `analysis_package_focus_area_versions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `stakeholder_feedback_records_sh_fk` FOREIGN KEY (`stakeholder_feedback_headers_id`) REFERENCES `stakeholder_feedback_headers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stakeholder_sessions`
--
ALTER TABLE `stakeholder_sessions`
  ADD CONSTRAINT `stakeholder_sessions_ibfk_1` FOREIGN KEY (`stakeholder_feedback_headers_id`) REFERENCES `stakeholder_feedback_headers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ui_users`
--
ALTER TABLE `ui_users`
  ADD CONSTRAINT `ui_users_ibfk_1` FOREIGN KEY (`default_organization_id`) REFERENCES `default_organizations` (`id`);

--
-- Constraints for table `ui_user_sessions`
--
ALTER TABLE `ui_user_sessions`
  ADD CONSTRAINT `ui_user_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `ui_users` (`id`);

--
-- Constraints for table `user_agreement_acceptances`
--
ALTER TABLE `user_agreement_acceptances`
  ADD CONSTRAINT `user_agreement_acceptances_doc_version_fk` FOREIGN KEY (`document_versions_id`) REFERENCES `document_versions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `user_agreement_acceptances_user_fk` FOREIGN KEY (`user_id`) REFERENCES `ui_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_focus_organizations`
--
ALTER TABLE `user_focus_organizations`
  ADD CONSTRAINT `user_focus_organizations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `ui_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `user_focus_organizations_ibfk_2` FOREIGN KEY (`focus_org_id`) REFERENCES `custom_organizations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
