package com.roomrental.service;

import com.roomrental.entity.RoommateTrainingPair;
import com.roomrental.repository.RoommateTrainingPairRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoommateTrainingPairService extends BaseService<RoommateTrainingPair> {
    public RoommateTrainingPairService(RoommateTrainingPairRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoommateTrainingPair.class, false);
    }
}
