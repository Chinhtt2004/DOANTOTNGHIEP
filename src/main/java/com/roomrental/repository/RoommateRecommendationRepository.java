package com.roomrental.repository;

import com.roomrental.entity.RoommateRecommendation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoommateRecommendationRepository extends JpaRepository<RoommateRecommendation, Long> {
}
