package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps contract_revisions. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "contract_revisions")
public class ContractRevision implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`contract_id`", nullable = false)
    private Long contractId;
    @Column(name = "`revision_number`", nullable = false)
    private Integer revisionNumber;
    @Column(name = "`template_id`", nullable = true)
    private Long templateId;
    @Column(name = "`created_by_id`", nullable = false)
    private Long createdById;
    @Column(name = "`kind`", nullable = false, length = 40)
    private String kind;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "DRAFT";
    @Column(name = "`start_date`", nullable = false)
    private LocalDate startDate;
    @Column(name = "`end_date`", nullable = false)
    private LocalDate endDate;
    @Column(name = "`effective_from`", nullable = false)
    private LocalDate effectiveFrom;
    @Column(name = "`rent_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal rentAmount = new BigDecimal("0");
    @Column(name = "`deposit_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal depositAmount = new BigDecimal("0");
    @Column(name = "`content`", nullable = false, columnDefinition = "LONGTEXT")
    private String content;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`members_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode membersSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`service_terms_snapshot`", nullable = true, columnDefinition = "JSON")
    private JsonNode serviceTermsSnapshot;
    @Column(name = "`document_file_id`", nullable = true)
    private Long documentFileId;
    @Column(name = "`representative_room_tenant_id`", nullable = false)
    private Long representativeRoomTenantId;
    @Column(name = "`landlord_confirmed_by_id`", nullable = true)
    private Long landlordConfirmedById;
    @Column(name = "`tenant_confirmed_by_id`", nullable = true)
    private Long tenantConfirmedById;
    @Column(name = "`landlord_confirmed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime landlordConfirmedAt;
    @Column(name = "`tenant_confirmed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime tenantConfirmedAt;
    @Column(name = "`sent_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime sentAt;
    @Column(name = "`applied_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime appliedAt;
    @Column(name = "`tenant_feedback`", nullable = true, length = 2000)
    private String tenantFeedback;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Integer getRevisionNumber() { return revisionNumber; }
    public void setRevisionNumber(Integer revisionNumber) { this.revisionNumber = revisionNumber; }
    public Long getTemplateId() { return templateId; }
    public void setTemplateId(Long templateId) { this.templateId = templateId; }
    public Long getCreatedById() { return createdById; }
    public void setCreatedById(Long createdById) { this.createdById = createdById; }
    public String getKind() { return kind; }
    public void setKind(String kind) { this.kind = kind; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    public LocalDate getEffectiveFrom() { return effectiveFrom; }
    public void setEffectiveFrom(LocalDate effectiveFrom) { this.effectiveFrom = effectiveFrom; }
    public BigDecimal getRentAmount() { return rentAmount; }
    public void setRentAmount(BigDecimal rentAmount) { this.rentAmount = rentAmount; }
    public BigDecimal getDepositAmount() { return depositAmount; }
    public void setDepositAmount(BigDecimal depositAmount) { this.depositAmount = depositAmount; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public JsonNode getMembersSnapshot() { return membersSnapshot; }
    public void setMembersSnapshot(JsonNode membersSnapshot) { this.membersSnapshot = membersSnapshot; }
    public JsonNode getServiceTermsSnapshot() { return serviceTermsSnapshot; }
    public void setServiceTermsSnapshot(JsonNode serviceTermsSnapshot) { this.serviceTermsSnapshot = serviceTermsSnapshot; }
    public Long getDocumentFileId() { return documentFileId; }
    public void setDocumentFileId(Long documentFileId) { this.documentFileId = documentFileId; }
    public Long getRepresentativeRoomTenantId() { return representativeRoomTenantId; }
    public void setRepresentativeRoomTenantId(Long representativeRoomTenantId) { this.representativeRoomTenantId = representativeRoomTenantId; }
    public Long getLandlordConfirmedById() { return landlordConfirmedById; }
    public void setLandlordConfirmedById(Long landlordConfirmedById) { this.landlordConfirmedById = landlordConfirmedById; }
    public Long getTenantConfirmedById() { return tenantConfirmedById; }
    public void setTenantConfirmedById(Long tenantConfirmedById) { this.tenantConfirmedById = tenantConfirmedById; }
    public LocalDateTime getLandlordConfirmedAt() { return landlordConfirmedAt; }
    public void setLandlordConfirmedAt(LocalDateTime landlordConfirmedAt) { this.landlordConfirmedAt = landlordConfirmedAt; }
    public LocalDateTime getTenantConfirmedAt() { return tenantConfirmedAt; }
    public void setTenantConfirmedAt(LocalDateTime tenantConfirmedAt) { this.tenantConfirmedAt = tenantConfirmedAt; }
    public LocalDateTime getSentAt() { return sentAt; }
    public void setSentAt(LocalDateTime sentAt) { this.sentAt = sentAt; }
    public LocalDateTime getAppliedAt() { return appliedAt; }
    public void setAppliedAt(LocalDateTime appliedAt) { this.appliedAt = appliedAt; }
    public String getTenantFeedback() { return tenantFeedback; }
    public void setTenantFeedback(String tenantFeedback) { this.tenantFeedback = tenantFeedback; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

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
