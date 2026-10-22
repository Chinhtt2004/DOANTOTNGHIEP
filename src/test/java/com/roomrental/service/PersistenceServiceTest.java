package com.roomrental.service;

import com.roomrental.entity.Room;
import com.roomrental.entity.Tenant;
import com.roomrental.repository.RoomRepository;
import com.roomrental.repository.TenantRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityNotFoundException;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PersistenceServiceTest {
    private final EntityManager em = mock(EntityManager.class);
    private final RoomRepository rooms = mock(RoomRepository.class);
    private final RoomService service = new RoomService(rooms, em);

    @Test
    void createRejectsClientSuppliedGeneratedId() {
        Room room = new Room();
        room.setId(7L);
        assertThrows(IllegalArgumentException.class, () -> service.create(room));
        verifyNoInteractions(em);
    }

    @Test
    void roleCreationRequiresUserIdAndUsesPersistRatherThanMerge() {
        TenantService tenants = new TenantService(mock(TenantRepository.class), em);
        Tenant tenant = new Tenant();
        assertThrows(IllegalArgumentException.class, () -> tenants.create(tenant));
        tenant.setId(9L);
        assertSame(tenant, tenants.create(tenant));
        verify(em).persist(tenant);
        verify(em).flush();
        verify(em).refresh(tenant);
        verify(em, never()).merge(any());
    }

    @Test
    void updateChangesManagedRecordAndRefreshesGeneratedColumns() {
        Room room = new Room();
        room.setId(5L);
        when(rooms.findById(5L)).thenReturn(Optional.of(room));
        assertSame(room, service.update(5L, current -> current.setNotes("updated")));
        assertEquals("updated", room.getNotes());
        verify(em).flush();
        verify(em).refresh(room);
    }

    @Test
    void updateRejectsIdentityChangeBeforeFlush() {
        Room room = new Room();
        room.setId(5L);
        when(rooms.findById(5L)).thenReturn(Optional.of(room));
        assertThrows(IllegalArgumentException.class,
                () -> service.update(5L, current -> current.setId(6L)));
        verifyNoInteractions(em);
    }

    @Test
    void deletingMissingRecordFailsExplicitly() {
        when(rooms.findById(99L)).thenReturn(Optional.empty());
        assertThrows(EntityNotFoundException.class, () -> service.deleteById(99L));
        verify(rooms, never()).delete(any());
    }
}
