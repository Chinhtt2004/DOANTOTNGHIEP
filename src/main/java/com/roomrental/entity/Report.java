package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps reports. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "reports")
public class Report implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`reporter_id`", nullable = false)
    private Long reporterId;
    @Column(name = "`type`", nullable = false, length = 40)
    private String type;
    @Column(name = "`reported_user_id`", nullable = true)
    private Long reportedUserId;
    @Column(name = "`reported_post_id`", nullable = true)
    private Long reportedPostId;
    @Column(name = "`contract_id`", nullable = true)
    private Long contractId;
    @Column(name = "`roommate_request_id`", nullable = true)
    private Long roommateRequestId;
    @Column(name = "`reason`", nullable = false, columnDefinition = "TEXT")
    private String reason;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PENDING";
    @Column(name = "`resolution`", nullable = true, columnDefinition = "TEXT")
    private String resolution;
    @Column(name = "`handled_by_id`", nullable = true)
    private Long handledById;
    @Column(name = "`handled_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime handledAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getReporterId() { return reporterId; }
    public void setReporterId(Long reporterId) { this.reporterId = reporterId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Long getReportedUserId() { return reportedUserId; }
    public void setReportedUserId(Long reportedUserId) { this.reportedUserId = reportedUserId; }
    public Long getReportedPostId() { return reportedPostId; }
    public void setReportedPostId(Long reportedPostId) { this.reportedPostId = reportedPostId; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Long getRoommateRequestId() { return roommateRequestId; }
    public void setRoommateRequestId(Long roommateRequestId) { this.roommateRequestId = roommateRequestId; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getResolution() { return resolution; }
    public void setResolution(String resolution) { this.resolution = resolution; }
    public Long getHandledById() { return handledById; }
    public void setHandledById(Long handledById) { this.handledById = handledById; }
    public LocalDateTime getHandledAt() { return handledAt; }
    public void setHandledAt(LocalDateTime handledAt) { this.handledAt = handledAt; }
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
