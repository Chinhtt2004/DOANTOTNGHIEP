package com.roomrental.repository;

import com.roomrental.entity.RentalHouse;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RentalHouseRepository extends JpaRepository<RentalHouse, Long> {
}
