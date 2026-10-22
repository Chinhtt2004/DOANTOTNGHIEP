package com.roomrental.service;

import com.roomrental.entity.Report;
import com.roomrental.repository.ReportRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class ReportService extends BaseService<Report> {
    public ReportService(ReportRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Report.class, false);
    }
}
