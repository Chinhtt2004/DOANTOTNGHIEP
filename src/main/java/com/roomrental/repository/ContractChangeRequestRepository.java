package com.roomrental.repository;

import com.roomrental.entity.ContractChangeRequest;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContractChangeRequestRepository extends JpaRepository<ContractChangeRequest, Long> {
}
