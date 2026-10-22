package com.roomrental.service;

import com.roomrental.entity.LifestyleCriterion;
import com.roomrental.repository.LifestyleCriterionRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class LifestyleCriterionService extends BaseService<LifestyleCriterion> {
    public LifestyleCriterionService(LifestyleCriterionRepository repository, EntityManager entityManager) {
        super(repository, entityManager, LifestyleCriterion.class, false);
    }
}
