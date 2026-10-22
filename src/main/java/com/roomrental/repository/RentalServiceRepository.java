package com.roomrental.repository;

import com.roomrental.entity.RentalService;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RentalServiceRepository extends JpaRepository<RentalService, Long> {
}
