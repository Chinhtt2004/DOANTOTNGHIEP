package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps invoices. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "invoices")
public class Invoice implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`contract_id`", nullable = false)
    private Long contractId;
    @Column(name = "`contract_revision_id`", nullable = false)
    private Long contractRevisionId;
    @Column(name = "`payer_room_tenant_id`", nullable = false)
    private Long payerRoomTenantId;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`payer_snapshot`", nullable = false, columnDefinition = "JSON")
    private JsonNode payerSnapshot;
    @Column(name = "`billing_period`", nullable = false)
    private LocalDate billingPeriod;
    @Column(name = "`due_date`", nullable = false)
    private LocalDate dueDate;
    @Column(name = "`rent_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal rentAmount = new BigDecimal("0");
    @Column(name = "`electricity_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal electricityAmount = new BigDecimal("0");
    @Column(name = "`water_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal waterAmount = new BigDecimal("0");
    @Column(name = "`service_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal serviceAmount = new BigDecimal("0");
    @Column(name = "`other_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal otherAmount = new BigDecimal("0");
    @Column(name = "`discount_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal discountAmount = new BigDecimal("0");
    @Column(name = "`total_amount`", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalAmount = new BigDecimal("0");
    @Column(name = "`electricity_old_reading`", nullable = true, precision = 12, scale = 3)
    private BigDecimal electricityOldReading;
    @Column(name = "`electricity_new_reading`", nullable = true, precision = 12, scale = 3)
    private BigDecimal electricityNewReading;
    @Column(name = "`electricity_unit_price`", nullable = true, precision = 15, scale = 2)
    private BigDecimal electricityUnitPrice;
    @Column(name = "`water_old_reading`", nullable = true, precision = 12, scale = 3)
    private BigDecimal waterOldReading;
    @Column(name = "`water_new_reading`", nullable = true, precision = 12, scale = 3)
    private BigDecimal waterNewReading;
    @Column(name = "`water_unit_price`", nullable = true, precision = 15, scale = 2)
    private BigDecimal waterUnitPrice;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "`service_details`", nullable = false, columnDefinition = "JSON")
    private JsonNode serviceDetails;
    @Column(name = "`occupant_count_at_billing`", nullable = false)
    private Integer occupantCountAtBilling;
    @Column(name = "`status`", nullable = false, length = 40)
    private String status = "UNPAID";
    @Column(name = "`created_by_id`", nullable = false)
    private Long createdById;
    @Column(name = "`paid_by_id`", nullable = true)
    private Long paidById;
    @Column(name = "`cancelled_by_id`", nullable = true)
    private Long cancelledById;
    @Column(name = "`cancellation_reason`", nullable = true, length = 1000)
    private String cancellationReason;
    @Column(name = "`replacement_of_id`", nullable = true)
    private Long replacementOfId;
    @Column(name = "`paid_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime paidAt;
    @Column(name = "`cancelled_at`", nullable = true, columnDefinition = "DATETIME(6)")
    private LocalDateTime cancelledAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;
    @Column(name = "`open_period_key`", nullable = true, insertable = false, updatable = false)
    private Integer openPeriodKey;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Long getContractRevisionId() { return contractRevisionId; }
    public void setContractRevisionId(Long contractRevisionId) { this.contractRevisionId = contractRevisionId; }
    public Long getPayerRoomTenantId() { return payerRoomTenantId; }
    public void setPayerRoomTenantId(Long payerRoomTenantId) { this.payerRoomTenantId = payerRoomTenantId; }
    public JsonNode getPayerSnapshot() { return payerSnapshot; }
    public void setPayerSnapshot(JsonNode payerSnapshot) { this.payerSnapshot = payerSnapshot; }
    public LocalDate getBillingPeriod() { return billingPeriod; }
    public void setBillingPeriod(LocalDate billingPeriod) { this.billingPeriod = billingPeriod; }
    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }
    public BigDecimal getRentAmount() { return rentAmount; }
    public void setRentAmount(BigDecimal rentAmount) { this.rentAmount = rentAmount; }
    public BigDecimal getElectricityAmount() { return electricityAmount; }
    public void setElectricityAmount(BigDecimal electricityAmount) { this.electricityAmount = electricityAmount; }
    public BigDecimal getWaterAmount() { return waterAmount; }
    public void setWaterAmount(BigDecimal waterAmount) { this.waterAmount = waterAmount; }
    public BigDecimal getServiceAmount() { return serviceAmount; }
    public void setServiceAmount(BigDecimal serviceAmount) { this.serviceAmount = serviceAmount; }
    public BigDecimal getOtherAmount() { return otherAmount; }
    public void setOtherAmount(BigDecimal otherAmount) { this.otherAmount = otherAmount; }
    public BigDecimal getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(BigDecimal discountAmount) { this.discountAmount = discountAmount; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
    public BigDecimal getElectricityOldReading() { return electricityOldReading; }
    public void setElectricityOldReading(BigDecimal electricityOldReading) { this.electricityOldReading = electricityOldReading; }
    public BigDecimal getElectricityNewReading() { return electricityNewReading; }
    public void setElectricityNewReading(BigDecimal electricityNewReading) { this.electricityNewReading = electricityNewReading; }
    public BigDecimal getElectricityUnitPrice() { return electricityUnitPrice; }
    public void setElectricityUnitPrice(BigDecimal electricityUnitPrice) { this.electricityUnitPrice = electricityUnitPrice; }
    public BigDecimal getWaterOldReading() { return waterOldReading; }
    public void setWaterOldReading(BigDecimal waterOldReading) { this.waterOldReading = waterOldReading; }
    public BigDecimal getWaterNewReading() { return waterNewReading; }
    public void setWaterNewReading(BigDecimal waterNewReading) { this.waterNewReading = waterNewReading; }
    public BigDecimal getWaterUnitPrice() { return waterUnitPrice; }
    public void setWaterUnitPrice(BigDecimal waterUnitPrice) { this.waterUnitPrice = waterUnitPrice; }
    public JsonNode getServiceDetails() { return serviceDetails; }
    public void setServiceDetails(JsonNode serviceDetails) { this.serviceDetails = serviceDetails; }
    public Integer getOccupantCountAtBilling() { return occupantCountAtBilling; }
    public void setOccupantCountAtBilling(Integer occupantCountAtBilling) { this.occupantCountAtBilling = occupantCountAtBilling; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Long getCreatedById() { return createdById; }
    public void setCreatedById(Long createdById) { this.createdById = createdById; }
    public Long getPaidById() { return paidById; }
    public void setPaidById(Long paidById) { this.paidById = paidById; }
    public Long getCancelledById() { return cancelledById; }
    public void setCancelledById(Long cancelledById) { this.cancelledById = cancelledById; }
    public String getCancellationReason() { return cancellationReason; }
    public void setCancellationReason(String cancellationReason) { this.cancellationReason = cancellationReason; }
    public Long getReplacementOfId() { return replacementOfId; }
    public void setReplacementOfId(Long replacementOfId) { this.replacementOfId = replacementOfId; }
    public LocalDateTime getPaidAt() { return paidAt; }
    public void setPaidAt(LocalDateTime paidAt) { this.paidAt = paidAt; }
    public LocalDateTime getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(LocalDateTime cancelledAt) { this.cancelledAt = cancelledAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Integer getOpenPeriodKey() { return openPeriodKey; }

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
