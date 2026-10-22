package com.roomrental.service;

import com.roomrental.entity.TenantIdentityVerification;
import com.roomrental.repository.TenantIdentityVerificationRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class TenantIdentityVerificationService extends BaseService<TenantIdentityVerification> {
    public TenantIdentityVerificationService(TenantIdentityVerificationRepository repository, EntityManager entityManager) {
        super(repository, entityManager, TenantIdentityVerification.class, false);
    }
}
