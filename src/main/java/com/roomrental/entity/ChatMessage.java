package com.roomrental.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import com.fasterxml.jackson.databind.JsonNode;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Maps chat_messages. Foreign keys remain explicit IDs; constraints live in schema.mysql.sql. */
@Entity
@Table(name = "chat_messages")
public class ChatMessage implements IdentifiedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`id`", nullable = false)
    private Long id;
    @Column(name = "`conversation_id`", nullable = false)
    private Long conversationId;
    @Column(name = "`sender_id`", nullable = false)
    private Long senderId;
    @Column(name = "`client_message_key`", nullable = false, length = 36, columnDefinition = "CHAR(36)")
    private String clientMessageKey;
    @Column(name = "`message_type`", nullable = false, length = 40)
    private String messageType = "TEXT";
    @Column(name = "`content`", nullable = true, columnDefinition = "TEXT")
    private String content;
    @Column(name = "`sent_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime sentAt;
    @Column(name = "`created_at`", nullable = false, columnDefinition = "DATETIME(6)", updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "`updated_at`", nullable = false, columnDefinition = "DATETIME(6)")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getConversationId() { return conversationId; }
    public void setConversationId(Long conversationId) { this.conversationId = conversationId; }
    public Long getSenderId() { return senderId; }
    public void setSenderId(Long senderId) { this.senderId = senderId; }
    public String getClientMessageKey() { return clientMessageKey; }
    public void setClientMessageKey(String clientMessageKey) { this.clientMessageKey = clientMessageKey; }
    public String getMessageType() { return messageType; }
    public void setMessageType(String messageType) { this.messageType = messageType; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public LocalDateTime getSentAt() { return sentAt; }
    public void setSentAt(LocalDateTime sentAt) { this.sentAt = sentAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now(ZoneOffset.UTC);
    }
}
