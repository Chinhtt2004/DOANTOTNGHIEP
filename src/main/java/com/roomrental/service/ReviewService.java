package com.roomrental.service;

import com.roomrental.entity.Review;
import com.roomrental.repository.ReviewRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ReviewService extends BaseService<Review> {
    public ReviewService(ReviewRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Review.class, false);
    }
}
