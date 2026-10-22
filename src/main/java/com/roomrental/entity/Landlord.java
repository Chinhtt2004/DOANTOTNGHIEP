package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps landlords. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "landlords")
public class Landlord implements IdentifiedEntity {
    @Id
    @Column(name = "`id`", nullable = false)
    private Long id;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
}
