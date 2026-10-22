package com.roomrental.repository;

import com.roomrental.entity.TenantIdentityVerification;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantIdentityVerificationRepository extends JpaRepository<TenantIdentityVerification, Long> {
}
