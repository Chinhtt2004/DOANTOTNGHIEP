package com.roomrental.service;

import com.roomrental.entity.PostAmenity;
import com.roomrental.repository.PostAmenityRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class PostAmenityService extends BaseService<PostAmenity> {
    public PostAmenityService(PostAmenityRepository repository, EntityManager entityManager) {
        super(repository, entityManager, PostAmenity.class, false);
    }
}
