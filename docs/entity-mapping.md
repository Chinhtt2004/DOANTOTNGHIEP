# Ánh xạ schema

Khóa ngoại giữ dưới dạng ID, kể cả khóa ngoại ghép. MySQL kiểm tra các ràng buộc từ schema gốc. Các cột generated chỉ đọc.

| Bảng | Entity | Số cột |
| --- | --- | --- |
| `users` | `User` | 16 |
| `tenants` | `Tenant` | 1 |
| `landlords` | `Landlord` | 1 |
| `admins` | `Admin` | 1 |
| `personal_profiles` | `PersonalProfile` | 10 |
| `files` | `File` | 17 |
| `landlord_verifications` | `LandlordVerification` | 11 |
| `tenant_identity_verifications` | `TenantIdentityVerification` | 12 |
| `auth_sessions` | `AuthSession` | 10 |
| `verification_tokens` | `VerificationToken` | 14 |
| `rental_houses` | `RentalHouse` | 8 |
| `rooms` | `Room` | 12 |
| `rental_services` | `RentalService` | 6 |
| `room_services` | `RoomService` | 7 |
| `posts` | `Post` | 20 |
| `post_images` | `PostImage` | 7 |
| `post_amenities` | `PostAmenity` | 5 |
| `favorite_posts` | `FavoritePost` | 5 |
| `room_viewing_requests` | `RoomViewingRequest` | 18 |
| `contract_templates` | `ContractTemplate` | 8 |
| `contracts` | `Contract` | 22 |
| `room_tenants` | `RoomTenant` | 24 |
| `contract_revisions` | `ContractRevision` | 26 |
| `contract_change_requests` | `ContractChangeRequest` | 24 |
| `occupant_join_requests` | `OccupantJoinRequest` | 20 |
| `roommate_profiles` | `RoommateProfile` | 15 |
| `lifestyle_criteria` | `LifestyleCriterion` | 9 |
| `profile_lifestyles` | `ProfileLifestyle` | 9 |
| `roommate_requests` | `RoommateRequest` | 15 |
| `ai_model_versions` | `AiModelVersion` | 20 |
| `room_embeddings` | `RoomEmbedding` | 14 |
| `room_recommendations` | `RoomRecommendation` | 16 |
| `roommate_recommendations` | `RoommateRecommendation` | 20 |
| `roommate_training_pairs` | `RoommateTrainingPair` | 16 |
| `invoices` | `Invoice` | 33 |
| `reviews` | `Review` | 13 |
| `conversations` | `Conversation` | 8 |
| `conversation_participants` | `ConversationParticipant` | 11 |
| `chat_messages` | `ChatMessage` | 9 |
| `notifications` | `Notification` | 12 |
| `reports` | `Report` | 14 |
| `moderation_actions` | `ModerationAction` | 15 |
