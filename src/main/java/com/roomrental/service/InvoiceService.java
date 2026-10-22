package com.roomrental.service;

import com.roomrental.entity.Invoice;
import com.roomrental.repository.InvoiceRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class InvoiceService extends BaseService<Invoice> {
    public InvoiceService(InvoiceRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Invoice.class, false);
    }
}
