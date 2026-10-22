package com.roomrental.service;

import com.roomrental.entity.Landlord;
import com.roomrental.repository.LandlordRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class LandlordService extends BaseService<Landlord> {
    public LandlordService(LandlordRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Landlord.class, true);
    }
}
