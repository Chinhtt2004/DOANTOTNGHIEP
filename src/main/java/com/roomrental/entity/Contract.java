package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps contracts. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "contracts")
public class Contract implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`contract_number`", nullable = false, length = 100)
    private String contractNumber;
    @Column(name = "`room_id`", nullable = false)
    private Long roomId;
    @Column(name = "`landlord_id`", nullable = false)
    private Long landlordId;
    @Column(name = "`representative_room_tenant_id`", nullable = true)
    private Long representativeRoomTenantId;
    @Column(name = "`current_revision_id`", nullable = true)
    private Long currentRevisionId;
    @Column(name = "`viewing_id`", nullable = true)
    private Long viewingId;
    @Column(name = "`previous_contract_id`", nullable = true)
    private Long previousContractId;
    @Column(name = "`paper_document_file_id`", nullable = true)
    private Long paperDocumentFileId;
    @Column(name = "`source`", nullable = false, length = 40)
    private String source;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "DRAFT";
    @Column(name = "`start_date`", nullable = false)
    private LocalDate startDate;
    @Column(name = "`end_date`", nullable = false)
    private LocalDate endDate;
    @Column(name = "`rent_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal rentAmount = new BigDecimal("0");
    @Column(name = "`deposit_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal depositAmount = new BigDecimal("0");
    @Column(name = "`activated_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime activatedAt;
    @Column(name = "`closed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime closedAt;
    @Column(name = "`closure_reason`", nullable = true, length = 1000)
    private String closureReason;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`live_room_id`", nullable = true, insertable = false, updatable = false)
    private Long liveRoomId;
    @Column(name = "`live_viewing_id`", nullable = true, insertable = false, updatable = false)
    private Long liveViewingId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getContractNumber() { return contractNumber; }
    public void setContractNumber(String contractNumber) { this.contractNumber = contractNumber; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getLandlordId() { return landlordId; }
    public void setLandlordId(Long landlordId) { this.landlordId = landlordId; }
    public Long getRepresentativeRoomTenantId() { return representativeRoomTenantId; }
    public void setRepresentativeRoomTenantId(Long representativeRoomTenantId) { this.representativeRoomTenantId = representativeRoomTenantId; }
    public Long getCurrentRevisionId() { return currentRevisionId; }
    public void setCurrentRevisionId(Long currentRevisionId) { this.currentRevisionId = currentRevisionId; }
    public Long getViewingId() { return viewingId; }
    public void setViewingId(Long viewingId) { this.viewingId = viewingId; }
    public Long getPreviousContractId() { return previousContractId; }
    public void setPreviousContractId(Long previousContractId) { this.previousContractId = previousContractId; }
    public Long getPaperDocumentFileId() { return paperDocumentFileId; }
    public void setPaperDocumentFileId(Long paperDocumentFileId) { this.paperDocumentFileId = paperDocumentFileId; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    public BigDecimal getRentAmount() { return rentAmount; }
    public void setRentAmount(BigDecimal rentAmount) { this.rentAmount = rentAmount; }
    public BigDecimal getDepositAmount() { return depositAmount; }
    public void setDepositAmount(BigDecimal depositAmount) { this.depositAmount = depositAmount; }
    public LocalDateTime getActivatedAt() { return activatedAt; }
    public void setActivatedAt(LocalDateTime activatedAt) { this.activatedAt = activatedAt; }
    public LocalDateTime getClosedAt() { return closedAt; }
    public void setClosedAt(LocalDateTime closedAt) { this.closedAt = closedAt; }
    public String getClosureReason() { return closureReason; }
    public void setClosureReason(String closureReason) { this.closureReason = closureReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getLiveRoomId() { return liveRoomId; }
    public Long getLiveViewingId() { return liveViewingId; }

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
