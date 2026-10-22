package com.roomrental.service;

import com.roomrental.entity.User;
import com.roomrental.repository.UserRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class UserService extends BaseService<User> {
    public UserService(UserRepository repository, EntityManager entityManager) {
        super(repository, entityManager, User.class, false);
    }
}
