# Trọday — wireframe và CSDL v5

Mở `index.html` trực tiếp trong trình duyệt, không cần cài đặt hay chạy server. Chọn vai trò Người thuê, Chủ trọ hoặc Quản trị ở thanh trên.

Dữ liệu mẫu lưu trong `localStorage`; nhập `__troday.reset()` ở console để bắt đầu lại. Wireframe chạy độc lập với MySQL, các thao tác trên giao diện chưa ghi vào CSDL thật.

## Bắt đầu đọc

- [Quy tắc nghiệp vụ](docs/business-rules.md): toàn bộ logic đang có, thay đổi đã thực hiện, ràng buộc CSDL và cách tích hợp API.
- [SQL tạo mới](database/schema.sql): CSDL v5 hiện tại, 40 bảng.
- [SQL nâng cấp](database/migrations/20261024_v5_workflows.sql): chuyển v5 gốc 39 bảng sang phiên bản hiện tại.

## Cấu trúc thư mục

```text
index.html                     Giao diện
app.js                         Dữ liệu mẫu và xử lý nghiệp vụ
styles.css                     Kiểu hiển thị
icons.js                       Bộ biểu tượng
assets/                        Ảnh phòng
docs/
  business-rules.md            Tài liệu nghiệp vụ chung
database/
  schema.sql                   SQL đầy đủ để tạo CSDL mới
  migrations/
    20261024_v5_workflows.sql   Nâng cấp một lần từ v5 gốc
  source/
    workflows.sql              Nguồn chung của view, trigger và procedure
scripts/
  build-database.cjs            Đồng bộ nguồn nghiệp vụ vào SQL triển khai
tests/
  app.test.cjs                 Kiểm thử nghiệp vụ JavaScript
  browser.test.cjs             Kiểm thử giao diện bằng Chrome
  database.test.cjs            Kiểm thử MySQL trên instance tạm
  fixtures/
    v5-original-schema.sql     Cấu trúc v5 gốc để kiểm thử nâng cấp
    workflow-data.sql          Dữ liệu mẫu để kiểm thử SQL
```

SQL triển khai nằm trong `database/`. Hai SQL trong `tests/fixtures/` cần giữ để kiểm tra migration và các giao dịch; không dùng để cài đặt hệ thống. Tên migration bắt đầu bằng ngày áp dụng để team theo dõi thứ tự.

## Sử dụng SQL

Chọn **một** cách phù hợp:

- **Tạo mới:** chạy `database/schema.sql`. File tự tạo và chọn CSDL `room_rental_v5_20261023`; nếu tên này đã tồn tại thì dừng. Tên CSDL được giữ nguyên để tương thích v5.
- **Nâng cấp v5 gốc:** sao lưu, dừng các thao tác ghi rồi chạy `database/migrations/20261024_v5_workflows.sql` **một lần**. Script kiểm tra dữ liệu mâu thuẫn trước DDL. Nếu có lỗi thì dừng và xử lý nguyên nhân; không dùng `--force` hoặc bỏ qua lỗi để chạy tiếp. MySQL DDL không rollback toàn bộ như giao dịch dữ liệu.

Không chạy migration ngay sau bản tạo mới trên cùng CSDL. Chưa áp dụng các script này lên CSDL hiện có của người dùng.

Khi sửa view, trigger hoặc procedure, sửa `database/source/workflows.sql` rồi chạy:

```sh
npm run db:build
npm run db:check
```

Commit cả nguồn chung và hai SQL đã đồng bộ. Script build chỉ cập nhật file, không kết nối CSDL. Chi tiết cột mới, tham số procedure và cách gọi từ API nằm trong mục 4–5 của tài liệu nghiệp vụ.

## Kiểm thử

Cần Node.js 22+; không cần `npm install` vì các script chỉ dùng thư viện có sẵn của Node.

Trên PowerShell, nếu `npm.ps1` bị chặn bởi Execution Policy, dùng `npm.cmd` thay cho `npm` trong các lệnh dưới đây.

| Lệnh | Nội dung | Điều kiện thêm |
| --- | --- | --- |
| `npm test` | Nghiệp vụ JavaScript | Không |
| `npm run db:check` | SQL triển khai đồng bộ với nguồn | Không |
| `npm run test:browser` | Thao tác giao diện thật | Chrome; có thể đặt `CHROME_PATH` |
| `npm run test:database` | Tạo mới, nâng cấp và giao dịch đồng thời | MySQL Server/client 8.0 trên Windows; có thể đặt `MYSQL_BIN` |

Bộ kiểm thử MySQL khởi tạo instance tạm có thư mục dữ liệu và cổng riêng, kiểm tra đúng instance trước khi chạy SQL, rồi dọn sau khi hoàn tất. Đường dẫn mặc định là `C:/Program Files/MySQL/MySQL Server 8.0/bin`. Bộ kiểm thử trình duyệt cũng dùng profile tạm.

## Phạm vi mô phỏng

Wireframe có tìm phòng, tin đăng, chat, lịch xem, hợp đồng, bàn giao đại diện, quản lý người ở, đổi phòng, hóa đơn, dịch vụ và quản trị. Danh sách quy tắc chi tiết tập trung trong [tài liệu nghiệp vụ](docs/business-rules.md).

Chat nhiều bài đăng trong cùng một dòng thời gian là đề xuất giao diện: v5 hiện gắn mỗi `conversation` với một `post_id`/`room_id`. API cần nhóm các conversation theo cặp người, hoặc thiết kế thêm ngữ cảnh con và điều chỉnh liên kết lịch xem nếu muốn lưu thành một hội thoại chung. Không dùng dữ liệu chat của prototype làm migration v5.
