package com.roomrental.service;

import com.roomrental.entity.ContractChangeRequest;
import com.roomrental.repository.ContractChangeRequestRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ContractChangeRequestService extends BaseService<ContractChangeRequest> {
    public ContractChangeRequestService(ContractChangeRequestRepository repository, EntityManager entityManager) {
        super(repository, entityManager, ContractChangeRequest.class, false);
    }
}
