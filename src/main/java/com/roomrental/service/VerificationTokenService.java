package com.roomrental.service;

import com.roomrental.entity.VerificationToken;
import com.roomrental.repository.VerificationTokenRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class VerificationTokenService extends BaseService<VerificationToken> {
    public VerificationTokenService(VerificationTokenRepository repository, EntityManager entityManager) {
        super(repository, entityManager, VerificationToken.class, false);
    }
}
