# Troday wireframe

Mo `index.html` truc tiep trong trinh duyet. Khong can cai dat hay chay dev server.

- Chuyen giua Nguoi thue, Chu tro va Quan tri bang bo chon o thanh tren.
- Du lieu mau duoc luu trong `localStorage`; de bat dau lai, mo console va go `__troday.reset()`.
- Anh phong nam trong `assets/`; icon nam trong `icons.js`. Prototype khong can Internet.
- Cac thao tac la mo phong tren trinh duyet, khong ghi vao MySQL hay tai file len may chu.

## Cac luong duoc mo phong

- Tim/loc/luu tin, xem chi tiet, bao cao, danh gia.
- Chat theo nguoi voi nhieu ngu canh bai dang/phong trong cung mot dong thoi gian.
- Chu tro tao lich cho dung nguoi/phong; xac nhan da xem; nguoi thue dong y; tao hop dong; yeu cau sua/xac nhan phien ban; xac nhan vao o.
- Quan ly nha/phong, tin dang, dich vu theo nha va ap dung/gia rieng theo phong.
- Danh sach nguoi o, yeu cau them nguoi, xuat CSV phuc vu cu tru; gia han/ket thuc/doi phong; tim nguoi o ghep.
- Hoa don nhap/phat hanh/thu/huy, chi so dau-cuoi va gia dich vu duoc chot tai ky.
- Xac minh, duyet tin, xu ly bao cao, khoa tai khoan, mau hop dong va nhat ky quan tri.

## Luu y ve V5

Wireframe bao phu cac luong nghiep vu va cac thuc the cua V5, nhung phan chat nhieu bai dang trong mot hoi thoai la **de xuat giao dien moi**: V5 hien gan `conversations` voi mot `post_id`/`room_id`. De luu dung mo hinh chat duoc mo phong, can tach ngu canh bai dang ra bang con cua hoi thoai (hoac nhom nhieu conversation V5 theo cap nguoi o lop ung dung) va doi lien ket lich xem sang ngu canh phong tuong ung. Khong nen coi du lieu chat cua prototype la script migration cho V5.
