package com.roomrental.service;

import com.roomrental.entity.PostImage;
import com.roomrental.repository.PostImageRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class PostImageService extends BaseService<PostImage> {
    public PostImageService(PostImageRepository repository, EntityManager entityManager) {
        super(repository, entityManager, PostImage.class, false);
    }
}
