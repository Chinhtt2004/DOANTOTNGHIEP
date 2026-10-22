package com.roomrental.service;

import com.roomrental.entity.AuthSession;
import com.roomrental.repository.AuthSessionRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class AuthSessionService extends BaseService<AuthSession> {
    public AuthSessionService(AuthSessionRepository repository, EntityManager entityManager) {
        super(repository, entityManager, AuthSession.class, false);
    }
}
