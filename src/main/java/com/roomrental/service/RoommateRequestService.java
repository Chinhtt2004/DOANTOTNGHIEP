package com.roomrental.service;

import com.roomrental.entity.RoommateRequest;
import com.roomrental.repository.RoommateRequestRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoommateRequestService extends BaseService<RoommateRequest> {
    public RoommateRequestService(RoommateRequestRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoommateRequest.class, false);
    }
}
