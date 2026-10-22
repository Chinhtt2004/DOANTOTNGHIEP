package com.roomrental.service;

import com.roomrental.entity.LandlordVerification;
import com.roomrental.repository.LandlordVerificationRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class LandlordVerificationService extends BaseService<LandlordVerification> {
    public LandlordVerificationService(LandlordVerificationRepository repository, EntityManager entityManager) {
        super(repository, entityManager, LandlordVerification.class, false);
    }
}
