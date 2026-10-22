package com.roomrental.repository;

import com.roomrental.entity.RoomTenant;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomTenantRepository extends JpaRepository<RoomTenant, Long> {
}
