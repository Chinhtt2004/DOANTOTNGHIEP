package com.roomrental.service;

import com.roomrental.entity.RentalHouse;
import com.roomrental.repository.RentalHouseRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RentalHouseService extends BaseService<RentalHouse> {
    public RentalHouseService(RentalHouseRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RentalHouse.class, false);
    }
}
