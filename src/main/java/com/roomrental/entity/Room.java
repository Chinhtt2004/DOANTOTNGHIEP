package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps rooms. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "rooms")
public class Room implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`house_id`", nullable = false)
    private Long houseId;
    @Column(name = "`room_number`", nullable = false, length = 100)
    private String roomNumber;
    @Column(name = "`area`", nullable = false, precision = 10, scale = 2)
    private BigDecimal area;
    @Column(name = "`rent_price`", nullable = false, precision = 15, scale = 2)
    private BigDecimal rentPrice = new BigDecimal("0");
    @Column(name = "`deposit_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal depositAmount = new BigDecimal("0");
    @Column(name = "`max_occupants`", nullable = false)
    private Integer maxOccupants;
    @Column(name = "`allow_additional_occupants`", nullable = false)
    private Boolean allowAdditionalOccupants = false;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "AVAILABLE";
    @Column(name = "`notes`", nullable = true, length = 2000)
    private String notes;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getHouseId() { return houseId; }
    public void setHouseId(Long houseId) { this.houseId = houseId; }
    public String getRoomNumber() { return roomNumber; }
    public void setRoomNumber(String roomNumber) { this.roomNumber = roomNumber; }
    public BigDecimal getArea() { return area; }
    public void setArea(BigDecimal area) { this.area = area; }
    public BigDecimal getRentPrice() { return rentPrice; }
    public void setRentPrice(BigDecimal rentPrice) { this.rentPrice = rentPrice; }
    public BigDecimal getDepositAmount() { return depositAmount; }
    public void setDepositAmount(BigDecimal depositAmount) { this.depositAmount = depositAmount; }
    public Integer getMaxOccupants() { return maxOccupants; }
    public void setMaxOccupants(Integer maxOccupants) { this.maxOccupants = maxOccupants; }
    public Boolean getAllowAdditionalOccupants() { return allowAdditionalOccupants; }
    public void setAllowAdditionalOccupants(Boolean allowAdditionalOccupants) { this.allowAdditionalOccupants = allowAdditionalOccupants; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
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
