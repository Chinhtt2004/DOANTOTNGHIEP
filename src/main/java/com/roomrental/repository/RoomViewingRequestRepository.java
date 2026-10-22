package com.roomrental.repository;

import com.roomrental.entity.RoomViewingRequest;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomViewingRequestRepository extends JpaRepository<RoomViewingRequest, Long> {
}
