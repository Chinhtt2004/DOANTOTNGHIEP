package com.roomrental.service;

import com.roomrental.entity.ModerationAction;
import com.roomrental.repository.ModerationActionRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ModerationActionService extends BaseService<ModerationAction> {
    public ModerationActionService(ModerationActionRepository repository, EntityManager entityManager) {
        super(repository, entityManager, ModerationAction.class, false);
    }
}
