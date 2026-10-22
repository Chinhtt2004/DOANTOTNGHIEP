package com.roomrental.service;

import com.roomrental.entity.RoomTenant;
import com.roomrental.repository.RoomTenantRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoomTenantService extends BaseService<RoomTenant> {
    public RoomTenantService(RoomTenantRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoomTenant.class, false);
    }
}
