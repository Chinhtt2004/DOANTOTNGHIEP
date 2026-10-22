package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps profile_lifestyles. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "profile_lifestyles")
public class ProfileLifestyle implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`profile_id`", nullable = false)
    private Long profileId;
    @Column(name = "`criterion_id`", nullable = false)
    private Long criterionId;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`self_value`", nullable = true, columnDefinition = "JSON")
    private JsonNode selfValue;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`preferred_value`", nullable = true, columnDefinition = "JSON")
    private JsonNode preferredValue;
    @Column(name = "`is_mandatory`", nullable = false)
    private Boolean isMandatory = false;
    @Column(name = "`importance`", nullable = false)
    private Integer importance = 1;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getProfileId() { return profileId; }
    public void setProfileId(Long profileId) { this.profileId = profileId; }
    public Long getCriterionId() { return criterionId; }
    public void setCriterionId(Long criterionId) { this.criterionId = criterionId; }
    public JsonNode getSelfValue() { return selfValue; }
    public void setSelfValue(JsonNode selfValue) { this.selfValue = selfValue; }
    public JsonNode getPreferredValue() { return preferredValue; }
    public void setPreferredValue(JsonNode preferredValue) { this.preferredValue = preferredValue; }
    public Boolean getIsMandatory() { return isMandatory; }
    public void setIsMandatory(Boolean isMandatory) { this.isMandatory = isMandatory; }
    public Integer getImportance() { return importance; }
    public void setImportance(Integer importance) { this.importance = importance; }
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
