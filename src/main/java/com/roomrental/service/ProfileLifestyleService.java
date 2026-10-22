package com.roomrental.service;

import com.roomrental.entity.ProfileLifestyle;
import com.roomrental.repository.ProfileLifestyleRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ProfileLifestyleService extends BaseService<ProfileLifestyle> {
    public ProfileLifestyleService(ProfileLifestyleRepository repository, EntityManager entityManager) {
        super(repository, entityManager, ProfileLifestyle.class, false);
    }
}
