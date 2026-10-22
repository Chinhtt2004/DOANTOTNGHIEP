package com.roomrental.repository;

import com.roomrental.entity.FavoritePost;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FavoritePostRepository extends JpaRepository<FavoritePost, Long> {
}
