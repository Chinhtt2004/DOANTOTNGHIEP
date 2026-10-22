package com.roomrental.service;

import com.roomrental.entity.Post;
import com.roomrental.repository.PostRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class PostService extends BaseService<Post> {
    public PostService(PostRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Post.class, false);
    }
}
