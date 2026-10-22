package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps room_embeddings. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "room_embeddings")
public class RoomEmbedding implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`room_id`", nullable = false)
    private Long roomId;
    @Column(name = "`post_id`", nullable = false)
    private Long postId;
    @Column(name = "`model_version_id`", nullable = false)
    private Long modelVersionId;
    @Column(name = "`content_version`", nullable = false)
    private Long contentVersion;
    @Column(name = "`content_sha256`", nullable = false, length = 64, columnDefinition = "CHAR(64)")
    private String contentSha256;
    @Column(name = "`text_snapshot`", nullable = false, columnDefinition = "TEXT")
    private String textSnapshot;
    @Column(name = "`index_version`", nullable = false, length = 100)
    private String indexVersion;
    @Column(name = "`vector_id`", nullable = true)
    private Long vectorId;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "PENDING";
    @Column(name = "`indexed_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime indexedAt;
    @Column(name = "`failure_reason`", nullable = true, length = 1000)
    private String failureReason;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getPostId() { return postId; }
    public void setPostId(Long postId) { this.postId = postId; }
    public Long getModelVersionId() { return modelVersionId; }
    public void setModelVersionId(Long modelVersionId) { this.modelVersionId = modelVersionId; }
    public Long getContentVersion() { return contentVersion; }
    public void setContentVersion(Long contentVersion) { this.contentVersion = contentVersion; }
    public String getContentSha256() { return contentSha256; }
    public void setContentSha256(String contentSha256) { this.contentSha256 = contentSha256; }
    public String getTextSnapshot() { return textSnapshot; }
    public void setTextSnapshot(String textSnapshot) { this.textSnapshot = textSnapshot; }
    public String getIndexVersion() { return indexVersion; }
    public void setIndexVersion(String indexVersion) { this.indexVersion = indexVersion; }
    public Long getVectorId() { return vectorId; }
    public void setVectorId(Long vectorId) { this.vectorId = vectorId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getIndexedAt() { return indexedAt; }
    public void setIndexedAt(LocalDateTime indexedAt) { this.indexedAt = indexedAt; }
    public String getFailureReason() { return failureReason; }
    public void setFailureReason(String failureReason) { this.failureReason = failureReason; }
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
