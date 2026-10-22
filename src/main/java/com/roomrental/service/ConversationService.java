package com.roomrental.service;

import com.roomrental.entity.Conversation;
import com.roomrental.repository.ConversationRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ConversationService extends BaseService<Conversation> {
    public ConversationService(ConversationRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Conversation.class, false);
    }
}
