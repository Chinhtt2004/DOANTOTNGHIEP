package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps occupant_join_requests. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "occupant_join_requests")
public class OccupantJoinRequest implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`contract_id`", nullable = false)
    private Long contractId;
    @Column(name = "`applicant_id`", nullable = false)
    private Long applicantId;
    @Column(name = "`requested_by_id`", nullable = false)
    private Long requestedById;
    @Column(name = "`representative_room_tenant_id`", nullable = false)
    private Long representativeRoomTenantId;
    @Column(name = "`planned_move_in_date`", nullable = false)
    private LocalDate plannedMoveInDate;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PENDING_CONSENT";
    @Column(name = "`representative_consented_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime representativeConsentedAt;
    @Column(name = "`applicant_consented_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime applicantConsentedAt;
    @Column(name = "`reviewed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime reviewedAt;
    @Column(name = "`hold_expires_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime holdExpiresAt;
    @Column(name = "`completed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime completedAt;
    @Column(name = "`cancelled_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime cancelledAt;
    @Column(name = "`reviewed_by_id`", nullable = true)
    private Long reviewedById;
    @Column(name = "`rejection_reason`", nullable = true, length = 1000)
    private String rejectionReason;
    @Column(name = "`completed_room_tenant_id`", nullable = true)
    private Long completedRoomTenantId;
    @Column(name = "`message`", nullable = true, length = 2000)
    private String message;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`open_applicant_id`", nullable = true, insertable = false, updatable = false)
    private Long openApplicantId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Long getApplicantId() { return applicantId; }
    public void setApplicantId(Long applicantId) { this.applicantId = applicantId; }
    public Long getRequestedById() { return requestedById; }
    public void setRequestedById(Long requestedById) { this.requestedById = requestedById; }
    public Long getRepresentativeRoomTenantId() { return representativeRoomTenantId; }
    public void setRepresentativeRoomTenantId(Long representativeRoomTenantId) { this.representativeRoomTenantId = representativeRoomTenantId; }
    public LocalDate getPlannedMoveInDate() { return plannedMoveInDate; }
    public void setPlannedMoveInDate(LocalDate plannedMoveInDate) { this.plannedMoveInDate = plannedMoveInDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getRepresentativeConsentedAt() { return representativeConsentedAt; }
    public void setRepresentativeConsentedAt(LocalDateTime representativeConsentedAt) { this.representativeConsentedAt = representativeConsentedAt; }
    public LocalDateTime getApplicantConsentedAt() { return applicantConsentedAt; }
    public void setApplicantConsentedAt(LocalDateTime applicantConsentedAt) { this.applicantConsentedAt = applicantConsentedAt; }
    public LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(LocalDateTime reviewedAt) { this.reviewedAt = reviewedAt; }
    public LocalDateTime getHoldExpiresAt() { return holdExpiresAt; }
    public void setHoldExpiresAt(LocalDateTime holdExpiresAt) { this.holdExpiresAt = holdExpiresAt; }
    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
    public LocalDateTime getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(LocalDateTime cancelledAt) { this.cancelledAt = cancelledAt; }
    public Long getReviewedById() { return reviewedById; }
    public void setReviewedById(Long reviewedById) { this.reviewedById = reviewedById; }
    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
    public Long getCompletedRoomTenantId() { return completedRoomTenantId; }
    public void setCompletedRoomTenantId(Long completedRoomTenantId) { this.completedRoomTenantId = completedRoomTenantId; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getOpenApplicantId() { return openApplicantId; }

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now(ZoneOffset.UTC);
    }
}
