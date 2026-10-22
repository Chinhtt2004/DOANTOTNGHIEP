package com.roomrental.repository;

import com.roomrental.entity.RoommateProfile;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoommateProfileRepository extends JpaRepository<RoommateProfile, Long> {
}
