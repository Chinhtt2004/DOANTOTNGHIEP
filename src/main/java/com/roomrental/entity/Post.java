package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps posts. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "posts")
public class Post implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`landlord_id`", nullable = false)
    private Long landlordId;
    @Column(name = "`room_id`", nullable = false)
    private Long roomId;
    @Column(name = "`title`", nullable = false, length = 200)
    private String title;
    @Column(name = "`content`", nullable = true, columnDefinition = "TEXT")
    private String content;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "DRAFT";
    @Column(name = "`availability_status`", nullable = false, length = 40)
    private String availabilityStatus = "STALE";
    @Column(name = "`availability_confirmed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime availabilityConfirmedAt;
    @Column(name = "`availability_expires_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime availabilityExpiresAt;
    @Column(name = "`published_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime publishedAt;
    @Column(name = "`reviewed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime reviewedAt;
    @Column(name = "`hidden_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime hiddenAt;
    @Column(name = "`reviewed_by_id`", nullable = true)
    private Long reviewedById;
    @Column(name = "`rejection_reason`", nullable = true, length = 1000)
    private String rejectionReason;
    @Column(name = "`hidden_by_id`", nullable = true)
    private Long hiddenById;
    @Column(name = "`hidden_reason`", nullable = true, length = 1000)
    private String hiddenReason;
    @Column(name = "`content_version`", nullable = false)
    private Long contentVersion = 1L;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`live_room_id`", nullable = true, insertable = false, updatable = false)
    private Long liveRoomId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getLandlordId() { return landlordId; }
    public void setLandlordId(Long landlordId) { this.landlordId = landlordId; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getAvailabilityStatus() { return availabilityStatus; }
    public void setAvailabilityStatus(String availabilityStatus) { this.availabilityStatus = availabilityStatus; }
    public LocalDateTime getAvailabilityConfirmedAt() { return availabilityConfirmedAt; }
    public void setAvailabilityConfirmedAt(LocalDateTime availabilityConfirmedAt) { this.availabilityConfirmedAt = availabilityConfirmedAt; }
    public LocalDateTime getAvailabilityExpiresAt() { return availabilityExpiresAt; }
    public void setAvailabilityExpiresAt(LocalDateTime availabilityExpiresAt) { this.availabilityExpiresAt = availabilityExpiresAt; }
    public LocalDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(LocalDateTime publishedAt) { this.publishedAt = publishedAt; }
    public LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(LocalDateTime reviewedAt) { this.reviewedAt = reviewedAt; }
    public LocalDateTime getHiddenAt() { return hiddenAt; }
    public void setHiddenAt(LocalDateTime hiddenAt) { this.hiddenAt = hiddenAt; }
    public Long getReviewedById() { return reviewedById; }
    public void setReviewedById(Long reviewedById) { this.reviewedById = reviewedById; }
    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
    public Long getHiddenById() { return hiddenById; }
    public void setHiddenById(Long hiddenById) { this.hiddenById = hiddenById; }
    public String getHiddenReason() { return hiddenReason; }
    public void setHiddenReason(String hiddenReason) { this.hiddenReason = hiddenReason; }
    public Long getContentVersion() { return contentVersion; }
    public void setContentVersion(Long contentVersion) { this.contentVersion = contentVersion; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getLiveRoomId() { return liveRoomId; }

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
