package com.roomrental.service;

import com.roomrental.entity.RentalService;
import com.roomrental.repository.RentalServiceRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RentalServiceService extends BaseService<RentalService> {
    public RentalServiceService(RentalServiceRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RentalService.class, false);
    }
}
