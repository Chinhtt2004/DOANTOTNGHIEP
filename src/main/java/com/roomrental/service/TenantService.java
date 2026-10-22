package com.roomrental.service;

import com.roomrental.entity.Tenant;
import com.roomrental.repository.TenantRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class TenantService extends BaseService<Tenant> {
    public TenantService(TenantRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Tenant.class, true);
    }
}
