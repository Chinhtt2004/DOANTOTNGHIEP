package com.roomrental.service;

import com.roomrental.entity.RoommateRecommendation;
import com.roomrental.repository.RoommateRecommendationRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoommateRecommendationService extends BaseService<RoommateRecommendation> {
    public RoommateRecommendationService(RoommateRecommendationRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoommateRecommendation.class, false);
    }
}
