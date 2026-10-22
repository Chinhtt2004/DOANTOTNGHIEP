package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps contract_change_requests. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "contract_change_requests")
public class ContractChangeRequest implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`contract_id`", nullable = false)
    private Long contractId;
    @Column(name = "`requested_by_id`", nullable = false)
    private Long requestedById;
    @Column(name = "`representative_room_tenant_id`", nullable = false)
    private Long representativeRoomTenantId;
    @Column(name = "`base_revision_id`", nullable = false)
    private Long baseRevisionId;
    @Column(name = "`proposed_revision_id`", nullable = true)
    private Long proposedRevisionId;
    @Column(name = "`target_room_id`", nullable = true)
    private Long targetRoomId;
    @Column(name = "`result_contract_id`", nullable = true)
    private Long resultContractId;
    @Column(name = "`type`", nullable = false, length = 40)
    private String type;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PENDING";
    @Column(name = "`requested_effective_date`", nullable = false)
    private LocalDate requestedEffectiveDate;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`proposal_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode proposalSnapshot;
    @Column(name = "`message`", nullable = true, length = 2000)
    private String message;
    @Column(name = "`reviewed_by_id`", nullable = true)
    private Long reviewedById;
    @Column(name = "`rejection_reason`", nullable = true, length = 1000)
    private String rejectionReason;
    @Column(name = "`tenant_confirmed_by_id`", nullable = true)
    private Long tenantConfirmedById;
    @Column(name = "`applied_by_id`", nullable = true)
    private Long appliedById;
    @Column(name = "`reviewed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime reviewedAt;
    @Column(name = "`tenant_confirmed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime tenantConfirmedAt;
    @Column(name = "`applied_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime appliedAt;
    @Column(name = "`expires_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime expiresAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`open_contract_id`", nullable = true, insertable = false, updatable = false)
    private Long openContractId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Long getRequestedById() { return requestedById; }
    public void setRequestedById(Long requestedById) { this.requestedById = requestedById; }
    public Long getRepresentativeRoomTenantId() { return representativeRoomTenantId; }
    public void setRepresentativeRoomTenantId(Long representativeRoomTenantId) { this.representativeRoomTenantId = representativeRoomTenantId; }
    public Long getBaseRevisionId() { return baseRevisionId; }
    public void setBaseRevisionId(Long baseRevisionId) { this.baseRevisionId = baseRevisionId; }
    public Long getProposedRevisionId() { return proposedRevisionId; }
    public void setProposedRevisionId(Long proposedRevisionId) { this.proposedRevisionId = proposedRevisionId; }
    public Long getTargetRoomId() { return targetRoomId; }
    public void setTargetRoomId(Long targetRoomId) { this.targetRoomId = targetRoomId; }
    public Long getResultContractId() { return resultContractId; }
    public void setResultContractId(Long resultContractId) { this.resultContractId = resultContractId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDate getRequestedEffectiveDate() { return requestedEffectiveDate; }
    public void setRequestedEffectiveDate(LocalDate requestedEffectiveDate) { this.requestedEffectiveDate = requestedEffectiveDate; }
    public JsonNode getProposalSnapshot() { return proposalSnapshot; }
    public void setProposalSnapshot(JsonNode proposalSnapshot) { this.proposalSnapshot = proposalSnapshot; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public Long getReviewedById() { return reviewedById; }
    public void setReviewedById(Long reviewedById) { this.reviewedById = reviewedById; }
    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
    public Long getTenantConfirmedById() { return tenantConfirmedById; }
    public void setTenantConfirmedById(Long tenantConfirmedById) { this.tenantConfirmedById = tenantConfirmedById; }
    public Long getAppliedById() { return appliedById; }
    public void setAppliedById(Long appliedById) { this.appliedById = appliedById; }
    public LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(LocalDateTime reviewedAt) { this.reviewedAt = reviewedAt; }
    public LocalDateTime getTenantConfirmedAt() { return tenantConfirmedAt; }
    public void setTenantConfirmedAt(LocalDateTime tenantConfirmedAt) { this.tenantConfirmedAt = tenantConfirmedAt; }
    public LocalDateTime getAppliedAt() { return appliedAt; }
    public void setAppliedAt(LocalDateTime appliedAt) { this.appliedAt = appliedAt; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getOpenContractId() { return openContractId; }

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
