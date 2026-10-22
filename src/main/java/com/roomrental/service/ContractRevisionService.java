package com.roomrental.service;

import com.roomrental.entity.ContractRevision;
import com.roomrental.repository.ContractRevisionRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ContractRevisionService extends BaseService<ContractRevision> {
    public ContractRevisionService(ContractRevisionRepository repository, EntityManager entityManager) {
        super(repository, entityManager, ContractRevision.class, false);
    }
}
