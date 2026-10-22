# Room Rental Backend

Spring Boot 3.5, Java 17+, Maven, MySQL. Package gốc: `com.roomrental`.

## Nội dung

- 42 entity tương ứng 42 bảng trong `schema.mysql.sql`, 42 repository và 42 service.
- Mỗi service kế thừa `BaseService`: `findAll(Pageable)`, `findById`, `create`, `update(id, Consumer<T>)`, `deleteById`.
- Decimal dùng `BigDecimal`, JSON dùng `JsonNode`, DATE dùng `LocalDate`, DATETIME dùng `LocalDateTime` theo UTC.
- Giá trị DEFAULT tĩnh được khởi tạo trong Java. `created_at` và `updated_at` do JPA lifecycle cập nhật.
- Cột GENERATED ALWAYS không có setter và không được ghi bởi Hibernate; service refresh sau khi ghi để lấy giá trị mới.
- Tenant/Landlord/Admin dùng ID được cấp từ User; không dùng kế thừa loại trừ vai trò.

## Chạy

1. Cài JDK 17 trở lên, cấu hình `JAVA_HOME` trỏ đến JDK và cài Maven.
2. Import `schema.mysql.sql` **một lần vào database mới**, đúng hướng dẫn ở đầu file. Script có CREATE DATABASE; không chạy lại trên database đã tồn tại.
3. Cấu hình biến môi trường `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`. URL mặc định trỏ đến database `room_rental_v2_20261015` trên localhost:3306, kết nối UTC.
4. Chạy `mvn test` rồi `mvn spring-boot:run`.

Trên máy hiện tại, Java trên PATH đang lỗi. Có thể chọn JDK 17 đã cài trong PowerShell trước khi chạy Maven:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-17'
mvn test
```

Hibernate dùng `ddl-auto: validate`, SQL init tắt. Ứng dụng này là nền persistence chưa có HTTP controller; khi chạy nó khởi tạo context và kiểm tra kết nối/schema.

## Sử dụng service

```java
Room room = new Room();
room.setHouseId(houseId);
room.setRoomNumber("101");
room.setArea(new BigDecimal("25.00"));
room.setMaxOccupants(2);
Room saved = roomService.create(room);

roomService.update(saved.getId(), existing -> existing.setNotes("Có ban công"));
Page<Room> rooms = roomService.findAll(PageRequest.of(0, 20));
```

## Phạm vi và cách chia việc

Đây là service thao tác persistence, chưa triển khai các luồng nghiệp vụ như xác nhận hợp đồng, chuyển trạng thái hóa đơn, xác minh chủ trọ, phân quyền, gửi OTP hoặc AI. Không lấy entity làm response trực tiếp vì có dữ liệu riêng tư/token/hash. Thêm DTO và kiểm tra quyền ở tầng nghiệp vụ trước khi tạo API.

Khóa ngoại được ánh xạ bằng trường ID thay vì `@ManyToOne`/`@OneToMany`; khóa ngoại ghép và CHECK/UNIQUE vẫn do schema MySQL gốc kiểm tra. Không sinh DDL từ entity để thay schema gốc. Giá trị trạng thái hiện dùng String và được CHECK trong database. Xem `docs/entity-mapping.md` để đối chiếu từng bảng.

`deleteById` xóa vật lý; người viết nghiệp vụ phải quyết định đối tượng nào được xóa, đối tượng nào chỉ đổi trạng thái để lưu lịch sử. Các thao tác nhiều service cần một phương thức nghiệp vụ `@Transactional` bao ngoài. Chưa có khóa/version để xử lý cập nhật đồng thời, nên cần bổ sung locking cho luồng giữ phòng, hợp đồng và hóa đơn.

Generator: `python tools/generate_backend.py`. Lệnh này ghi đè entity, repository, service đã sinh; chỉ chạy lại trước khi chỉnh thủ công hoặc sau khi đã lưu thay đổi vào Git. Schema SQL được giữ nguyên.

Yêu cầu nền tảng tham khảo từ [tài liệu Spring Boot 3.5](https://docs.spring.io/spring-boot/3.5/system-requirements.html).
