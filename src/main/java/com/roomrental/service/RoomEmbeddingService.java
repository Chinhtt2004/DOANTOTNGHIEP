package com.roomrental.service;

import com.roomrental.entity.RoomEmbedding;
import com.roomrental.repository.RoomEmbeddingRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoomEmbeddingService extends BaseService<RoomEmbedding> {
    public RoomEmbeddingService(RoomEmbeddingRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoomEmbedding.class, false);
    }
}
