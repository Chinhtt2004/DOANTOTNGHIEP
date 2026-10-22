package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps conversation_participants. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "conversation_participants")
public class ConversationParticipant implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`conversation_id`", nullable = false)
    private Long conversationId;
    @Column(name = "`user_id`", nullable = false)
    private Long userId;
    @Column(name = "`joined_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime joinedAt;
    @Column(name = "`last_read_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime lastReadAt;
    @Column(name = "`left_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime leftAt;
    @Column(name = "`muted`", nullable = false)
    private Boolean muted = false;
    @Column(name = "`archived`", nullable = false)
    private Boolean archived = false;
    @Column(name = "`deleted`", nullable = false)
    private Boolean deleted = false;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getConversationId() { return conversationId; }
    public void setConversationId(Long conversationId) { this.conversationId = conversationId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public LocalDateTime getJoinedAt() { return joinedAt; }
    public void setJoinedAt(LocalDateTime joinedAt) { this.joinedAt = joinedAt; }
    public LocalDateTime getLastReadAt() { return lastReadAt; }
    public void setLastReadAt(LocalDateTime lastReadAt) { this.lastReadAt = lastReadAt; }
    public LocalDateTime getLeftAt() { return leftAt; }
    public void setLeftAt(LocalDateTime leftAt) { this.leftAt = leftAt; }
    public Boolean getMuted() { return muted; }
    public void setMuted(Boolean muted) { this.muted = muted; }
    public Boolean getArchived() { return archived; }
    public void setArchived(Boolean archived) { this.archived = archived; }
    public Boolean getDeleted() { return deleted; }
    public void setDeleted(Boolean deleted) { this.deleted = deleted; }
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
