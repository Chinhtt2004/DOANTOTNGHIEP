package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps roommate_profiles. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "roommate_profiles")
public class RoommateProfile implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`tenant_id`", nullable = false)
    private Long tenantId;
    @Column(name = "`housing_status`", nullable = false, length = 40)
    private String housingStatus;
    @Column(name = "`current_room_tenant_id`", nullable = true)
    private Long currentRoomTenantId;
    @Column(name = "`external_context`", nullable = true, length = 1000)
    private String externalContext;
    @Column(name = "`available_from`", nullable = false)
    private LocalDate availableFrom;
    @Column(name = "`budget_min`", nullable = true, precision = 15, scale = 2)
    private BigDecimal budgetMin;
    @Column(name = "`budget_max`", nullable = true, precision = 15, scale = 2)
    private BigDecimal budgetMax;
    @Column(name = "`preferred_location`", nullable = true, length = 500)
    private String preferredLocation;
    @Column(name = "`preferred_gender`", nullable = true, length = 30)
    private String preferredGender;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`requirements_snapshot`", nullable = true, columnDefinition = "JSON")
    private JsonNode requirementsSnapshot;
    @Column(name = "`profile_version`", nullable = false)
    private Long profileVersion = 1L;
    @Column(name = "`active`", nullable = false)
    private Boolean active = false;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }
    public String getHousingStatus() { return housingStatus; }
    public void setHousingStatus(String housingStatus) { this.housingStatus = housingStatus; }
    public Long getCurrentRoomTenantId() { return currentRoomTenantId; }
    public void setCurrentRoomTenantId(Long currentRoomTenantId) { this.currentRoomTenantId = currentRoomTenantId; }
    public String getExternalContext() { return externalContext; }
    public void setExternalContext(String externalContext) { this.externalContext = externalContext; }
    public LocalDate getAvailableFrom() { return availableFrom; }
    public void setAvailableFrom(LocalDate availableFrom) { this.availableFrom = availableFrom; }
    public BigDecimal getBudgetMin() { return budgetMin; }
    public void setBudgetMin(BigDecimal budgetMin) { this.budgetMin = budgetMin; }
    public BigDecimal getBudgetMax() { return budgetMax; }
    public void setBudgetMax(BigDecimal budgetMax) { this.budgetMax = budgetMax; }
    public String getPreferredLocation() { return preferredLocation; }
    public void setPreferredLocation(String preferredLocation) { this.preferredLocation = preferredLocation; }
    public String getPreferredGender() { return preferredGender; }
    public void setPreferredGender(String preferredGender) { this.preferredGender = preferredGender; }
    public JsonNode getRequirementsSnapshot() { return requirementsSnapshot; }
    public void setRequirementsSnapshot(JsonNode requirementsSnapshot) { this.requirementsSnapshot = requirementsSnapshot; }
    public Long getProfileVersion() { return profileVersion; }
    public void setProfileVersion(Long profileVersion) { this.profileVersion = profileVersion; }
    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }
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
