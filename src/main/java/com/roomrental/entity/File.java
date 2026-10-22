package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps files. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "files")
public class File implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`owner_user_id`", nullable = false)
    private Long ownerUserId;
    @Column(name = "`storage_key`", nullable = false, length = 500)
    private String storageKey;
    @Column(name = "`original_name`", nullable = false, length = 255)
    private String originalName;
    @Column(name = "`mime_type`", nullable = false, length = 150)
    private String mimeType;
    @Column(name = "`size_bytes`", nullable = false)
    private Long sizeBytes;
    @Column(name = "`sha256`", nullable = false, length = 64, columnDefinition = "CHAR(64)")
    private String sha256;
    @Column(name = "`purpose`", nullable = false, length = 40)
    private String purpose;
    @Column(name = "`visibility`", nullable = false, length = 40)
    private String visibility = "PRIVATE";
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "STAGED";
    @Column(name = "`report_id`", nullable = true)
    private Long reportId;
    @Column(name = "`chat_message_id`", nullable = true)
    private Long chatMessageId;
    @Column(name = "`landlord_verification_id`", nullable = true)
    private Long landlordVerificationId;
    @Column(name = "`expires_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime expiresAt;
    @Column(name = "`deleted_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime deletedAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getOwnerUserId() { return ownerUserId; }
    public void setOwnerUserId(Long ownerUserId) { this.ownerUserId = ownerUserId; }
    public String getStorageKey() { return storageKey; }
    public void setStorageKey(String storageKey) { this.storageKey = storageKey; }
    public String getOriginalName() { return originalName; }
    public void setOriginalName(String originalName) { this.originalName = originalName; }
    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }
    public Long getSizeBytes() { return sizeBytes; }
    public void setSizeBytes(Long sizeBytes) { this.sizeBytes = sizeBytes; }
    public String getSha256() { return sha256; }
    public void setSha256(String sha256) { this.sha256 = sha256; }
    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }
    public String getVisibility() { return visibility; }
    public void setVisibility(String visibility) { this.visibility = visibility; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Long getReportId() { return reportId; }
    public void setReportId(Long reportId) { this.reportId = reportId; }
    public Long getChatMessageId() { return chatMessageId; }
    public void setChatMessageId(Long chatMessageId) { this.chatMessageId = chatMessageId; }
    public Long getLandlordVerificationId() { return landlordVerificationId; }
    public void setLandlordVerificationId(Long landlordVerificationId) { this.landlordVerificationId = landlordVerificationId; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
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
