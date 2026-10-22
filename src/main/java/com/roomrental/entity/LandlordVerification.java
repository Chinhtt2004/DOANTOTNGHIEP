package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps landlord_verifications. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "landlord_verifications")
public class LandlordVerification implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`applicant_user_id`", nullable = false)
    private Long applicantUserId;
    @Column(name = "`identity_number`", nullable = false, length = 30)
    private String identityNumber;
    @Column(name = "`identity_file_id`", nullable = false)
    private Long identityFileId;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PENDING";
    @Column(name = "`rejection_reason`", nullable = true, length = 1000)
    private String rejectionReason;
    @Column(name = "`reviewed_by_id`", nullable = true)
    private Long reviewedById;
    @Column(name = "`reviewed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime reviewedAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`pending_applicant_id`", nullable = true, insertable = false, updatable = false)
    private Long pendingApplicantId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getApplicantUserId() { return applicantUserId; }
    public void setApplicantUserId(Long applicantUserId) { this.applicantUserId = applicantUserId; }
    public String getIdentityNumber() { return identityNumber; }
    public void setIdentityNumber(String identityNumber) { this.identityNumber = identityNumber; }
    public Long getIdentityFileId() { return identityFileId; }
    public void setIdentityFileId(Long identityFileId) { this.identityFileId = identityFileId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
    public Long getReviewedById() { return reviewedById; }
    public void setReviewedById(Long reviewedById) { this.reviewedById = reviewedById; }
    public LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(LocalDateTime reviewedAt) { this.reviewedAt = reviewedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getPendingApplicantId() { return pendingApplicantId; }

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
