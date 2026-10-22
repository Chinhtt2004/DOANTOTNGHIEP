package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps personal_profiles. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "personal_profiles")
public class PersonalProfile implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`user_id`", nullable = false)
    private Long userId;
    @Column(name = "`avatar_file_id`", nullable = true)
    private Long avatarFileId;
    @Column(name = "`address`", nullable = true, length = 500)
    private String address;
    @Column(name = "`gender`", nullable = true, length = 30)
    private String gender;
    @Column(name = "`occupation`", nullable = true, length = 150)
    private String occupation;
    @Column(name = "`university`", nullable = true, length = 200)
    private String university;
    @Column(name = "`bio`", nullable = true, columnDefinition = "TEXT")
    private String bio;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getAvatarFileId() { return avatarFileId; }
    public void setAvatarFileId(Long avatarFileId) { this.avatarFileId = avatarFileId; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    public String getOccupation() { return occupation; }
    public void setOccupation(String occupation) { this.occupation = occupation; }
    public String getUniversity() { return university; }
    public void setUniversity(String university) { this.university = university; }
    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }
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
