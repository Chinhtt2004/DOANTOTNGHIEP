package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps users. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "users")
public class User implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`email`", nullable = true, length = 150)
    private String email;
    @Column(name = "`phone_number`", nullable = true, length = 20)
    private String phoneNumber;
    @Column(name = "`password_hash`", nullable = false, length = 255)
    private String passwordHash;
    @Column(name = "`full_name`", nullable = false, length = 150)
    private String fullName;
    @Column(name = "`role`", nullable = false, length = 40)
    private String role = "TENANT";
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "ACTIVE";
    @Column(name = "`phone_verified_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime phoneVerifiedAt;
    @Column(name = "`locked_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime lockedAt;
    @Column(name = "`in_app_enabled`", nullable = false)
    private Boolean inAppEnabled = true;
    @Column(name = "`email_enabled`", nullable = false)
    private Boolean emailEnabled = false;
    @Column(name = "`push_enabled`", nullable = false)
    private Boolean pushEnabled = false;
    @Column(name = "`lock_reason`", nullable = true, length = 1000)
    private String lockReason;
    @Column(name = "`locked_by_id`", nullable = true)
    private Long lockedById;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getPhoneVerifiedAt() { return phoneVerifiedAt; }
    public void setPhoneVerifiedAt(LocalDateTime phoneVerifiedAt) { this.phoneVerifiedAt = phoneVerifiedAt; }
    public LocalDateTime getLockedAt() { return lockedAt; }
    public void setLockedAt(LocalDateTime lockedAt) { this.lockedAt = lockedAt; }
    public Boolean getInAppEnabled() { return inAppEnabled; }
    public void setInAppEnabled(Boolean inAppEnabled) { this.inAppEnabled = inAppEnabled; }
    public Boolean getEmailEnabled() { return emailEnabled; }
    public void setEmailEnabled(Boolean emailEnabled) { this.emailEnabled = emailEnabled; }
    public Boolean getPushEnabled() { return pushEnabled; }
    public void setPushEnabled(Boolean pushEnabled) { this.pushEnabled = pushEnabled; }
    public String getLockReason() { return lockReason; }
    public void setLockReason(String lockReason) { this.lockReason = lockReason; }
    public Long getLockedById() { return lockedById; }
    public void setLockedById(Long lockedById) { this.lockedById = lockedById; }
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
