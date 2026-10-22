package com.roomrental.service;

import com.roomrental.entity.Admin;
import com.roomrental.repository.AdminRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class AdminService extends BaseService<Admin> {
    public AdminService(AdminRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Admin.class, true);
    }
}
