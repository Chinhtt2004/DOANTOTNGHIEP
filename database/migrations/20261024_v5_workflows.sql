-- V5 upgrade 2026-10-24; run once against the original 39-table V5.
-- Stop application writers and back up first. DDL implicitly commits in MySQL.
-- Do not use --force. A failed preflight makes no business-data changes.
USE room_rental_v5_20261023;
SET time_zone = '+00:00';
DELIMITER $$
DROP PROCEDURE IF EXISTS _v5_preflight_upgrade$$
CREATE PROCEDURE _v5_preflight_upgrade()
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='contract_representative_history')
    OR EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='contracts' AND column_name='initial_representative_room_tenant_id') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='V5 workflow upgrade is already applied or incomplete; do not rerun blindly';
  END IF;
  IF EXISTS (SELECT room_id FROM contracts WHERE status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE') GROUP BY room_id HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Preflight: reconcile multiple open contracts for the same room';
  END IF;
  IF EXISTS (SELECT 1 FROM contracts c LEFT JOIN room_tenants rt ON rt.id=c.representative_room_tenant_id AND rt.contract_id=c.id
    WHERE c.status='ACTIVE' AND (rt.id IS NULL OR rt.status<>'ACTIVE')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Preflight: reconcile ACTIVE contracts without an ACTIVE representative';
  END IF;
  IF EXISTS (SELECT 1 FROM room_tenants rt JOIN contracts c ON c.id=rt.contract_id
    WHERE c.status IN ('TERMINATED','EXPIRED','CANCELLED') AND rt.status IN ('ACTIVE','PLANNED')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Preflight: reconcile open stays on closed contracts';
  END IF;
  IF EXISTS (SELECT 1 FROM rooms r WHERE r.max_occupants <
    (SELECT COUNT(*) FROM room_tenants rt JOIN contracts c ON c.id=rt.contract_id WHERE rt.room_id=r.id
      AND (rt.status='ACTIVE' OR (rt.status='PLANNED' AND c.status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE'))))
    + (SELECT COUNT(*) FROM occupant_join_requests j JOIN contracts c ON c.id=j.contract_id WHERE c.room_id=r.id
      AND c.status='ACTIVE' AND j.status='APPROVED' AND j.hold_expires_at>UTC_TIMESTAMP(6)
      AND NOT EXISTS (SELECT 1 FROM room_tenants rt WHERE rt.join_request_id=j.id AND rt.status IN ('PLANNED','ACTIVE')))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Preflight: reconcile room overcapacity including planned members and valid holds';
  END IF;
END$$
CALL _v5_preflight_upgrade()$$
DROP PROCEDURE _v5_preflight_upgrade$$
DELIMITER ;

-- Replace the old update trigger only after validation; preserve the original viewing tenant.
DROP TRIGGER IF EXISTS trg_contracts_before_update;
ALTER TABLE contracts ADD COLUMN initial_representative_room_tenant_id BIGINT AFTER representative_room_tenant_id,
  MODIFY COLUMN live_room_id BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE') THEN room_id ELSE NULL END) STORED;
UPDATE contracts SET initial_representative_room_tenant_id=representative_room_tenant_id;
ALTER TABLE contracts DROP FOREIGN KEY fk_contract_viewing_representative,
  ADD KEY ix_contract_current_representative (id,representative_room_tenant_id),
  ADD KEY ix_contract_initial_representative (id,initial_representative_room_tenant_id,viewing_tenant_id);
ALTER TABLE contracts DROP INDEX ix_contract_viewing_representative;
ALTER TABLE contracts ADD CONSTRAINT fk_contract_initial_representative FOREIGN KEY(id,initial_representative_room_tenant_id) REFERENCES room_tenants(contract_id,id);
ALTER TABLE contracts ADD CONSTRAINT fk_contract_viewing_initial_rep FOREIGN KEY(id,initial_representative_room_tenant_id,viewing_tenant_id) REFERENCES room_tenants(contract_id,id,tenant_id);
ALTER TABLE contract_change_requests ADD COLUMN cancelled_at DATETIME(6), ADD COLUMN cancelled_by_id BIGINT, ADD COLUMN cancellation_reason VARCHAR(1000);
ALTER TABLE occupant_join_requests ADD COLUMN cancelled_by_id BIGINT, ADD COLUMN cancellation_reason VARCHAR(1000);

CREATE TABLE `contract_representative_history` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `contract_id` BIGINT NOT NULL,
  `room_tenant_id` BIGINT NOT NULL,
  `tenant_id` BIGINT,
  `name_snapshot` VARCHAR(150) NOT NULL,
  `event_type` VARCHAR(40) NOT NULL,
  `previous_history_id` BIGINT,
  `previous_room_tenant_id` BIGINT,
  `basis_revision_id` BIGINT,
  `started_at` DATETIME(6),
  `ended_at` DATETIME(6),
  `is_current` BOOLEAN NOT NULL DEFAULT TRUE,
  `recorded_by_id` BIGINT,
  `recorded_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `reason` VARCHAR(1000) NOT NULL,
  `consent_method` VARCHAR(40) NOT NULL,
  `consented_by_id` BIGINT,
  `consent_recorded_by_id` BIGINT,
  `consent_recorded_at` DATETIME(6),
  `consent_file_id` BIGINT,
  `ended_by_id` BIGINT,
  `end_reason` VARCHAR(1000),
  `current_contract_id` BIGINT GENERATED ALWAYS AS (CASE WHEN is_current = TRUE THEN contract_id ELSE NULL END) STORED,
  UNIQUE KEY `uq_rep_history_current` (`current_contract_id`),
  UNIQUE KEY `uq_rep_history_contract_id` (`contract_id`, `id`),
  KEY `ix_rep_history_timeline` (`contract_id`, `started_at`, `id`),
  KEY `ix_rep_history_member` (`contract_id`, `room_tenant_id`, `tenant_id`),
  CONSTRAINT `ck_rep_history_event` CHECK (event_type IN ('INITIAL','HANDOVER','LEGACY_BASELINE')),
  CONSTRAINT `ck_rep_history_bool` CHECK (is_current IN (0,1)),
  CONSTRAINT `ck_rep_history_dates` CHECK ((started_at IS NOT NULL OR event_type = 'LEGACY_BASELINE') AND (ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at)),
  CONSTRAINT `ck_rep_history_period` CHECK ((is_current = TRUE AND ended_at IS NULL) OR (is_current = FALSE AND (ended_at IS NOT NULL OR event_type = 'LEGACY_BASELINE'))),
  CONSTRAINT `ck_rep_history_previous` CHECK (event_type <> 'HANDOVER' OR (previous_history_id IS NOT NULL AND previous_room_tenant_id IS NOT NULL AND previous_room_tenant_id <> room_tenant_id AND recorded_by_id IS NOT NULL)),
  CONSTRAINT `ck_rep_history_consent` CHECK (
    (event_type = 'LEGACY_BASELINE' AND consent_method = 'LEGACY_UNKNOWN' AND consented_by_id IS NULL AND consent_recorded_by_id IS NULL AND consent_recorded_at IS NULL)
    OR (event_type = 'INITIAL' AND consent_method = 'NOT_REQUIRED' AND consented_by_id IS NULL AND consent_recorded_by_id IS NULL AND consent_recorded_at IS NULL)
    OR (event_type = 'HANDOVER' AND tenant_id IS NOT NULL AND consent_recorded_at IS NOT NULL AND (
      (consent_method = 'LANDLORD_RECORDED' AND consented_by_id IS NULL AND consent_recorded_by_id IS NOT NULL)
      OR (consent_method = 'TENANT_ACCOUNT' AND consented_by_id IS NOT NULL AND consented_by_id = tenant_id)
    ))
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
ALTER TABLE `contract_change_requests` ADD CONSTRAINT `fk_changes_cancelled_by` FOREIGN KEY (`cancelled_by_id`) REFERENCES `users` (`id`);
ALTER TABLE `occupant_join_requests` ADD CONSTRAINT `fk_join_cancelled_by` FOREIGN KEY (`cancelled_by_id`) REFERENCES `users` (`id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_member` FOREIGN KEY (`contract_id`, `room_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_account` FOREIGN KEY (`contract_id`, `room_tenant_id`, `tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`, `tenant_id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_previous` FOREIGN KEY (`contract_id`, `previous_history_id`) REFERENCES `contract_representative_history` (`contract_id`, `id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_previous_member` FOREIGN KEY (`contract_id`, `previous_room_tenant_id`) REFERENCES `room_tenants` (`contract_id`, `id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_revision` FOREIGN KEY (`contract_id`, `basis_revision_id`) REFERENCES `contract_revisions` (`contract_id`, `id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_recorder` FOREIGN KEY (`contract_id`, `recorded_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_consent_recorder` FOREIGN KEY (`contract_id`, `consent_recorded_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_consent_tenant` FOREIGN KEY (`room_tenant_id`, `consented_by_id`) REFERENCES `room_tenants` (`id`, `tenant_id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_ended_by` FOREIGN KEY (`contract_id`, `ended_by_id`) REFERENCES `contracts` (`id`, `landlord_id`);
ALTER TABLE `contract_representative_history` ADD CONSTRAINT `fk_rep_history_consent_file` FOREIGN KEY (`consent_file_id`) REFERENCES `files` (`id`);

-- Baselines deliberately keep unknown start/actor/consent unknown, including closed contracts.
INSERT INTO contract_representative_history(contract_id,room_tenant_id,tenant_id,name_snapshot,event_type,basis_revision_id,started_at,ended_at,is_current,reason,consent_method)
SELECT c.id,rt.id,rt.tenant_id,rt.full_name,'LEGACY_BASELINE',c.current_revision_id,NULL,
  CASE WHEN c.status IN ('TERMINATED','EXPIRED','CANCELLED') THEN c.closed_at ELSE NULL END,
  c.status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE'),
  'Imported V5 representative; original start and consent timestamps are unknown','LEGACY_UNKNOWN'
FROM contracts c JOIN room_tenants rt ON rt.id=c.representative_room_tenant_id AND rt.contract_id=c.id;

-- BEGIN V5 WORKFLOW OBJECTS 20261024
-- Shared source; scripts/build-database.cjs embeds this in schema.sql and the migration.
-- Public sp_* routines own their transaction. SET TRANSACTION rejects an active caller
-- transaction before START TRANSACTION can implicitly commit it. Use a fresh UTC session.
-- Application accounts should receive EXECUTE on public routines, not direct table writes
-- or EXECUTE on _v5_* helpers. The backend authenticates the supplied actor IDs.

CREATE OR REPLACE VIEW v5_room_capacity_usage AS
SELECT r.id AS room_id, r.max_occupants,
  (SELECT COUNT(*) FROM room_tenants rt WHERE rt.room_id = r.id AND rt.status = 'ACTIVE') AS active_count,
  (SELECT COUNT(*) FROM room_tenants rt JOIN contracts c ON c.id = rt.contract_id
   WHERE rt.room_id = r.id AND rt.status = 'PLANNED'
     AND c.status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE')) AS planned_count,
  (SELECT COUNT(*) FROM occupant_join_requests j JOIN contracts c ON c.id = j.contract_id
   WHERE c.room_id = r.id AND c.status = 'ACTIVE' AND j.status = 'APPROVED'
     AND j.hold_expires_at > UTC_TIMESTAMP(6)
     AND NOT EXISTS (SELECT 1 FROM room_tenants rt WHERE rt.join_request_id = j.id AND rt.status IN ('PLANNED','ACTIVE'))) AS held_count
FROM rooms r;

CREATE OR REPLACE VIEW v5_current_residents AS
SELECT rt.*, c.contract_number, c.landlord_id, c.status AS contract_status,
  (rt.id = c.representative_room_tenant_id) AS is_representative,
  (c.status <> 'ACTIVE') AS needs_reconciliation
FROM room_tenants rt JOIN contracts c ON c.id = rt.contract_id WHERE rt.status = 'ACTIVE';

CREATE OR REPLACE VIEW v5_representative_timeline AS
SELECT h.*, c.contract_number, c.room_id, c.landlord_id
FROM contract_representative_history h JOIN contracts c ON c.id = h.contract_id;

DELIMITER $$

DROP PROCEDURE IF EXISTS _v5_room_load$$
CREATE PROCEDURE _v5_room_load(IN p_room BIGINT, IN p_exclude_join BIGINT, OUT p_load BIGINT)
SQL SECURITY DEFINER
BEGIN
  SELECT active_count + planned_count + held_count INTO p_load FROM v5_room_capacity_usage WHERE room_id = p_room;
  IF p_exclude_join IS NOT NULL AND EXISTS (
    SELECT 1 FROM occupant_join_requests j JOIN contracts c ON c.id = j.contract_id
    WHERE j.id = p_exclude_join AND c.room_id = p_room AND c.status = 'ACTIVE'
      AND j.status = 'APPROVED' AND j.hold_expires_at > UTC_TIMESTAMP(6)
      AND NOT EXISTS (SELECT 1 FROM room_tenants rt WHERE rt.join_request_id = j.id AND rt.status IN ('PLANNED','ACTIVE'))
  ) THEN SET p_load = p_load - 1; END IF;
END$$

DROP PROCEDURE IF EXISTS _v5_sync_room$$
CREATE PROCEDURE _v5_sync_room(IN p_room BIGINT)
SQL SECURITY DEFINER
BEGIN
  UPDATE rooms SET status = CASE
    WHEN EXISTS (SELECT 1 FROM room_tenants rt WHERE rt.room_id = p_room AND rt.status = 'ACTIVE') THEN 'OCCUPIED'
    WHEN EXISTS (SELECT 1 FROM contracts c WHERE c.room_id = p_room AND c.status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE')) THEN 'RESERVED'
    WHEN status = 'MAINTENANCE' THEN 'MAINTENANCE' ELSE 'AVAILABLE' END,
    updated_at = UTC_TIMESTAMP(6) WHERE id = p_room;
END$$

DROP PROCEDURE IF EXISTS _v5_cancel_requests$$
CREATE PROCEDURE _v5_cancel_requests(IN p_contract BIGINT, IN p_actor BIGINT, IN p_reason VARCHAR(1000), IN p_keep_change BIGINT)
SQL SECURITY DEFINER
BEGIN
  UPDATE occupant_join_requests SET status = 'CANCELLED', cancelled_at = UTC_TIMESTAMP(6),
    cancelled_by_id = p_actor, cancellation_reason = p_reason, updated_at = UTC_TIMESTAMP(6)
  WHERE contract_id = p_contract AND status IN ('PENDING_CONSENT','PENDING_LANDLORD','APPROVED');
  UPDATE contract_change_requests SET status = 'CANCELLED', cancelled_at = UTC_TIMESTAMP(6),
    cancelled_by_id = p_actor, cancellation_reason = p_reason, updated_at = UTC_TIMESTAMP(6)
  WHERE contract_id = p_contract AND status IN ('PENDING','APPROVED_WAITING_CONFIRMATION','READY_TO_APPLY') AND (p_keep_change IS NULL OR id <> p_keep_change);
END$$

DROP TRIGGER IF EXISTS trg_contracts_before_insert$$
CREATE TRIGGER trg_contracts_before_insert BEFORE INSERT ON contracts FOR EACH ROW
BEGIN
  DECLARE v_room_status VARCHAR(40);
  SELECT status INTO v_room_status FROM rooms WHERE id = NEW.room_id FOR UPDATE;
  IF NEW.status <> 'DRAFT' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Create a DRAFT contract before adding members and a revision'; END IF;
  IF v_room_status <> 'AVAILABLE' OR EXISTS (SELECT 1 FROM room_tenants WHERE room_id = NEW.room_id AND status = 'ACTIVE') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available for a new contract';
  END IF;
  IF EXISTS (SELECT 1 FROM contracts WHERE room_id = NEW.room_id AND status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room already has an open contract';
  END IF;
  IF NEW.source = 'NEW_RENTAL' AND NOT EXISTS (
    SELECT 1 FROM room_viewing_requests WHERE id = NEW.viewing_id AND room_id = NEW.room_id
      AND tenant_id = NEW.viewing_tenant_id AND status = 'COMPLETED' AND rental_decision = 'AGREED'
  ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New rental requires a completed and agreed viewing'; END IF;
END$$

DROP TRIGGER IF EXISTS trg_contracts_before_update$$
CREATE TRIGGER trg_contracts_before_update BEFORE UPDATE ON contracts FOR EACH ROW
BEGIN
  DECLARE v_revision VARCHAR(40);
  DECLARE v_rep_at DATETIME(6);
  DECLARE v_rep_status VARCHAR(40);
  DECLARE v_rep_date DATE;
  IF NOT (NEW.room_id <=> OLD.room_id) OR NOT (NEW.house_id <=> OLD.house_id)
    OR NOT (NEW.landlord_id <=> OLD.landlord_id) OR NOT (NEW.source <=> OLD.source)
    OR NOT (NEW.viewing_id <=> OLD.viewing_id) OR NOT (NEW.viewing_tenant_id <=> OLD.viewing_tenant_id)
    OR NOT (NEW.previous_contract_id <=> OLD.previous_contract_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract origin and room are immutable; create a transfer contract';
  END IF;
  IF OLD.status IN ('TERMINATED','EXPIRED','CANCELLED') AND NEW.status <> OLD.status THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Closed contracts cannot reopen';
  END IF;
  IF NEW.initial_representative_room_tenant_id IS NULL THEN SET NEW.initial_representative_room_tenant_id = NEW.representative_room_tenant_id; END IF;
  IF OLD.initial_representative_room_tenant_id IS NOT NULL AND NOT (NEW.initial_representative_room_tenant_id <=> OLD.initial_representative_room_tenant_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Initial representative is immutable';
  END IF;
  IF NEW.source = 'NEW_RENTAL' AND NEW.status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE') AND NOT EXISTS (
    SELECT 1 FROM room_viewing_requests WHERE id = NEW.viewing_id AND status = 'COMPLETED' AND rental_decision = 'AGREED'
  ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Live rental requires an agreed viewing'; END IF;
  IF NEW.status IN ('CONFIRMED','ACTIVE') THEN
    SELECT status INTO v_revision FROM contract_revisions WHERE id = NEW.current_revision_id AND contract_id = NEW.id;
    IF v_revision IS NULL OR (v_revision <> 'CONFIRMED' AND NOT (NEW.source = 'PAPER_IMPORT' AND v_revision = 'IMPORTED')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract requires its confirmed or imported current revision';
    END IF;
  END IF;
  IF NEW.status = 'ACTIVE' THEN
    SELECT status, move_in_date, move_in_confirmed_at INTO v_rep_status, v_rep_date, v_rep_at
    FROM room_tenants WHERE id = NEW.representative_room_tenant_id AND contract_id = NEW.id;
    IF v_rep_status IS NULL OR v_rep_status <> 'ACTIVE' OR v_rep_date NOT BETWEEN NEW.start_date AND NEW.end_date
      OR v_rep_at IS NULL OR v_rep_at > UTC_TIMESTAMP(6) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active contract requires an active confirmed representative';
    END IF;
    IF OLD.status <> 'ACTIVE' AND (NEW.activated_at IS NULL OR v_rep_at > NEW.activated_at) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Activation requires representative move-in first';
    END IF;
    IF OLD.status = 'ACTIVE' AND NOT (NEW.activated_at <=> OLD.activated_at) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Do not change original activation time during handover';
    END IF;
  END IF;
  IF OLD.representative_room_tenant_id IS NOT NULL AND NOT (NEW.representative_room_tenant_id <=> OLD.representative_room_tenant_id) THEN
    IF OLD.status <> 'ACTIVE' OR NEW.status <> 'ACTIVE' OR NOT EXISTS (
      SELECT 1 FROM contract_representative_history h WHERE h.contract_id = NEW.id
        AND h.room_tenant_id = NEW.representative_room_tenant_id AND h.is_current = TRUE
        AND h.event_type = 'HANDOVER' AND h.previous_room_tenant_id = OLD.representative_room_tenant_id
    ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Representative change requires a recorded handover'; END IF;
  END IF;
  IF NEW.status IN ('TERMINATED','EXPIRED','CANCELLED') AND OLD.status NOT IN ('TERMINATED','EXPIRED','CANCELLED') THEN
    IF EXISTS (SELECT 1 FROM room_tenants WHERE contract_id = NEW.id AND status IN ('ACTIVE','PLANNED')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Close or cancel every open stay before closing the contract';
    END IF;
    IF NEW.closed_at IS NULL OR NULLIF(TRIM(NEW.closure_reason), '') IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Closing requires a timestamp and reason';
    END IF;
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_contracts_after_update_workflow$$
CREATE TRIGGER trg_contracts_after_update_workflow AFTER UPDATE ON contracts FOR EACH ROW
BEGIN
  IF OLD.representative_room_tenant_id IS NULL AND NEW.representative_room_tenant_id IS NOT NULL THEN
    INSERT INTO contract_representative_history
      (contract_id, room_tenant_id, tenant_id, name_snapshot, event_type, basis_revision_id, started_at, recorded_by_id, reason, consent_method)
    SELECT NEW.id, rt.id, rt.tenant_id, rt.full_name, 'INITIAL', NEW.current_revision_id, UTC_TIMESTAMP(6), NEW.landlord_id,
      'Initial contract representative', 'NOT_REQUIRED' FROM room_tenants rt WHERE rt.id = NEW.representative_room_tenant_id;
  END IF;
  IF NEW.status IN ('TERMINATED','EXPIRED','CANCELLED') AND OLD.status NOT IN ('TERMINATED','EXPIRED','CANCELLED') THEN
    UPDATE contract_representative_history SET is_current = FALSE, ended_at = NEW.closed_at,
      ended_by_id = NEW.landlord_id, end_reason = NEW.closure_reason WHERE contract_id = NEW.id AND is_current = TRUE;
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_rep_history_before_insert$$
CREATE TRIGGER trg_rep_history_before_insert BEFORE INSERT ON contract_representative_history FOR EACH ROW
BEGIN
  IF NEW.event_type = 'HANDOVER' THEN
    IF NOT EXISTS (SELECT 1 FROM contracts c JOIN room_tenants rt ON rt.contract_id = c.id
      JOIN users u ON u.id = rt.tenant_id
      WHERE c.id = NEW.contract_id AND c.status = 'ACTIVE' AND c.representative_room_tenant_id = NEW.previous_room_tenant_id
        AND rt.id = NEW.room_tenant_id AND rt.status = 'ACTIVE' AND u.status = 'ACTIVE') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Successor must be an active linked resident with an active account';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM contract_representative_history h WHERE h.id = NEW.previous_history_id
      AND h.contract_id = NEW.contract_id AND h.room_tenant_id = NEW.previous_room_tenant_id
      AND h.is_current = FALSE AND h.ended_at = NEW.started_at) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Handover must continue the immediately closed representative tenure';
    END IF;
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_rep_history_before_update$$
CREATE TRIGGER trg_rep_history_before_update BEFORE UPDATE ON contract_representative_history FOR EACH ROW
BEGIN
  IF OLD.is_current = FALSE OR NEW.is_current <> FALSE OR NEW.ended_at IS NULL
    OR NOT (OLD.contract_id <=> NEW.contract_id) OR NOT (OLD.room_tenant_id <=> NEW.room_tenant_id)
    OR NOT (OLD.tenant_id <=> NEW.tenant_id) OR NOT (OLD.name_snapshot <=> NEW.name_snapshot)
    OR NOT (OLD.event_type <=> NEW.event_type) OR NOT (OLD.previous_history_id <=> NEW.previous_history_id)
    OR NOT (OLD.previous_room_tenant_id <=> NEW.previous_room_tenant_id) OR NOT (OLD.basis_revision_id <=> NEW.basis_revision_id)
    OR NOT (OLD.started_at <=> NEW.started_at) OR NOT (OLD.recorded_at <=> NEW.recorded_at)
    OR NOT (OLD.recorded_by_id <=> NEW.recorded_by_id) OR NOT (OLD.reason <=> NEW.reason)
    OR NOT (OLD.consent_method <=> NEW.consent_method) OR NOT (OLD.consented_by_id <=> NEW.consented_by_id)
    OR NOT (OLD.consent_recorded_by_id <=> NEW.consent_recorded_by_id) OR NOT (OLD.consent_recorded_at <=> NEW.consent_recorded_at)
    OR NOT (OLD.consent_file_id <=> NEW.consent_file_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Representative history is immutable except for closing the current tenure';
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_rep_history_before_delete$$
CREATE TRIGGER trg_rep_history_before_delete BEFORE DELETE ON contract_representative_history FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Representative history cannot be deleted'; END$$

DROP TRIGGER IF EXISTS trg_occupants_before_insert_workflow$$
CREATE TRIGGER trg_occupants_before_insert_workflow BEFORE INSERT ON room_tenants FOR EACH ROW
BEGIN
  DECLARE v_status VARCHAR(40);
  DECLARE v_start DATE;
  DECLARE v_end DATE;
  DECLARE v_capacity INT;
  DECLARE v_load BIGINT;
  SELECT max_occupants INTO v_capacity FROM rooms WHERE id = NEW.room_id FOR UPDATE;
  SELECT status, start_date, end_date INTO v_status, v_start, v_end FROM contracts WHERE id = NEW.contract_id;
  IF NEW.status IN ('PLANNED','ACTIVE') AND v_status NOT IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot add an open stay to a closed contract';
  END IF;
  IF NEW.status = 'ACTIVE' AND (v_status NOT IN ('CONFIRMED','ACTIVE') OR NEW.move_in_date NOT BETWEEN v_start AND v_end
    OR NEW.move_in_date > DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR) OR NEW.move_in_confirmed_at > UTC_TIMESTAMP(6)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Move-in requires a live confirmed contract and a valid actual date';
  END IF;
  IF NEW.intake_source = 'APPROVED_JOIN' AND NOT EXISTS (SELECT 1 FROM occupant_join_requests j WHERE j.id = NEW.join_request_id
    AND j.contract_id = NEW.contract_id AND j.applicant_id = NEW.tenant_id AND j.status = 'APPROVED' AND j.hold_expires_at > UTC_TIMESTAMP(6)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Join stay requires an unexpired approved request';
  END IF;
  IF NEW.status IN ('PLANNED','ACTIVE') THEN
    CALL _v5_room_load(NEW.room_id, NEW.join_request_id, v_load);
    IF v_load + 1 > v_capacity THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room capacity includes planned members and held places'; END IF;
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_occupants_before_update_workflow$$
CREATE TRIGGER trg_occupants_before_update_workflow BEFORE UPDATE ON room_tenants FOR EACH ROW
BEGIN
  DECLARE v_status VARCHAR(40);
  DECLARE v_rep BIGINT;
  DECLARE v_start DATE;
  DECLARE v_end DATE;
  IF NEW.contract_id <> OLD.contract_id OR NEW.room_id <> OLD.room_id OR NOT (NEW.join_request_id <=> OLD.join_request_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Create a new stay for a different contract or room';
  END IF;
  IF NEW.status <> OLD.status AND NOT ((OLD.status = 'PLANNED' AND NEW.status IN ('ACTIVE','CANCELLED')) OR (OLD.status = 'ACTIVE' AND NEW.status = 'LEFT')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid stay status transition';
  END IF;
  SELECT status, representative_room_tenant_id, start_date, end_date INTO v_status, v_rep, v_start, v_end FROM contracts WHERE id = NEW.contract_id;
  IF OLD.status = 'PLANNED' AND NEW.status = 'ACTIVE' AND (v_status NOT IN ('CONFIRMED','ACTIVE')
    OR NEW.move_in_date NOT BETWEEN v_start AND v_end OR NEW.move_in_date > DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR)
    OR NEW.move_in_confirmed_at > UTC_TIMESTAMP(6)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot move into a closed or unconfirmed contract';
  END IF;
  IF OLD.status = 'ACTIVE' AND NEW.status = 'LEFT' AND OLD.id = v_rep AND v_status = 'ACTIVE'
    AND EXISTS (SELECT 1 FROM room_tenants WHERE contract_id = OLD.contract_id AND id <> OLD.id AND status IN ('PLANNED','ACTIVE')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Handover the representative before their departure';
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_rooms_before_update_workflow$$
CREATE TRIGGER trg_rooms_before_update_workflow BEFORE UPDATE ON rooms FOR EACH ROW
BEGIN
  DECLARE v_load BIGINT;
  IF NEW.max_occupants <> OLD.max_occupants THEN
    CALL _v5_room_load(OLD.id, NULL, v_load);
    IF NEW.max_occupants < v_load THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room capacity cannot be reduced below committed places'; END IF;
  END IF;
  IF NEW.status = 'AVAILABLE' AND (EXISTS (SELECT 1 FROM room_tenants WHERE room_id=OLD.id AND status='ACTIVE')
    OR EXISTS (SELECT 1 FROM contracts WHERE room_id=OLD.id AND status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE'))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Occupied or reserved room cannot be marked available';
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_join_before_insert_workflow$$
CREATE TRIGGER trg_join_before_insert_workflow BEFORE INSERT ON occupant_join_requests FOR EACH ROW
BEGIN
  IF NEW.status NOT IN ('PENDING_CONSENT','PENDING_LANDLORD') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A join request must start pending'; END IF;
  IF NOT EXISTS (SELECT 1 FROM contracts c JOIN room_tenants rt ON rt.id=c.representative_room_tenant_id
    WHERE c.id=NEW.contract_id AND c.status='ACTIVE' AND rt.status='ACTIVE'
      AND c.representative_room_tenant_id=NEW.representative_room_tenant_id
      AND NEW.planned_move_in_date BETWEEN c.start_date AND c.end_date) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Join request requires a live contract and its current representative';
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_join_before_update_workflow$$
CREATE TRIGGER trg_join_before_update_workflow BEFORE UPDATE ON occupant_join_requests FOR EACH ROW
BEGIN
  DECLARE v_room BIGINT;
  DECLARE v_rep BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE v_start DATE;
  DECLARE v_end DATE;
  DECLARE v_capacity INT;
  DECLARE v_load BIGINT;
  IF NEW.contract_id <> OLD.contract_id OR NEW.applicant_id <> OLD.applicant_id
    OR NEW.representative_room_tenant_id <> OLD.representative_room_tenant_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Join request identity and consent representative are immutable';
  END IF;
  IF NEW.status <> OLD.status AND NOT (
    (OLD.status = 'PENDING_CONSENT' AND NEW.status IN ('PENDING_LANDLORD','CANCELLED','EXPIRED'))
    OR (OLD.status = 'PENDING_LANDLORD' AND NEW.status IN ('APPROVED','REJECTED','CANCELLED','EXPIRED'))
    OR (OLD.status = 'APPROVED' AND NEW.status IN ('COMPLETED','CANCELLED','EXPIRED'))
  ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid join request status transition'; END IF;
  IF NEW.status IN ('APPROVED','COMPLETED') THEN
    SELECT room_id, representative_room_tenant_id, status, start_date, end_date INTO v_room, v_rep, v_status, v_start, v_end FROM contracts WHERE id = NEW.contract_id;
    SELECT max_occupants INTO v_capacity FROM rooms WHERE id = v_room FOR UPDATE;
    IF v_status <> 'ACTIVE' OR v_rep <> NEW.representative_room_tenant_id
      OR DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR) NOT BETWEEN v_start AND v_end
      OR NEW.planned_move_in_date NOT BETWEEN v_start AND v_end OR NEW.hold_expires_at <= UTC_TIMESTAMP(6) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Join requires current representative, active contract and unexpired hold';
    END IF;
    IF NEW.status = 'APPROVED' AND OLD.status <> 'APPROVED' THEN
      CALL _v5_room_load(v_room, NEW.id, v_load);
      IF v_load + 1 > v_capacity THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No unreserved room capacity remains'; END IF;
    END IF;
    IF NEW.status = 'COMPLETED' AND (NEW.planned_move_in_date > DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR) OR NOT EXISTS (
      SELECT 1 FROM room_tenants WHERE id = NEW.completed_room_tenant_id AND join_request_id = NEW.id AND status = 'ACTIVE'
    )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Join completion requires an actual linked active stay'; END IF;
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_viewings_before_insert_workflow$$
CREATE TRIGGER trg_viewings_before_insert_workflow BEFORE INSERT ON room_viewing_requests FOR EACH ROW
BEGIN
  DECLARE v_status VARCHAR(40);
  SELECT status INTO v_status FROM rooms WHERE id = NEW.room_id FOR UPDATE;
  IF NEW.status = 'SCHEDULED' THEN
    IF v_status <> 'AVAILABLE' OR NEW.starts_at <= UTC_TIMESTAMP(6) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Viewing must be in the future for an available room'; END IF;
    IF EXISTS (SELECT 1 FROM room_viewing_requests WHERE room_id = NEW.room_id AND status = 'SCHEDULED' AND starts_at < NEW.ends_at AND ends_at > NEW.starts_at) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Viewing interval overlaps an existing appointment';
    END IF;
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_viewings_before_update$$
CREATE TRIGGER trg_viewings_before_update BEFORE UPDATE ON room_viewing_requests FOR EACH ROW
BEGIN
  DECLARE v_room BIGINT;
  SELECT id INTO v_room FROM rooms WHERE id = NEW.room_id FOR UPDATE;
  IF NEW.room_id <> OLD.room_id OR NEW.tenant_id <> OLD.tenant_id OR NEW.created_by_id <> OLD.created_by_id OR NEW.conversation_id <> OLD.conversation_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Viewing participants and room are immutable';
  END IF;
  IF NEW.status <> OLD.status AND NOT (OLD.status = 'SCHEDULED' AND NEW.status IN ('COMPLETED','CANCELLED','NO_SHOW')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid viewing status transition';
  END IF;
  IF NEW.status = 'COMPLETED' AND NEW.starts_at > UTC_TIMESTAMP(6) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Attendance cannot precede the appointment'; END IF;
  IF NEW.status = 'NO_SHOW' AND NEW.ends_at > UTC_TIMESTAMP(6) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No-show can only be recorded after the appointment ends'; END IF;
  IF NEW.status = 'SCHEDULED' THEN
    IF NEW.starts_at <= UTC_TIMESTAMP(6) AND (NEW.starts_at <> OLD.starts_at OR NEW.ends_at <> OLD.ends_at) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rescheduled viewing must start in the future'; END IF;
    IF EXISTS (SELECT 1 FROM room_viewing_requests WHERE id <> NEW.id AND room_id = NEW.room_id AND status = 'SCHEDULED' AND starts_at < NEW.ends_at AND ends_at > NEW.starts_at) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Viewing interval overlaps an existing appointment';
    END IF;
  END IF;
  IF OLD.rental_decision <> NEW.rental_decision AND NOT ((OLD.rental_decision = 'WAITING' AND NEW.rental_decision IN ('AGREED','DECLINED')) OR (OLD.rental_decision = 'AGREED' AND NEW.rental_decision = 'WITHDRAWN')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid rental decision transition';
  END IF;
  IF OLD.rental_decision = 'AGREED' AND NEW.rental_decision <> 'AGREED' AND EXISTS (
    SELECT 1 FROM contracts WHERE viewing_id = OLD.id AND status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE')
  ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cancel or close the linked contract before withdrawal'; END IF;
END$$

DROP PROCEDURE IF EXISTS sp_handover_representative$$
CREATE PROCEDURE sp_handover_representative(
  IN p_contract BIGINT, IN p_departing BIGINT, IN p_successor BIGINT,
  IN p_actor BIGINT, IN p_reason VARCHAR(1000), IN p_consent_recorded BOOLEAN
)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_rep BIGINT;
  DECLARE v_revision BIGINT;
  DECLARE v_old_history BIGINT;
  DECLARE v_old_tenant BIGINT;
  DECLARE v_tenant BIGINT;
  DECLARE v_name VARCHAR(150);
  DECLARE v_status VARCHAR(40);
  DECLARE v_at DATETIME(6);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM contracts WHERE id = p_contract;
  SELECT id INTO v_room FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT landlord_id, representative_room_tenant_id, status, current_revision_id
    INTO v_owner, v_rep, v_status, v_revision FROM contracts WHERE id = p_contract FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_status <> 'ACTIVE' OR v_rep <> p_departing
    OR p_successor = p_departing OR COALESCE(p_consent_recorded, FALSE) <> TRUE OR NULLIF(TRIM(p_reason), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid actor, current representative, reason or recorded consent';
  END IF;
  SELECT tenant_id INTO v_old_tenant FROM room_tenants WHERE id = p_departing AND contract_id = p_contract AND status = 'ACTIVE' FOR UPDATE;
  SELECT rt.tenant_id, rt.full_name INTO v_tenant, v_name FROM room_tenants rt JOIN users u ON u.id = rt.tenant_id
    WHERE rt.id = p_successor AND rt.contract_id = p_contract AND rt.status = 'ACTIVE' AND u.status = 'ACTIVE' FOR UPDATE;
  IF v_tenant IS NULL OR NOT EXISTS (SELECT 1 FROM room_tenants WHERE id = p_departing AND contract_id = p_contract AND status = 'ACTIVE') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Successor must be another active resident with an active linked account';
  END IF;
  SELECT id INTO v_old_history FROM contract_representative_history WHERE contract_id = p_contract AND room_tenant_id = p_departing AND is_current = TRUE FOR UPDATE;
  IF v_old_history IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Representative history needs reconciliation before handover'; END IF;
  SET v_at = UTC_TIMESTAMP(6);
  UPDATE contract_representative_history SET is_current = FALSE, ended_at = v_at, ended_by_id = p_actor, end_reason = p_reason WHERE id = v_old_history;
  INSERT INTO contract_representative_history
    (contract_id, room_tenant_id, tenant_id, name_snapshot, event_type, previous_history_id, previous_room_tenant_id,
     basis_revision_id, started_at, recorded_by_id, recorded_at, reason, consent_method, consent_recorded_by_id, consent_recorded_at)
  VALUES (p_contract, p_successor, v_tenant, v_name, 'HANDOVER', v_old_history, p_departing,
    v_revision, v_at, p_actor, v_at, p_reason, 'LANDLORD_RECORDED', p_actor, v_at);
  UPDATE contracts SET representative_room_tenant_id = p_successor, updated_at = v_at WHERE id = p_contract;
  UPDATE room_tenants SET status = 'LEFT', move_out_date = DATE(v_at + INTERVAL 7 HOUR),
    move_out_confirmed_by_id = p_actor, move_out_confirmed_at = v_at, updated_at = v_at WHERE id = p_departing;
  CALL _v5_cancel_requests(p_contract, p_actor, 'Representative changed; request new consent from the current representative', NULL);
  INSERT INTO notifications (user_id, type, title, content, resource_type, resource_id, event_key)
  SELECT u.id, 'REPRESENTATIVE_CHANGED', 'Contract representative changed', CONCAT(v_name, ' is now the representative. ', p_reason),
    'CONTRACT', p_contract, CONCAT('representative-history:', h.id)
  FROM contract_representative_history h JOIN users u ON u.id IN (v_old_tenant, v_tenant)
  WHERE h.contract_id = p_contract AND h.is_current = TRUE;
  CALL _v5_sync_room(v_room);
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_approve_occupant_join$$
CREATE PROCEDURE sp_approve_occupant_join(IN p_request BIGINT, IN p_actor BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_contract BIGINT;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE v_applicant BIGINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT j.contract_id, c.room_id INTO v_contract, v_room FROM occupant_join_requests j JOIN contracts c ON c.id = j.contract_id WHERE j.id = p_request;
  SELECT id INTO v_room FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT landlord_id INTO v_owner FROM contracts WHERE id = v_contract FOR UPDATE;
  SELECT status, applicant_id INTO v_status, v_applicant FROM occupant_join_requests WHERE id = p_request FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_status <> 'PENDING_LANDLORD' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only the owner may approve a pending join request'; END IF;
  IF EXISTS (SELECT 1 FROM room_tenants WHERE tenant_id = v_applicant AND (status = 'ACTIVE' OR (contract_id = v_contract AND status = 'PLANNED'))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Applicant already has an open stay';
  END IF;
  UPDATE occupant_join_requests SET status = 'EXPIRED', updated_at = UTC_TIMESTAMP(6)
    WHERE contract_id = v_contract AND status = 'APPROVED' AND hold_expires_at <= UTC_TIMESTAMP(6);
  UPDATE occupant_join_requests SET status = 'APPROVED', reviewed_by_id = p_actor, reviewed_at = UTC_TIMESTAMP(6),
    hold_expires_at = UTC_TIMESTAMP(6) + INTERVAL 48 HOUR, updated_at = UTC_TIMESTAMP(6) WHERE id = p_request;
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_complete_occupant_join$$
CREATE PROCEDURE sp_complete_occupant_join(IN p_request BIGINT, IN p_actor BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_contract BIGINT;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_applicant BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE v_contract_status VARCHAR(40);
  DECLARE v_hold DATETIME(6);
  DECLARE v_date DATE;
  DECLARE v_member BIGINT;
  DECLARE v_today DATE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SET v_today = DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR);
  SELECT j.contract_id, c.room_id INTO v_contract, v_room FROM occupant_join_requests j JOIN contracts c ON c.id = j.contract_id WHERE j.id = p_request;
  SELECT id INTO v_room FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT landlord_id, status INTO v_owner, v_contract_status FROM contracts WHERE id = v_contract FOR UPDATE;
  SELECT status, applicant_id, hold_expires_at, planned_move_in_date INTO v_status, v_applicant, v_hold, v_date FROM occupant_join_requests WHERE id = p_request FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_contract_status <> 'ACTIVE' OR v_status <> 'APPROVED'
    OR v_hold <= UTC_TIMESTAMP(6) OR v_date > v_today THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Join is not currently eligible for actual move-in'; END IF;
  IF EXISTS (SELECT 1 FROM room_tenants WHERE tenant_id = v_applicant AND status = 'ACTIVE') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Applicant is already residing elsewhere'; END IF;
  INSERT INTO room_tenants (contract_id, room_id, tenant_id, full_name, status, intake_source, join_request_id,
    planned_move_in_date, move_in_date, move_in_confirmed_by_id, move_in_confirmed_at)
  SELECT v_contract, v_room, u.id, u.full_name, 'ACTIVE', 'APPROVED_JOIN', p_request,
    v_date, v_today, p_actor, UTC_TIMESTAMP(6) FROM users u WHERE u.id = v_applicant AND u.status = 'ACTIVE';
  IF ROW_COUNT() <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Applicant account is not active'; END IF;
  SET v_member = LAST_INSERT_ID();
  UPDATE occupant_join_requests SET status = 'COMPLETED', completed_room_tenant_id = v_member,
    completed_at = UTC_TIMESTAMP(6), updated_at = UTC_TIMESTAMP(6) WHERE id = p_request;
  CALL _v5_sync_room(v_room);
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_confirm_move_in$$
CREATE PROCEDURE sp_confirm_move_in(IN p_contract BIGINT, IN p_members JSON, IN p_date DATE, IN p_actor BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_rep BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE v_start DATE;
  DECLARE v_end DATE;
  DECLARE v_count INT;
  DECLARE v_distinct INT;
  DECLARE v_valid INT;
  DECLARE v_capacity INT;
  DECLARE v_load BIGINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM contracts WHERE id = p_contract;
  SELECT max_occupants INTO v_capacity FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT landlord_id, representative_room_tenant_id, status, start_date, end_date INTO v_owner, v_rep, v_status, v_start, v_end FROM contracts WHERE id = p_contract FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_status NOT IN ('CONFIRMED','ACTIVE') OR p_date IS NULL
    OR p_date NOT BETWEEN v_start AND v_end OR p_date > DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR)
    OR p_members IS NULL OR JSON_TYPE(p_members) <> 'ARRAY' OR JSON_LENGTH(p_members) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Move-in requires selected planned members and a valid actual date';
  END IF;
  SELECT COUNT(*), COUNT(DISTINCT ids.id), COUNT(rt.id) INTO v_count, v_distinct, v_valid
    FROM JSON_TABLE(p_members, '$[*]' COLUMNS(id BIGINT PATH '$' ERROR ON ERROR)) ids
    LEFT JOIN room_tenants rt ON rt.id = ids.id AND rt.contract_id = p_contract AND rt.status = 'PLANNED';
  IF v_count <> v_distinct OR v_count <> v_valid THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Every selected member must be a distinct planned stay in this contract'; END IF;
  IF v_status = 'CONFIRMED' AND NOT JSON_CONTAINS(p_members, CAST(v_rep AS JSON)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Select the representative when activating the contract'; END IF;
  CALL _v5_room_load(v_room, NULL, v_load);
  IF v_load > v_capacity THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Committed room capacity is exceeded'; END IF;
  UPDATE room_tenants rt JOIN JSON_TABLE(p_members, '$[*]' COLUMNS(id BIGINT PATH '$')) ids ON ids.id = rt.id
    SET rt.status = 'ACTIVE', rt.move_in_date = p_date, rt.move_in_confirmed_by_id = p_actor,
      rt.move_in_confirmed_at = UTC_TIMESTAMP(6), rt.updated_at = UTC_TIMESTAMP(6) WHERE rt.contract_id = p_contract;
  UPDATE contracts SET status = 'ACTIVE', activated_at = COALESCE(activated_at, UTC_TIMESTAMP(6)), updated_at = UTC_TIMESTAMP(6) WHERE id = p_contract;
  CALL _v5_sync_room(v_room);
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS _v5_close_stays$$
CREATE PROCEDURE _v5_close_stays(IN p_contract BIGINT, IN p_date DATE, IN p_actor BIGINT, IN p_reason VARCHAR(1000), IN p_keep_change BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_rep BIGINT;
  SELECT representative_room_tenant_id INTO v_rep FROM contracts WHERE id = p_contract;
  IF p_date IS NULL OR p_date > DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR)
    OR EXISTS (SELECT 1 FROM room_tenants WHERE contract_id = p_contract AND status = 'ACTIVE' AND move_in_date > p_date) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Departure date cannot precede move-in or be in the future';
  END IF;
  UPDATE room_tenants SET status = 'CANCELLED', cancellation_reason = p_reason, updated_at = UTC_TIMESTAMP(6)
    WHERE contract_id = p_contract AND status = 'PLANNED';
  UPDATE room_tenants SET status = 'LEFT', move_out_date = p_date, move_out_confirmed_by_id = p_actor,
    move_out_confirmed_at = UTC_TIMESTAMP(6), updated_at = UTC_TIMESTAMP(6)
    WHERE contract_id = p_contract AND status = 'ACTIVE' AND id <> v_rep;
  UPDATE room_tenants SET status = 'LEFT', move_out_date = p_date, move_out_confirmed_by_id = p_actor,
    move_out_confirmed_at = UTC_TIMESTAMP(6), updated_at = UTC_TIMESTAMP(6)
    WHERE contract_id = p_contract AND status = 'ACTIVE' AND id = v_rep;
  CALL _v5_cancel_requests(p_contract, p_actor, p_reason, p_keep_change);
END$$

DROP PROCEDURE IF EXISTS sp_move_out$$
CREATE PROCEDURE sp_move_out(IN p_contract BIGINT, IN p_member BIGINT, IN p_date DATE, IN p_actor BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE v_rep BIGINT;
  DECLARE v_move_in DATE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM contracts WHERE id = p_contract;
  SELECT id INTO v_room FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT landlord_id, status, representative_room_tenant_id INTO v_owner, v_status, v_rep FROM contracts WHERE id = p_contract FOR UPDATE;
  SELECT move_in_date INTO v_move_in FROM room_tenants WHERE id = p_member AND contract_id = p_contract AND status = 'ACTIVE' FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_move_in IS NULL OR p_date IS NULL OR p_date < v_move_in OR p_date > DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid owner or actual departure date'; END IF;
  IF p_member = v_rep AND EXISTS (SELECT 1 FROM room_tenants WHERE contract_id = p_contract AND id <> p_member AND status IN ('ACTIVE','PLANNED')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Choose and confirm a successor before representative departure'; END IF;
  UPDATE room_tenants SET status = 'LEFT', move_out_date = p_date, move_out_confirmed_by_id = p_actor,
    move_out_confirmed_at = UTC_TIMESTAMP(6), updated_at = UTC_TIMESTAMP(6) WHERE id = p_member;
  IF NOT EXISTS (SELECT 1 FROM room_tenants WHERE contract_id = p_contract AND status IN ('ACTIVE','PLANNED')) AND v_status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE') THEN
    CALL _v5_cancel_requests(p_contract, p_actor, 'Last resident left the room', NULL);
    UPDATE contracts SET status = 'TERMINATED', closed_at = UTC_TIMESTAMP(6), closure_reason = 'Last resident left the room', updated_at = UTC_TIMESTAMP(6) WHERE id = p_contract;
  END IF;
  CALL _v5_sync_room(v_room);
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_cancel_contract$$
CREATE PROCEDURE sp_cancel_contract(IN p_contract BIGINT, IN p_actor BIGINT, IN p_reason VARCHAR(1000))
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM contracts WHERE id = p_contract;
  SELECT id INTO v_room FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT landlord_id, status INTO v_owner, v_status FROM contracts WHERE id = p_contract FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_status NOT IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED')
    OR NULLIF(TRIM(p_reason), '') IS NULL OR EXISTS (SELECT 1 FROM room_tenants WHERE contract_id = p_contract AND status = 'ACTIVE') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only an unoccupied unactivated contract can be cancelled';
  END IF;
  CALL _v5_close_stays(p_contract, DATE(UTC_TIMESTAMP() + INTERVAL 7 HOUR), p_actor, p_reason, NULL);
  UPDATE contracts SET status = 'CANCELLED', closed_at = UTC_TIMESTAMP(6), closure_reason = p_reason, updated_at = UTC_TIMESTAMP(6) WHERE id = p_contract;
  CALL _v5_sync_room(v_room);
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_set_room_capacity$$
CREATE PROCEDURE sp_set_room_capacity(IN p_room BIGINT, IN p_capacity INT, IN p_actor BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_owner BIGINT;
  DECLARE v_load BIGINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT h.landlord_id INTO v_owner FROM rooms r JOIN rental_houses h ON h.id = r.house_id WHERE r.id = p_room FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR p_capacity IS NULL OR p_capacity <= 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid room owner or capacity'; END IF;
  CALL _v5_room_load(p_room, NULL, v_load);
  IF p_capacity < v_load THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacity cannot be less than active, planned and held places'; END IF;
  UPDATE rooms SET max_occupants = p_capacity, updated_at = UTC_TIMESTAMP(6) WHERE id = p_room;
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_schedule_viewing$$
CREATE PROCEDURE sp_schedule_viewing(IN p_conversation BIGINT, IN p_room BIGINT, IN p_tenant BIGINT, IN p_actor BIGINT, IN p_starts_at_utc DATETIME(6), IN p_duration_minutes INT, IN p_notes VARCHAR(2000), OUT p_viewing BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_house BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT r.house_id, h.landlord_id, r.status INTO v_house, v_owner, v_status FROM rooms r JOIN rental_houses h ON h.id = r.house_id WHERE r.id = p_room FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_status <> 'AVAILABLE' OR p_starts_at_utc IS NULL OR p_starts_at_utc <= UTC_TIMESTAMP(6)
    OR p_duration_minutes IS NULL OR p_duration_minutes NOT IN (30,60,90,120) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid owner, available room or future UTC viewing interval'; END IF;
  IF EXISTS (SELECT 1 FROM contracts WHERE room_id = p_room AND status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE'))
    OR EXISTS (SELECT 1 FROM room_tenants WHERE room_id = p_room AND status = 'ACTIVE') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is already occupied or reserved'; END IF;
  INSERT INTO room_viewing_requests(room_id, house_id, conversation_id, tenant_id, created_by_id, starts_at, ends_at, notes)
    VALUES(p_room, v_house, p_conversation, p_tenant, p_actor, p_starts_at_utc, p_starts_at_utc + INTERVAL p_duration_minutes MINUTE, p_notes);
  SET p_viewing = LAST_INSERT_ID();
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_set_viewing_outcome$$
CREATE PROCEDURE sp_set_viewing_outcome(IN p_viewing BIGINT, IN p_actor BIGINT, IN p_action VARCHAR(40), IN p_reason VARCHAR(1000))
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_tenant BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE v_decision VARCHAR(40);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM room_viewing_requests WHERE id = p_viewing;
  SELECT id INTO v_room FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT created_by_id, tenant_id, status, rental_decision INTO v_owner, v_tenant, v_status, v_decision FROM room_viewing_requests WHERE id = p_viewing FOR UPDATE;
  IF v_owner IS NULL OR p_actor IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown viewing or actor'; END IF;
  IF p_action IN ('ATTENDED','NO_SHOW') THEN
    IF p_actor <> v_owner OR v_status <> 'SCHEDULED' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only the owner may record viewing attendance'; END IF;
    IF p_action = 'ATTENDED' THEN
      UPDATE room_viewing_requests SET status = 'COMPLETED', attendance_confirmed_by_id = p_actor, attendance_confirmed_at = UTC_TIMESTAMP(6), updated_at = UTC_TIMESTAMP(6) WHERE id = p_viewing;
    ELSE UPDATE room_viewing_requests SET status = 'NO_SHOW', updated_at = UTC_TIMESTAMP(6) WHERE id = p_viewing; END IF;
  ELSEIF p_action = 'CANCEL' THEN
    IF p_actor NOT IN (v_owner,v_tenant) OR v_status <> 'SCHEDULED' OR NULLIF(TRIM(p_reason),'') IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cancellation requires a participant and a reason'; END IF;
    UPDATE room_viewing_requests SET status = 'CANCELLED', cancelled_at = UTC_TIMESTAMP(6), cancelled_by_id = p_actor, cancellation_reason = p_reason, updated_at = UTC_TIMESTAMP(6) WHERE id = p_viewing;
  ELSEIF p_action IN ('AGREE','DECLINE') THEN
    IF p_actor <> v_tenant OR v_status <> 'COMPLETED' OR v_decision <> 'WAITING' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only the viewing tenant may decide once after attendance'; END IF;
    UPDATE room_viewing_requests SET rental_decision = IF(p_action = 'AGREE','AGREED','DECLINED'),
      rental_decided_by_id = p_actor, rental_decided_at = UTC_TIMESTAMP(6), updated_at = UTC_TIMESTAMP(6) WHERE id = p_viewing;
  ELSEIF p_action = 'WITHDRAW' THEN
    IF p_actor <> v_tenant OR v_decision <> 'AGREED' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only an agreed viewing tenant may withdraw'; END IF;
    UPDATE room_viewing_requests SET rental_decision = 'WITHDRAWN', rental_withdrawn_at = UTC_TIMESTAMP(6), updated_at = UTC_TIMESTAMP(6) WHERE id = p_viewing;
  ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown viewing action'; END IF;
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_create_rental_contract$$
CREATE PROCEDURE sp_create_rental_contract(IN p_viewing BIGINT, IN p_actor BIGINT, IN p_number VARCHAR(100), IN p_start DATE, IN p_end DATE, IN p_rent DECIMAL(15,2), IN p_deposit DECIMAL(15,2), IN p_content LONGTEXT, IN p_template BIGINT, IN p_extra_members JSON, OUT p_contract BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_house BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_tenant BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE v_decision VARCHAR(40);
  DECLARE v_capacity INT;
  DECLARE v_rep BIGINT;
  DECLARE v_revision BIGINT;
  DECLARE v_snapshot JSON;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM room_viewing_requests WHERE id = p_viewing;
  SELECT house_id, max_occupants INTO v_house, v_capacity FROM rooms WHERE id = v_room FOR UPDATE;
  SELECT created_by_id, tenant_id, status, rental_decision INTO v_owner, v_tenant, v_status, v_decision FROM room_viewing_requests WHERE id = p_viewing FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR v_status <> 'COMPLETED' OR v_decision <> 'AGREED'
    OR p_start IS NULL OR p_end IS NULL OR p_end < p_start OR p_rent IS NULL OR p_rent < 0 OR p_deposit IS NULL OR p_deposit < 0
    OR NULLIF(TRIM(p_number),'') IS NULL OR NULLIF(TRIM(p_content),'') IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid completed viewing, owner or contract terms'; END IF;
  SET p_extra_members = COALESCE(p_extra_members, JSON_ARRAY());
  IF JSON_TYPE(p_extra_members) <> 'ARRAY' OR JSON_LENGTH(p_extra_members) + 1 > v_capacity THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Initial members exceed room capacity'; END IF;
  IF EXISTS (SELECT 1 FROM JSON_TABLE(p_extra_members, '$[*]' COLUMNS(full_name VARCHAR(150) PATH '$.full_name' NULL ON EMPTY)) x WHERE NULLIF(TRIM(x.full_name),'') IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Each initial member needs a name'; END IF;
  INSERT INTO contracts(contract_number,room_id,house_id,landlord_id,viewing_id,viewing_tenant_id,source,status,start_date,end_date,rent_amount,deposit_amount)
    VALUES(p_number,v_room,v_house,p_actor,p_viewing,v_tenant,'NEW_RENTAL','DRAFT',p_start,p_end,p_rent,p_deposit);
  SET p_contract = LAST_INSERT_ID();
  INSERT INTO room_tenants(contract_id,room_id,tenant_id,full_name,status,intake_source,planned_move_in_date)
    SELECT p_contract,v_room,u.id,u.full_name,'PLANNED','INITIAL_CONTRACT',p_start FROM users u WHERE u.id=v_tenant AND u.status='ACTIVE';
  IF ROW_COUNT() <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Representative account is not active'; END IF;
  SET v_rep = LAST_INSERT_ID();
  INSERT INTO room_tenants(contract_id,room_id,tenant_id,full_name,identity_number,date_of_birth,status,intake_source,planned_move_in_date)
    SELECT p_contract,v_room,x.tenant_id,TRIM(x.full_name),x.identity_number,x.date_of_birth,'PLANNED','INITIAL_CONTRACT',p_start
    FROM JSON_TABLE(p_extra_members,'$[*]' COLUMNS(
      tenant_id BIGINT PATH '$.tenant_id' NULL ON EMPTY,
      full_name VARCHAR(150) PATH '$.full_name' ERROR ON EMPTY,
      identity_number VARCHAR(30) PATH '$.identity_number' NULL ON EMPTY,
      date_of_birth DATE PATH '$.date_of_birth' NULL ON EMPTY
    )) x;
  SELECT JSON_ARRAYAGG(JSON_OBJECT('room_tenant_id',id,'tenant_id',tenant_id,'full_name',full_name,'identity_number',identity_number)) INTO v_snapshot FROM room_tenants WHERE contract_id=p_contract;
  INSERT INTO contract_revisions(contract_id,revision_number,template_id,created_by_id,kind,status,start_date,end_date,effective_from,rent_amount,deposit_amount,content,members_snapshot,representative_room_tenant_id,landlord_confirmed_by_id,landlord_confirmed_at,sent_at)
    VALUES(p_contract,1,p_template,p_actor,'INITIAL','PENDING_CONFIRMATION',p_start,p_end,p_start,p_rent,p_deposit,p_content,v_snapshot,v_rep,p_actor,UTC_TIMESTAMP(6),UTC_TIMESTAMP(6));
  SET v_revision = LAST_INSERT_ID();
  UPDATE contracts SET representative_room_tenant_id=v_rep,current_revision_id=v_revision,status='PENDING_CONFIRMATION',updated_at=UTC_TIMESTAMP(6) WHERE id=p_contract;
  INSERT INTO notifications(user_id,type,title,content,resource_type,resource_id,event_key)
    VALUES(v_tenant,'CONTRACT_SENT','Contract confirmation requested',p_number,'CONTRACT',p_contract,CONCAT('contract-sent:',v_revision));
  CALL _v5_sync_room(v_room);
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_confirm_contract$$
CREATE PROCEDURE sp_confirm_contract(IN p_contract BIGINT, IN p_tenant BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_revision BIGINT;
  DECLARE v_rep BIGINT;
  DECLARE v_tenant BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM contracts WHERE id=p_contract;
  SELECT id INTO v_room FROM rooms WHERE id=v_room FOR UPDATE;
  SELECT current_revision_id,representative_room_tenant_id,status INTO v_revision,v_rep,v_status FROM contracts WHERE id=p_contract FOR UPDATE;
  SELECT tenant_id INTO v_tenant FROM room_tenants WHERE id=v_rep;
  IF v_tenant IS NULL OR NOT (v_tenant <=> p_tenant) OR v_status <> 'PENDING_CONFIRMATION' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only the current representative may confirm the pending contract'; END IF;
  UPDATE contract_revisions SET status='CONFIRMED',tenant_confirmed_by_id=p_tenant,tenant_confirmed_at=UTC_TIMESTAMP(6),applied_at=UTC_TIMESTAMP(6),updated_at=UTC_TIMESTAMP(6)
    WHERE id=v_revision AND contract_id=p_contract AND status='PENDING_CONFIRMATION';
  IF ROW_COUNT() <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Current revision is not pending confirmation'; END IF;
  UPDATE contracts SET status='CONFIRMED',updated_at=UTC_TIMESTAMP(6) WHERE id=p_contract;
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_cancel_planned_member$$
CREATE PROCEDURE sp_cancel_planned_member(IN p_contract BIGINT, IN p_member BIGINT, IN p_actor BIGINT, IN p_reason VARCHAR(1000))
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_rep BIGINT;
  DECLARE v_status VARCHAR(40);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT room_id INTO v_room FROM contracts WHERE id=p_contract;
  SELECT id INTO v_room FROM rooms WHERE id=v_room FOR UPDATE;
  SELECT landlord_id,representative_room_tenant_id,status INTO v_owner,v_rep,v_status FROM contracts WHERE id=p_contract FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR p_member=v_rep OR v_status NOT IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE') OR NULLIF(TRIM(p_reason),'') IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot cancel this planned member separately'; END IF;
  UPDATE room_tenants SET status='CANCELLED',cancellation_reason=p_reason,updated_at=UTC_TIMESTAMP(6) WHERE id=p_member AND contract_id=p_contract AND status='PLANNED';
  IF ROW_COUNT() <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member is not a planned stay in this contract'; END IF;
  CALL _v5_sync_room(v_room);
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_cancel_join_hold$$
CREATE PROCEDURE sp_cancel_join_hold(IN p_request BIGINT, IN p_actor BIGINT, IN p_reason VARCHAR(1000))
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_room BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_contract BIGINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SELECT j.contract_id,c.room_id INTO v_contract,v_room FROM occupant_join_requests j JOIN contracts c ON c.id=j.contract_id WHERE j.id=p_request;
  SELECT id INTO v_room FROM rooms WHERE id=v_room FOR UPDATE;
  SELECT landlord_id INTO v_owner FROM contracts WHERE id=v_contract FOR UPDATE;
  IF v_owner IS NULL OR NOT (v_owner <=> p_actor) OR NULLIF(TRIM(p_reason),'') IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cancelling a hold requires the owner and a reason'; END IF;
  UPDATE occupant_join_requests SET status='CANCELLED',cancelled_at=UTC_TIMESTAMP(6),cancelled_by_id=p_actor,cancellation_reason=p_reason,updated_at=UTC_TIMESTAMP(6)
    WHERE id=p_request AND status='APPROVED';
  IF ROW_COUNT() <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Request is not an approved hold'; END IF;
  COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_apply_contract_change$$
CREATE PROCEDURE sp_apply_contract_change(IN p_request BIGINT, IN p_actor BIGINT, OUT p_result_contract BIGINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_started BOOLEAN DEFAULT FALSE;
  DECLARE v_contract BIGINT;
  DECLARE v_room BIGINT;
  DECLARE v_target BIGINT;
  DECLARE v_lock BIGINT;
  DECLARE v_owner BIGINT;
  DECLARE v_rep BIGINT;
  DECLARE v_rep_tenant BIGINT;
  DECLARE v_revision BIGINT;
  DECLARE v_base BIGINT;
  DECLARE v_proposed BIGINT;
  DECLARE v_kind VARCHAR(40);
  DECLARE v_request_status VARCHAR(40);
  DECLARE v_contract_status VARCHAR(40);
  DECLARE v_effective DATE;
  DECLARE v_start DATE;
  DECLARE v_end DATE;
  DECLARE v_rent DECIMAL(15,2);
  DECLARE v_deposit DECIMAL(15,2);
  DECLARE v_content LONGTEXT;
  DECLARE v_proposal JSON;
  DECLARE v_snapshot JSON;
  DECLARE v_house BIGINT;
  DECLARE v_capacity INT;
  DECLARE v_count INT;
  DECLARE v_next_rep BIGINT;
  DECLARE v_next_revision BIGINT;
  DECLARE v_confirmation BIGINT;
  DECLARE v_target_owner BIGINT;
  DECLARE v_target_status VARCHAR(40);
  DECLARE v_target_price DECIMAL(15,2);
  DECLARE v_target_deposit DECIMAL(15,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN IF v_started THEN ROLLBACK; END IF; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION; SET v_started = TRUE;
  SET p_result_contract = NULL;
  SELECT x.contract_id,c.room_id,x.target_room_id INTO v_contract,v_room,v_target FROM contract_change_requests x JOIN contracts c ON c.id=x.contract_id WHERE x.id=p_request;
  IF v_room IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Unknown contract change'; END IF;
  SELECT id INTO v_lock FROM rooms WHERE id=LEAST(v_room,COALESCE(v_target,v_room)) FOR UPDATE;
  IF v_target IS NOT NULL AND v_target<>v_room THEN SELECT id INTO v_lock FROM rooms WHERE id=GREATEST(v_room,v_target) FOR UPDATE; END IF;
  SELECT landlord_id,representative_room_tenant_id,current_revision_id,status,start_date INTO v_owner,v_rep,v_revision,v_contract_status,v_start FROM contracts WHERE id=v_contract FOR UPDATE;
  SELECT type,status,requested_effective_date,base_revision_id,proposed_revision_id,proposal_snapshot,tenant_confirmed_by_id
    INTO v_kind,v_request_status,v_effective,v_base,v_proposed,v_proposal,v_confirmation FROM contract_change_requests WHERE id=p_request FOR UPDATE;
  SELECT tenant_id INTO v_rep_tenant FROM room_tenants WHERE id=v_rep AND status='ACTIVE';
  IF NOT (v_owner <=> p_actor) OR v_contract_status<>'ACTIVE' OR v_request_status<>'READY_TO_APPLY'
    OR v_base<>v_revision OR NOT (v_confirmation <=> v_rep_tenant) OR v_rep_tenant IS NULL
    OR v_effective>DATE(UTC_TIMESTAMP()+INTERVAL 7 HOUR) OR v_effective<v_start THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Change requires the owner, active contract, current revision and current representative confirmation';
  END IF;
  IF v_kind='RENEWAL' THEN
    SELECT end_date,rent_amount,deposit_amount INTO v_end,v_rent,v_deposit FROM contract_revisions
      WHERE id=v_proposed AND contract_id=v_contract AND kind='RENEWAL' AND status='CONFIRMED'
        AND representative_room_tenant_id=v_rep AND effective_from=v_effective;
    IF v_end IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Renewal requires its confirmed proposed revision'; END IF;
    UPDATE contract_revisions SET status='SUPERSEDED',updated_at=UTC_TIMESTAMP(6) WHERE id=v_revision;
    UPDATE contracts SET end_date=v_end,rent_amount=v_rent,deposit_amount=v_deposit,current_revision_id=v_proposed,updated_at=UTC_TIMESTAMP(6) WHERE id=v_contract;
    UPDATE contract_revisions SET applied_at=UTC_TIMESTAMP(6),updated_at=UTC_TIMESTAMP(6) WHERE id=v_proposed;
  ELSEIF v_kind='TERMINATION' THEN
    CALL _v5_close_stays(v_contract,v_effective,p_actor,'Contract terminated by confirmed request',p_request);
    UPDATE contracts SET status='TERMINATED',closed_at=UTC_TIMESTAMP(6),closure_reason='Contract terminated by confirmed request',updated_at=UTC_TIMESTAMP(6) WHERE id=v_contract;
    CALL _v5_sync_room(v_room);
  ELSEIF v_kind='TRANSFER' THEN
    SELECT r.house_id,h.landlord_id,r.status,r.max_occupants,r.rent_price,r.deposit_amount INTO v_house,v_target_owner,v_target_status,v_capacity,v_target_price,v_target_deposit
      FROM rooms r JOIN rental_houses h ON h.id=r.house_id WHERE r.id=v_target;
    SELECT COUNT(*) INTO v_count FROM room_tenants WHERE contract_id=v_contract AND status IN ('ACTIVE','PLANNED');
    IF v_target IS NULL OR v_target=v_room OR NOT (v_target_owner <=> p_actor) OR v_target_status<>'AVAILABLE' OR v_count>v_capacity
      OR EXISTS(SELECT 1 FROM room_tenants WHERE room_id=v_target AND status='ACTIVE')
      OR EXISTS(SELECT 1 FROM contracts WHERE room_id=v_target AND status IN ('DRAFT','PENDING_CONFIRMATION','CONFIRMED','ACTIVE')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Transfer target must be an available room of the same owner with enough capacity';
    END IF;
    SET v_content=JSON_UNQUOTE(JSON_EXTRACT(v_proposal,'$.content'));
    SET v_end=CAST(JSON_UNQUOTE(JSON_EXTRACT(v_proposal,'$.end_date')) AS DATE);
    SET v_rent=COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(v_proposal,'$.rent_amount')) AS DECIMAL(15,2)),v_target_price);
    SET v_deposit=COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(v_proposal,'$.deposit_amount')) AS DECIMAL(15,2)),v_target_deposit);
    IF NULLIF(TRIM(v_content),'') IS NULL OR v_end IS NULL OR v_end<v_effective OR v_rent<0 OR v_deposit<0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Confirmed transfer proposal needs target content and a valid end date';
    END IF;
    INSERT INTO contracts(contract_number,room_id,house_id,landlord_id,previous_contract_id,source,status,start_date,end_date,rent_amount,deposit_amount)
      VALUES(CONCAT('TRANSFER-',p_request),v_target,v_house,p_actor,v_contract,'TRANSFER','DRAFT',v_effective,v_end,v_rent,v_deposit);
    SET p_result_contract=LAST_INSERT_ID();
    INSERT INTO room_tenants(contract_id,room_id,tenant_id,full_name,phone_number,identity_number,date_of_birth,gender,permanent_address,status,intake_source,planned_move_in_date)
      SELECT p_result_contract,v_target,tenant_id,full_name,phone_number,identity_number,date_of_birth,gender,permanent_address,'PLANNED','TRANSFER',v_effective
      FROM room_tenants WHERE contract_id=v_contract AND status IN ('ACTIVE','PLANNED');
    SELECT id INTO v_next_rep FROM room_tenants WHERE contract_id=p_result_contract AND tenant_id=v_rep_tenant;
    SELECT JSON_ARRAYAGG(JSON_OBJECT('room_tenant_id',id,'tenant_id',tenant_id,'full_name',full_name)) INTO v_snapshot FROM room_tenants WHERE contract_id=p_result_contract;
    INSERT INTO contract_revisions(contract_id,revision_number,created_by_id,kind,status,start_date,end_date,effective_from,rent_amount,deposit_amount,content,members_snapshot,representative_room_tenant_id,landlord_confirmed_by_id,landlord_confirmed_at,tenant_confirmed_by_id,tenant_confirmed_at,applied_at)
      SELECT p_result_contract,1,p_actor,'TRANSFER','CONFIRMED',v_effective,v_end,v_effective,v_rent,v_deposit,v_content,v_snapshot,v_next_rep,p_actor,x.reviewed_at,v_confirmation,x.tenant_confirmed_at,UTC_TIMESTAMP(6)
      FROM contract_change_requests x WHERE x.id=p_request;
    SET v_next_revision=LAST_INSERT_ID();
    UPDATE contracts SET representative_room_tenant_id=v_next_rep,current_revision_id=v_next_revision,status='CONFIRMED',updated_at=UTC_TIMESTAMP(6) WHERE id=p_result_contract;
    CALL _v5_close_stays(v_contract,v_effective,p_actor,'Transferred to another contract',p_request);
    UPDATE contracts SET status='TERMINATED',closed_at=UTC_TIMESTAMP(6),closure_reason='Transferred to another contract',updated_at=UTC_TIMESTAMP(6) WHERE id=v_contract;
    CALL _v5_sync_room(v_room); CALL _v5_sync_room(v_target);
  ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Unknown contract change type'; END IF;
  UPDATE contract_change_requests SET status='COMPLETED',result_contract_id=p_result_contract,applied_by_id=p_actor,applied_at=UTC_TIMESTAMP(6),updated_at=UTC_TIMESTAMP(6) WHERE id=p_request;
  COMMIT;
END$$

DELIMITER ;
-- END V5 WORKFLOW OBJECTS 20261024
