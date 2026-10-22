package com.roomrental.service;

import com.roomrental.entity.ConversationParticipant;
import com.roomrental.repository.ConversationParticipantRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ConversationParticipantService extends BaseService<ConversationParticipant> {
    public ConversationParticipantService(ConversationParticipantRepository repository, EntityManager entityManager) {
        super(repository, entityManager, ConversationParticipant.class, false);
    }
}
