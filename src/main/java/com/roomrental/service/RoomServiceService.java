package com.roomrental.service;

import com.roomrental.entity.RoomService;
import com.roomrental.repository.RoomServiceRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoomServiceService extends BaseService<RoomService> {
    public RoomServiceService(RoomServiceRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoomService.class, false);
    }
}
