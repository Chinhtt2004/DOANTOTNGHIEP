package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps room_recommendations. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "room_recommendations")
public class RoomRecommendation implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`batch_key`", nullable = false, length = 36, columnDefinition = "CHAR(36)")
    private String batchKey;
    @Column(name = "`user_id`", nullable = false)
    private Long userId;
    @Column(name = "`room_id`", nullable = false)
    private Long roomId;
    @Column(name = "`post_id`", nullable = false)
    private Long postId;
    @Column(name = "`embedding_id`", nullable = false)
    private Long embeddingId;
    @Column(name = "`model_version_id`", nullable = false)
    private Long modelVersionId;
    @Column(name = "`ranking_position`", nullable = false)
    private Integer rankingPosition;
    @Column(name = "`cosine_score`", nullable = false, precision = 10, scale = 8)
    private BigDecimal cosineScore;
    @Column(name = "`query_text`", nullable = false, columnDefinition = "TEXT")
    private String queryText;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`criteria_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode criteriaSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`room_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode roomSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`reasons`", nullable = false, columnDefinition = "JSON")
    private JsonNode reasons;
    @Column(name = "`generated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime generatedAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getBatchKey() { return batchKey; }
    public void setBatchKey(String batchKey) { this.batchKey = batchKey; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getPostId() { return postId; }
    public void setPostId(Long postId) { this.postId = postId; }
    public Long getEmbeddingId() { return embeddingId; }
    public void setEmbeddingId(Long embeddingId) { this.embeddingId = embeddingId; }
    public Long getModelVersionId() { return modelVersionId; }
    public void setModelVersionId(Long modelVersionId) { this.modelVersionId = modelVersionId; }
    public Integer getRankingPosition() { return rankingPosition; }
    public void setRankingPosition(Integer rankingPosition) { this.rankingPosition = rankingPosition; }
    public BigDecimal getCosineScore() { return cosineScore; }
    public void setCosineScore(BigDecimal cosineScore) { this.cosineScore = cosineScore; }
    public String getQueryText() { return queryText; }
    public void setQueryText(String queryText) { this.queryText = queryText; }
    public JsonNode getCriteriaSnapshot() { return criteriaSnapshot; }
    public void setCriteriaSnapshot(JsonNode criteriaSnapshot) { this.criteriaSnapshot = criteriaSnapshot; }
    public JsonNode getRoomSnapshot() { return roomSnapshot; }
    public void setRoomSnapshot(JsonNode roomSnapshot) { this.roomSnapshot = roomSnapshot; }
    public JsonNode getReasons() { return reasons; }
    public void setReasons(JsonNode reasons) { this.reasons = reasons; }
    public LocalDateTime getGeneratedAt() { return generatedAt; }
    public void setGeneratedAt(LocalDateTime generatedAt) { this.generatedAt = generatedAt; }
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
