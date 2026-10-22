package com.roomrental.service;

import com.roomrental.entity.Contract;
import com.roomrental.repository.ContractRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ContractService extends BaseService<Contract> {
    public ContractService(ContractRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Contract.class, false);
    }
}
