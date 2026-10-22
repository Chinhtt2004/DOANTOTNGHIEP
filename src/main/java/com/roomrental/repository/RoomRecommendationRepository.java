package com.roomrental.repository;

import com.roomrental.entity.RoomRecommendation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomRecommendationRepository extends JpaRepository<RoomRecommendation, Long> {
}
