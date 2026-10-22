package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps room_viewing_requests. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "room_viewing_requests")
public class RoomViewingRequest implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`room_id`", nullable = false)
    private Long roomId;
    @Column(name = "`tenant_id`", nullable = false)
    private Long tenantId;
    @Column(name = "`created_by_id`", nullable = false)
    private Long createdById;
    @Column(name = "`starts_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime startsAt;
    @Column(name = "`ends_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime endsAt;
    @Column(name = "`notes`", nullable = true, length = 2000)
    private String notes;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "SCHEDULED";
    @Column(name = "`attendance_confirmed_by_id`", nullable = true)
    private Long attendanceConfirmedById;
    @Column(name = "`attendance_confirmed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime attendanceConfirmedAt;
    @Column(name = "`cancelled_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime cancelledAt;
    @Column(name = "`cancelled_by_id`", nullable = true)
    private Long cancelledById;
    @Column(name = "`cancellation_reason`", nullable = true, length = 1000)
    private String cancellationReason;
    @Column(name = "`rental_decision`", nullable = false, length = 40)
    private String rentalDecision = "WAITING";
    @Column(name = "`rental_decided_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime rentalDecidedAt;
    @Column(name = "`rental_withdrawn_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime rentalWithdrawnAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }
    public Long getCreatedById() { return createdById; }
    public void setCreatedById(Long createdById) { this.createdById = createdById; }
    public LocalDateTime getStartsAt() { return startsAt; }
    public void setStartsAt(LocalDateTime startsAt) { this.startsAt = startsAt; }
    public LocalDateTime getEndsAt() { return endsAt; }
    public void setEndsAt(LocalDateTime endsAt) { this.endsAt = endsAt; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Long getAttendanceConfirmedById() { return attendanceConfirmedById; }
    public void setAttendanceConfirmedById(Long attendanceConfirmedById) { this.attendanceConfirmedById = attendanceConfirmedById; }
    public LocalDateTime getAttendanceConfirmedAt() { return attendanceConfirmedAt; }
    public void setAttendanceConfirmedAt(LocalDateTime attendanceConfirmedAt) { this.attendanceConfirmedAt = attendanceConfirmedAt; }
    public LocalDateTime getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(LocalDateTime cancelledAt) { this.cancelledAt = cancelledAt; }
    public Long getCancelledById() { return cancelledById; }
    public void setCancelledById(Long cancelledById) { this.cancelledById = cancelledById; }
    public String getCancellationReason() { return cancellationReason; }
    public void setCancellationReason(String cancellationReason) { this.cancellationReason = cancellationReason; }
    public String getRentalDecision() { return rentalDecision; }
    public void setRentalDecision(String rentalDecision) { this.rentalDecision = rentalDecision; }
    public LocalDateTime getRentalDecidedAt() { return rentalDecidedAt; }
    public void setRentalDecidedAt(LocalDateTime rentalDecidedAt) { this.rentalDecidedAt = rentalDecidedAt; }
    public LocalDateTime getRentalWithdrawnAt() { return rentalWithdrawnAt; }
    public void setRentalWithdrawnAt(LocalDateTime rentalWithdrawnAt) { this.rentalWithdrawnAt = rentalWithdrawnAt; }
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
