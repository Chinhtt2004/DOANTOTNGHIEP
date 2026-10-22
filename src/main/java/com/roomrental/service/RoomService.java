package com.roomrental.service;

import com.roomrental.entity.Room;
import com.roomrental.repository.RoomRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoomService extends BaseService<Room> {
    public RoomService(RoomRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Room.class, false);
    }
}
