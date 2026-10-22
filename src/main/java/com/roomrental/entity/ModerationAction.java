package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps moderation_actions. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "moderation_actions")
public class ModerationAction implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`actor_user_id`", nullable = false)
    private Long actorUserId;
    @Column(name = "`target_user_id`", nullable = true)
    private Long targetUserId;
    @Column(name = "`target_post_id`", nullable = true)
    private Long targetPostId;
    @Column(name = "`target_report_id`", nullable = true)
    private Long targetReportId;
    @Column(name = "`target_landlord_verification_id`", nullable = true)
    private Long targetLandlordVerificationId;
    @Column(name = "`target_tenant_verification_id`", nullable = true)
    private Long targetTenantVerificationId;
    @Column(name = "`related_report_id`", nullable = true)
    private Long relatedReportId;
    @Column(name = "`action`", nullable = false, length = 80)
    private String action;
    @Column(name = "`reason`", nullable = false, columnDefinition = "TEXT")
    private String reason;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`before_snapshot`", nullable = true, columnDefinition = "JSON")
    private JsonNode beforeSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`after_snapshot`", nullable = true, columnDefinition = "JSON")
    private JsonNode afterSnapshot;
    @Column(name = "`occurred_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime occurredAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getActorUserId() { return actorUserId; }
    public void setActorUserId(Long actorUserId) { this.actorUserId = actorUserId; }
    public Long getTargetUserId() { return targetUserId; }
    public void setTargetUserId(Long targetUserId) { this.targetUserId = targetUserId; }
    public Long getTargetPostId() { return targetPostId; }
    public void setTargetPostId(Long targetPostId) { this.targetPostId = targetPostId; }
    public Long getTargetReportId() { return targetReportId; }
    public void setTargetReportId(Long targetReportId) { this.targetReportId = targetReportId; }
    public Long getTargetLandlordVerificationId() { return targetLandlordVerificationId; }
    public void setTargetLandlordVerificationId(Long targetLandlordVerificationId) { this.targetLandlordVerificationId = targetLandlordVerificationId; }
    public Long getTargetTenantVerificationId() { return targetTenantVerificationId; }
    public void setTargetTenantVerificationId(Long targetTenantVerificationId) { this.targetTenantVerificationId = targetTenantVerificationId; }
    public Long getRelatedReportId() { return relatedReportId; }
    public void setRelatedReportId(Long relatedReportId) { this.relatedReportId = relatedReportId; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public JsonNode getBeforeSnapshot() { return beforeSnapshot; }
    public void setBeforeSnapshot(JsonNode beforeSnapshot) { this.beforeSnapshot = beforeSnapshot; }
    public JsonNode getAfterSnapshot() { return afterSnapshot; }
    public void setAfterSnapshot(JsonNode afterSnapshot) { this.afterSnapshot = afterSnapshot; }
    public LocalDateTime getOccurredAt() { return occurredAt; }
    public void setOccurredAt(LocalDateTime occurredAt) { this.occurredAt = occurredAt; }
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
