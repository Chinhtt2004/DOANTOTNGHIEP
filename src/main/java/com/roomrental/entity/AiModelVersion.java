package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps ai_model_versions. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "ai_model_versions")
public class AiModelVersion implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`kind`", nullable = false, length = 40)
    private String kind;
    @Column(name = "`version`", nullable = false, length = 100)
    private String version;
    @Column(name = "`model_name`", nullable = false, length = 200)
    private String modelName;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "DRAFT";
    @Column(name = "`artifact_uri`", nullable = false, length = 1000)
    private String artifactUri;
    @Column(name = "`artifact_sha256`", nullable = true, length = 64, columnDefinition = "CHAR(64)")
    private String artifactSha256;
    @Column(name = "`feature_schema_version`", nullable = false, length = 100)
    private String featureSchemaVersion;
    @Column(name = "`embedding_dimensions`", nullable = true)
    private Integer embeddingDimensions;
    @Column(name = "`dataset_version`", nullable = true, length = 100)
    private String datasetVersion;
    @Column(name = "`dataset_manifest_uri`", nullable = true, length = 1000)
    private String datasetManifestUri;
    @Column(name = "`split_strategy`", nullable = true, length = 100)
    private String splitStrategy;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`parameters`", nullable = true, columnDefinition = "JSON")
    private JsonNode parameters;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`metrics`", nullable = true, columnDefinition = "JSON")
    private JsonNode metrics;
    @Column(name = "`evaluation_notes`", nullable = true, columnDefinition = "TEXT")
    private String evaluationNotes;
    @Column(name = "`created_by_id`", nullable = true)
    private Long createdById;
    @Column(name = "`activated_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime activatedAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`active_kind`", nullable = true, length = 40, insertable = false, updatable = false)
    private String activeKind;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getKind() { return kind; }
    public void setKind(String kind) { this.kind = kind; }
    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }
    public String getModelName() { return modelName; }
    public void setModelName(String modelName) { this.modelName = modelName; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getArtifactUri() { return artifactUri; }
    public void setArtifactUri(String artifactUri) { this.artifactUri = artifactUri; }
    public String getArtifactSha256() { return artifactSha256; }
    public void setArtifactSha256(String artifactSha256) { this.artifactSha256 = artifactSha256; }
    public String getFeatureSchemaVersion() { return featureSchemaVersion; }
    public void setFeatureSchemaVersion(String featureSchemaVersion) { this.featureSchemaVersion = featureSchemaVersion; }
    public Integer getEmbeddingDimensions() { return embeddingDimensions; }
    public void setEmbeddingDimensions(Integer embeddingDimensions) { this.embeddingDimensions = embeddingDimensions; }
    public String getDatasetVersion() { return datasetVersion; }
    public void setDatasetVersion(String datasetVersion) { this.datasetVersion = datasetVersion; }
    public String getDatasetManifestUri() { return datasetManifestUri; }
    public void setDatasetManifestUri(String datasetManifestUri) { this.datasetManifestUri = datasetManifestUri; }
    public String getSplitStrategy() { return splitStrategy; }
    public void setSplitStrategy(String splitStrategy) { this.splitStrategy = splitStrategy; }
    public JsonNode getParameters() { return parameters; }
    public void setParameters(JsonNode parameters) { this.parameters = parameters; }
    public JsonNode getMetrics() { return metrics; }
    public void setMetrics(JsonNode metrics) { this.metrics = metrics; }
    public String getEvaluationNotes() { return evaluationNotes; }
    public void setEvaluationNotes(String evaluationNotes) { this.evaluationNotes = evaluationNotes; }
    public Long getCreatedById() { return createdById; }
    public void setCreatedById(Long createdById) { this.createdById = createdById; }
    public LocalDateTime getActivatedAt() { return activatedAt; }
    public void setActivatedAt(LocalDateTime activatedAt) { this.activatedAt = activatedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public String getActiveKind() { return activeKind; }

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
