package com.roomrental.service;

import com.roomrental.entity.FavoritePost;
import com.roomrental.repository.FavoritePostRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class FavoritePostService extends BaseService<FavoritePost> {
    public FavoritePostService(FavoritePostRepository repository, EntityManager entityManager) {
        super(repository, entityManager, FavoritePost.class, false);
    }
}
