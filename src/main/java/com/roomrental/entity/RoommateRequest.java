package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps roommate_requests. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "roommate_requests")
public class RoommateRequest implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`sender_id`", nullable = false)
    private Long senderId;
    @Column(name = "`receiver_id`", nullable = false)
    private Long receiverId;
    @Column(name = "`scenario`", nullable = false, length = 40)
    private String scenario;
    @Column(name = "`target_contract_id`", nullable = true)
    private Long targetContractId;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PENDING";
    @Column(name = "`message`", nullable = true, length = 2000)
    private String message;
    @Column(name = "`responded_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime respondedAt;
    @Column(name = "`ended_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime endedAt;
    @Column(name = "`end_reason`", nullable = true, length = 1000)
    private String endReason;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`pair_low_id`", nullable = true, insertable = false, updatable = false)
    private Long pairLowId;
    @Column(name = "`pair_high_id`", nullable = true, insertable = false, updatable = false)
    private Long pairHighId;
    @Column(name = "`open_pair_key`", nullable = true, insertable = false, updatable = false)
    private Integer openPairKey;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getSenderId() { return senderId; }
    public void setSenderId(Long senderId) { this.senderId = senderId; }
    public Long getReceiverId() { return receiverId; }
    public void setReceiverId(Long receiverId) { this.receiverId = receiverId; }
    public String getScenario() { return scenario; }
    public void setScenario(String scenario) { this.scenario = scenario; }
    public Long getTargetContractId() { return targetContractId; }
    public void setTargetContractId(Long targetContractId) { this.targetContractId = targetContractId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public LocalDateTime getRespondedAt() { return respondedAt; }
    public void setRespondedAt(LocalDateTime respondedAt) { this.respondedAt = respondedAt; }
    public LocalDateTime getEndedAt() { return endedAt; }
    public void setEndedAt(LocalDateTime endedAt) { this.endedAt = endedAt; }
    public String getEndReason() { return endReason; }
    public void setEndReason(String endReason) { this.endReason = endReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getPairLowId() { return pairLowId; }
    public Long getPairHighId() { return pairHighId; }
    public Integer getOpenPairKey() { return openPairKey; }

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
