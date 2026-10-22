package com.roomrental.service;

import com.roomrental.entity.RoomViewingRequest;
import com.roomrental.repository.RoomViewingRequestRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoomViewingRequestService extends BaseService<RoomViewingRequest> {
    public RoomViewingRequestService(RoomViewingRequestRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoomViewingRequest.class, false);
    }
}
