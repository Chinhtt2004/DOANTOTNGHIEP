package com.roomrental.service;

import com.roomrental.entity.File;
import com.roomrental.repository.FileRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class FileService extends BaseService<File> {
    public FileService(FileRepository repository, EntityManager entityManager) {
        super(repository, entityManager, File.class, false);
    }
}
