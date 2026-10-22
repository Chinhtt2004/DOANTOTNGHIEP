package com.roomrental.service;

import com.roomrental.entity.AiModelVersion;
import com.roomrental.repository.AiModelVersionRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class AiModelVersionService extends BaseService<AiModelVersion> {
    public AiModelVersionService(AiModelVersionRepository repository, EntityManager entityManager) {
        super(repository, entityManager, AiModelVersion.class, false);
    }
}
