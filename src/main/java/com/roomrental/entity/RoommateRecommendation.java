package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps roommate_recommendations. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "roommate_recommendations")
public class RoommateRecommendation implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`batch_key`", nullable = false, length = 36, columnDefinition = "CHAR(36)")
    private String batchKey;
    @Column(name = "`source_profile_id`", nullable = false)
    private Long sourceProfileId;
    @Column(name = "`suggested_profile_id`", nullable = false)
    private Long suggestedProfileId;
    @Column(name = "`model_version_id`", nullable = false)
    private Long modelVersionId;
    @Column(name = "`source_profile_version`", nullable = false)
    private Long sourceProfileVersion;
    @Column(name = "`suggested_profile_version`", nullable = false)
    private Long suggestedProfileVersion;
    @Column(name = "`feature_schema_version`", nullable = false, length = 100)
    private String featureSchemaVersion;
    @Column(name = "`ranking_position`", nullable = false)
    private Integer rankingPosition;
    @Column(name = "`matching_score`", nullable = false, precision = 10, scale = 8)
    private BigDecimal matchingScore;
    @Column(name = "`data_coverage`", nullable = false, precision = 5, scale = 4)
    private BigDecimal dataCoverage;
    @Column(name = "`scenario_snapshot`", nullable = false, length = 40)
    private String scenarioSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`profiles_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode profilesSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`features_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode featuresSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`shap_values`", nullable = true, columnDefinition = "JSON")
    private JsonNode shapValues;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`explanation`", nullable = true, columnDefinition = "JSON")
    private JsonNode explanation;
    @Column(name = "`explanation_status`", nullable = false, length = 40)
    private String explanationStatus = "UNAVAILABLE";
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
    public Long getSourceProfileId() { return sourceProfileId; }
    public void setSourceProfileId(Long sourceProfileId) { this.sourceProfileId = sourceProfileId; }
    public Long getSuggestedProfileId() { return suggestedProfileId; }
    public void setSuggestedProfileId(Long suggestedProfileId) { this.suggestedProfileId = suggestedProfileId; }
    public Long getModelVersionId() { return modelVersionId; }
    public void setModelVersionId(Long modelVersionId) { this.modelVersionId = modelVersionId; }
    public Long getSourceProfileVersion() { return sourceProfileVersion; }
    public void setSourceProfileVersion(Long sourceProfileVersion) { this.sourceProfileVersion = sourceProfileVersion; }
    public Long getSuggestedProfileVersion() { return suggestedProfileVersion; }
    public void setSuggestedProfileVersion(Long suggestedProfileVersion) { this.suggestedProfileVersion = suggestedProfileVersion; }
    public String getFeatureSchemaVersion() { return featureSchemaVersion; }
    public void setFeatureSchemaVersion(String featureSchemaVersion) { this.featureSchemaVersion = featureSchemaVersion; }
    public Integer getRankingPosition() { return rankingPosition; }
    public void setRankingPosition(Integer rankingPosition) { this.rankingPosition = rankingPosition; }
    public BigDecimal getMatchingScore() { return matchingScore; }
    public void setMatchingScore(BigDecimal matchingScore) { this.matchingScore = matchingScore; }
    public BigDecimal getDataCoverage() { return dataCoverage; }
    public void setDataCoverage(BigDecimal dataCoverage) { this.dataCoverage = dataCoverage; }
    public String getScenarioSnapshot() { return scenarioSnapshot; }
    public void setScenarioSnapshot(String scenarioSnapshot) { this.scenarioSnapshot = scenarioSnapshot; }
    public JsonNode getProfilesSnapshot() { return profilesSnapshot; }
    public void setProfilesSnapshot(JsonNode profilesSnapshot) { this.profilesSnapshot = profilesSnapshot; }
    public JsonNode getFeaturesSnapshot() { return featuresSnapshot; }
    public void setFeaturesSnapshot(JsonNode featuresSnapshot) { this.featuresSnapshot = featuresSnapshot; }
    public JsonNode getShapValues() { return shapValues; }
    public void setShapValues(JsonNode shapValues) { this.shapValues = shapValues; }
    public JsonNode getExplanation() { return explanation; }
    public void setExplanation(JsonNode explanation) { this.explanation = explanation; }
    public String getExplanationStatus() { return explanationStatus; }
    public void setExplanationStatus(String explanationStatus) { this.explanationStatus = explanationStatus; }
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
