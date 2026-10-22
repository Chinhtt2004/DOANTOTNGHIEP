package com.roomrental.service;

import com.roomrental.entity.RoomRecommendation;
import com.roomrental.repository.RoomRecommendationRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoomRecommendationService extends BaseService<RoomRecommendation> {
    public RoomRecommendationService(RoomRecommendationRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoomRecommendation.class, false);
    }
}
