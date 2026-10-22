package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps roommate_training_pairs. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "roommate_training_pairs")
public class RoommateTrainingPair implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`dataset_version`", nullable = false, length = 100)
    private String datasetVersion;
    @Column(name = "`participant_a_key`", nullable = false, length = 64)
    private String participantAKey;
    @Column(name = "`participant_b_key`", nullable = false, length = 64)
    private String participantBKey;
    @Column(name = "`annotator_key`", nullable = false, length = 64)
    private String annotatorKey;
    @Column(name = "`label`", nullable = false, columnDefinition = "TINYINT")
    private Byte label;
    @Column(name = "`data_source`", nullable = false, length = 40)
    private String dataSource;
    @Column(name = "`split`", nullable = false, length = 40)
    private String split = "UNASSIGNED";
    @Column(name = "`feature_schema_version`", nullable = false, length = 100)
    private String featureSchemaVersion;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`profiles_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode profilesSnapshot;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`features_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode featuresSnapshot;
    @Column(name = "`consent_reference`", nullable = true, length = 255)
    private String consentReference;
    @Column(name = "`source_reference`", nullable = false, length = 1000)
    private String sourceReference;
    @Column(name = "`labelled_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime labelledAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getDatasetVersion() { return datasetVersion; }
    public void setDatasetVersion(String datasetVersion) { this.datasetVersion = datasetVersion; }
    public String getParticipantAKey() { return participantAKey; }
    public void setParticipantAKey(String participantAKey) { this.participantAKey = participantAKey; }
    public String getParticipantBKey() { return participantBKey; }
    public void setParticipantBKey(String participantBKey) { this.participantBKey = participantBKey; }
    public String getAnnotatorKey() { return annotatorKey; }
    public void setAnnotatorKey(String annotatorKey) { this.annotatorKey = annotatorKey; }
    public Byte getLabel() { return label; }
    public void setLabel(Byte label) { this.label = label; }
    public String getDataSource() { return dataSource; }
    public void setDataSource(String dataSource) { this.dataSource = dataSource; }
    public String getSplit() { return split; }
    public void setSplit(String split) { this.split = split; }
    public String getFeatureSchemaVersion() { return featureSchemaVersion; }
    public void setFeatureSchemaVersion(String featureSchemaVersion) { this.featureSchemaVersion = featureSchemaVersion; }
    public JsonNode getProfilesSnapshot() { return profilesSnapshot; }
    public void setProfilesSnapshot(JsonNode profilesSnapshot) { this.profilesSnapshot = profilesSnapshot; }
    public JsonNode getFeaturesSnapshot() { return featuresSnapshot; }
    public void setFeaturesSnapshot(JsonNode featuresSnapshot) { this.featuresSnapshot = featuresSnapshot; }
    public String getConsentReference() { return consentReference; }
    public void setConsentReference(String consentReference) { this.consentReference = consentReference; }
    public String getSourceReference() { return sourceReference; }
    public void setSourceReference(String sourceReference) { this.sourceReference = sourceReference; }
    public LocalDateTime getLabelledAt() { return labelledAt; }
    public void setLabelledAt(LocalDateTime labelledAt) { this.labelledAt = labelledAt; }
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
