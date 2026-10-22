package com.roomrental.repository;

import com.roomrental.entity.RoommateRequest;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoommateRequestRepository extends JpaRepository<RoommateRequest, Long> {
}
