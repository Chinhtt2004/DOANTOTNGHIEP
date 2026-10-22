package com.roomrental.service;

import com.roomrental.entity.PersonalProfile;
import com.roomrental.repository.PersonalProfileRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class PersonalProfileService extends BaseService<PersonalProfile> {
    public PersonalProfileService(PersonalProfileRepository repository, EntityManager entityManager) {
        super(repository, entityManager, PersonalProfile.class, false);
    }
}
