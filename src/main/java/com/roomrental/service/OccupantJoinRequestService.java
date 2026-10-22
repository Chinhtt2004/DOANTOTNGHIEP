package com.roomrental.service;

import com.roomrental.entity.OccupantJoinRequest;
import com.roomrental.repository.OccupantJoinRequestRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class OccupantJoinRequestService extends BaseService<OccupantJoinRequest> {
    public OccupantJoinRequestService(OccupantJoinRequestRepository repository, EntityManager entityManager) {
        super(repository, entityManager, OccupantJoinRequest.class, false);
    }
}
