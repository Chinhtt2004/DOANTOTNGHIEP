package com.roomrental.service;

import com.roomrental.entity.ContractTemplate;
import com.roomrental.repository.ContractTemplateRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ContractTemplateService extends BaseService<ContractTemplate> {
    public ContractTemplateService(ContractTemplateRepository repository, EntityManager entityManager) {
        super(repository, entityManager, ContractTemplate.class, false);
    }
}
