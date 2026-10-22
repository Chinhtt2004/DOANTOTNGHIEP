package com.roomrental.service;

import com.roomrental.entity.RoommateProfile;
import com.roomrental.repository.RoommateProfileRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class RoommateProfileService extends BaseService<RoommateProfile> {
    public RoommateProfileService(RoommateProfileRepository repository, EntityManager entityManager) {
        super(repository, entityManager, RoommateProfile.class, false);
    }
}
