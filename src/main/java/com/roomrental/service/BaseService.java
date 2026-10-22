package com.roomrental.service;

import com.roomrental.entity.IdentifiedEntity;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityNotFoundException;
import java.util.Objects;
import java.util.function.Consumer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

@Transactional(readOnly = true)
public abstract class BaseService<T extends IdentifiedEntity> {
    private final JpaRepository<T, Long> repository;
    private final EntityManager entityManager;
    private final Class<T> entityType;
    private final boolean assignedId;

    protected BaseService(JpaRepository<T, Long> repository, EntityManager entityManager,
                          Class<T> entityType, boolean assignedId) {
        this.repository = repository;
        this.entityManager = entityManager;
        this.entityType = entityType;
        this.assignedId = assignedId;
    }

    public Page<T> findAll(Pageable pageable) {
        return repository.findAll(Objects.requireNonNull(pageable));
    }

    public T findById(Long id) {
        return repository.findById(Objects.requireNonNull(id))
                .orElseThrow(() -> new EntityNotFoundException(entityType.getSimpleName() + " #" + id));
    }

    @Transactional
    public T create(T entity) {
        Objects.requireNonNull(entity);
        if (assignedId && entity.getId() == null) {
            throw new IllegalArgumentException("Role ID must be an existing user's ID");
        }
        if (!assignedId && entity.getId() != null) {
            throw new IllegalArgumentException("New entity must not supply an auto-generated ID");
        }
        // persist (rather than merge) also prevents overwriting an existing assigned role ID.
        entityManager.persist(entity);
        entityManager.flush();
        entityManager.refresh(entity);
        return entity;
    }

    @Transactional
    public T update(Long id, Consumer<T> changes) {
        T entity = findById(id);
        Objects.requireNonNull(changes).accept(entity);
        if (!Objects.equals(id, entity.getId())) {
            throw new IllegalArgumentException("Cannot change an entity's ID");
        }
        entityManager.flush();
        entityManager.refresh(entity);
        return entity;
    }

    /** Physical deletion; callers must enforce domain retention rules. FK restrictions still apply. */
    @Transactional
    public void deleteById(Long id) {
        repository.delete(findById(id));
        repository.flush();
    }
}
