package com.roomrental.service;

import com.roomrental.entity.ChatMessage;
import com.roomrental.repository.ChatMessageRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ChatMessageService extends BaseService<ChatMessage> {
    public ChatMessageService(ChatMessageRepository repository, EntityManager entityManager) {
        super(repository, entityManager, ChatMessage.class, false);
    }
}
