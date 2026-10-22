package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps verification_tokens. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "verification_tokens")
public class VerificationToken implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`user_id`", nullable = false)
    private Long userId;
    @Column(name = "`selector`", nullable = false, length = 36, columnDefinition = "CHAR(36)")
    private String selector;
    @Column(name = "`token_hash`", nullable = false, length = 64, columnDefinition = "CHAR(64)")
    private String tokenHash;
    @Column(name = "`purpose`", nullable = false, length = 40)
    private String purpose;
    @Column(name = "`target_value`", nullable = true, length = 255)
    private String targetValue;
    @Column(name = "`target_room_tenant_id`", nullable = true)
    private Long targetRoomTenantId;
    @Column(name = "`attempt_count`", nullable = false)
    private Integer attemptCount = 0;
    @Column(name = "`max_attempts`", nullable = false)
    private Integer maxAttempts = 5;
    @Column(name = "`expires_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime expiresAt;
    @Column(name = "`consumed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime consumedAt;
    @Column(name = "`revoked_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime revokedAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getSelector() { return selector; }
    public void setSelector(String selector) { this.selector = selector; }
    public String getTokenHash() { return tokenHash; }
    public void setTokenHash(String tokenHash) { this.tokenHash = tokenHash; }
    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }
    public String getTargetValue() { return targetValue; }
    public void setTargetValue(String targetValue) { this.targetValue = targetValue; }
    public Long getTargetRoomTenantId() { return targetRoomTenantId; }
    public void setTargetRoomTenantId(Long targetRoomTenantId) { this.targetRoomTenantId = targetRoomTenantId; }
    public Integer getAttemptCount() { return attemptCount; }
    public void setAttemptCount(Integer attemptCount) { this.attemptCount = attemptCount; }
    public Integer getMaxAttempts() { return maxAttempts; }
    public void setMaxAttempts(Integer maxAttempts) { this.maxAttempts = maxAttempts; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    public LocalDateTime getConsumedAt() { return consumedAt; }
    public void setConsumedAt(LocalDateTime consumedAt) { this.consumedAt = consumedAt; }
    public LocalDateTime getRevokedAt() { return revokedAt; }
    public void setRevokedAt(LocalDateTime revokedAt) { this.revokedAt = revokedAt; }
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
