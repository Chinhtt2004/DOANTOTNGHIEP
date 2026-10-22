package com.roomrental.service;

import com.roomrental.entity.Notification;
import com.roomrental.repository.NotificationRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

/** Persistence operations only; add authorization and domain workflows before exposing an API. */
@Service
public class NotificationService extends BaseService<Notification> {
    public NotificationService(NotificationRepository repository, EntityManager entityManager) {
        super(repository, entityManager, Notification.class, false);
    }
}
