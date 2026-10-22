package com.roomrental.repository;

import com.roomrental.entity.PersonalProfile;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PersonalProfileRepository extends JpaRepository<PersonalProfile, Long> {
}
