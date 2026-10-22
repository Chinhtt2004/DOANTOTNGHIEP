package com.roomrental.repository;

import com.roomrental.entity.RoomService;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomServiceRepository extends JpaRepository<RoomService, Long> {
}
