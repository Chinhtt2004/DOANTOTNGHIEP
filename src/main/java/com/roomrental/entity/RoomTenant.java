package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps room_tenants. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "room_tenants")
public class RoomTenant implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`contract_id`", nullable = false)
    private Long contractId;
    @Column(name = "`room_id`", nullable = false)
    private Long roomId;
    @Column(name = "`tenant_id`", nullable = true)
    private Long tenantId;
    @Column(name = "`full_name`", nullable = false, length = 150)
    private String fullName;
    @Column(name = "`phone_number`", nullable = true, length = 20)
    private String phoneNumber;
    @Column(name = "`identity_number`", nullable = true, length = 30)
    private String identityNumber;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PLANNED";
    @Column(name = "`intake_source`", nullable = false, length = 40)
    private String intakeSource;
    @Column(name = "`join_request_id`", nullable = true)
    private Long joinRequestId;
    @Column(name = "`planned_move_in_date`", nullable = true)
    private LocalDate plannedMoveInDate;
    @Column(name = "`move_in_date`", nullable = true)
    private LocalDate moveInDate;
    @Column(name = "`move_out_date`", nullable = true)
    private LocalDate moveOutDate;
    @Column(name = "`move_in_confirmed_by_id`", nullable = true)
    private Long moveInConfirmedById;
    @Column(name = "`move_out_confirmed_by_id`", nullable = true)
    private Long moveOutConfirmedById;
    @Column(name = "`move_in_confirmed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime moveInConfirmedAt;
    @Column(name = "`move_out_confirmed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime moveOutConfirmedAt;
    @Column(name = "`account_linked_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime accountLinkedAt;
    @Column(name = "`account_linked_by_id`", nullable = true)
    private Long accountLinkedById;
    @Column(name = "`cancellation_reason`", nullable = true, length = 1000)
    private String cancellationReason;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`active_tenant_id`", nullable = true, insertable = false, updatable = false)
    private Long activeTenantId;
    @Column(name = "`open_tenant_id`", nullable = true, insertable = false, updatable = false)
    private Long openTenantId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getIdentityNumber() { return identityNumber; }
    public void setIdentityNumber(String identityNumber) { this.identityNumber = identityNumber; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getIntakeSource() { return intakeSource; }
    public void setIntakeSource(String intakeSource) { this.intakeSource = intakeSource; }
    public Long getJoinRequestId() { return joinRequestId; }
    public void setJoinRequestId(Long joinRequestId) { this.joinRequestId = joinRequestId; }
    public LocalDate getPlannedMoveInDate() { return plannedMoveInDate; }
    public void setPlannedMoveInDate(LocalDate plannedMoveInDate) { this.plannedMoveInDate = plannedMoveInDate; }
    public LocalDate getMoveInDate() { return moveInDate; }
    public void setMoveInDate(LocalDate moveInDate) { this.moveInDate = moveInDate; }
    public LocalDate getMoveOutDate() { return moveOutDate; }
    public void setMoveOutDate(LocalDate moveOutDate) { this.moveOutDate = moveOutDate; }
    public Long getMoveInConfirmedById() { return moveInConfirmedById; }
    public void setMoveInConfirmedById(Long moveInConfirmedById) { this.moveInConfirmedById = moveInConfirmedById; }
    public Long getMoveOutConfirmedById() { return moveOutConfirmedById; }
    public void setMoveOutConfirmedById(Long moveOutConfirmedById) { this.moveOutConfirmedById = moveOutConfirmedById; }
    public LocalDateTime getMoveInConfirmedAt() { return moveInConfirmedAt; }
    public void setMoveInConfirmedAt(LocalDateTime moveInConfirmedAt) { this.moveInConfirmedAt = moveInConfirmedAt; }
    public LocalDateTime getMoveOutConfirmedAt() { return moveOutConfirmedAt; }
    public void setMoveOutConfirmedAt(LocalDateTime moveOutConfirmedAt) { this.moveOutConfirmedAt = moveOutConfirmedAt; }
    public LocalDateTime getAccountLinkedAt() { return accountLinkedAt; }
    public void setAccountLinkedAt(LocalDateTime accountLinkedAt) { this.accountLinkedAt = accountLinkedAt; }
    public Long getAccountLinkedById() { return accountLinkedById; }
    public void setAccountLinkedById(Long accountLinkedById) { this.accountLinkedById = accountLinkedById; }
    public String getCancellationReason() { return cancellationReason; }
    public void setCancellationReason(String cancellationReason) { this.cancellationReason = cancellationReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getActiveTenantId() { return activeTenantId; }
    public Long getOpenTenantId() { return openTenantId; }

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
