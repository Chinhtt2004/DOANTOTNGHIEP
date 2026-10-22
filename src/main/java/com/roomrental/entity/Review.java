package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps reviews. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "reviews")
public class Review implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`reviewer_id`", nullable = false)
    private Long reviewerId;
    @Column(name = "`room_id`", nullable = false)
    private Long roomId;
    @Column(name = "`contract_id`", nullable = false)
    private Long contractId;
    @Column(name = "`room_tenant_id`", nullable = false)
    private Long roomTenantId;
    @Column(name = "`rating`", nullable = false, columnDefinition = "TINYINT")
    private Byte rating;
    @Column(name = "`content`", nullable = true, columnDefinition = "TEXT")
    private String content;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PUBLISHED";
    @Column(name = "`hidden_by_id`", nullable = true)
    private Long hiddenById;
    @Column(name = "`hidden_reason`", nullable = true, length = 1000)
    private String hiddenReason;
    @Column(name = "`hidden_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime hiddenAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getReviewerId() { return reviewerId; }
    public void setReviewerId(Long reviewerId) { this.reviewerId = reviewerId; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Long getRoomTenantId() { return roomTenantId; }
    public void setRoomTenantId(Long roomTenantId) { this.roomTenantId = roomTenantId; }
    public Byte getRating() { return rating; }
    public void setRating(Byte rating) { this.rating = rating; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Long getHiddenById() { return hiddenById; }
    public void setHiddenById(Long hiddenById) { this.hiddenById = hiddenById; }
    public String getHiddenReason() { return hiddenReason; }
    public void setHiddenReason(String hiddenReason) { this.hiddenReason = hiddenReason; }
    public LocalDateTime getHiddenAt() { return hiddenAt; }
    public void setHiddenAt(LocalDateTime hiddenAt) { this.hiddenAt = hiddenAt; }
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
