---
name: preserve-and-upgrade
description: >-
  Quy chuẩn bảo tồn toàn vẹn mã nguồn và tính năng hiện tại của ứng dụng KINI CHAT.
  Kích hoạt khi cần nâng cấp, sửa lỗi hoặc thêm tính năng mới: luôn so sánh giải pháp mới
  với giải pháp hiện tại, chỉ chọn cái tốt nhất và ổn định nhất, tuyệt đối không phá code,
  không làm hỏng hay suy giảm bất kỳ tính năng nào đang hoạt động tốt.
---

# Nguyên Tắc Nâng Cấp An Toàn & Bảo Tồn Toàn Vẹn Mã Nguồn (Preserve & Upgrade)

Mục tiêu tối thượng: **Bảo vệ toàn vẹn 100% ứng dụng hiện tại, không làm hỏng tính năng cũ, chỉ sửa đúng điểm nghẽn và luôn chọn giải pháp tốt nhất.**

---

## 1. Nguyên Tắc Bất Biến (Immutable Rules)

1. **Không Phá Code - Không Phá Tính Năng (Zero Regressions)**:
   - Các tính năng đã hoạt động ổn định (gọi thoại, gọi video, chia sẻ màn hình, đàm thoại ngầm, tin nhắn realtime, biểu cảm tin nhắn, ghim tin nhắn, trả lời trích dẫn, bảng tin tường cá nhân, cập nhật OTA...) là tài sản cốt lõi.
   - Tuyệt đối không xóa, không viết lại từ đầu (rewrite) hoặc làm thay đổi logic hoạt động bình thường của các tính năng này khi không có yêu cầu cụ thể.

2. **Chỉ Chạm Vào Những Gì Cần Thiết (Targeted Modifications)**:
   - Phạm vi can thiệp code phải khu biệt (minimal scope), tập trung 100% vào việc giải quyết lỗi hoặc tính năng được yêu cầu.
   - Không thực hiện các hành động "dọn dẹp" (refactor) không cần thiết làm xáo trộn các module đang chạy mượt mà.

3. **So Sánh và Giữ Lại Cái Tốt Hơn (Compare & Retain the Best)**:
   - Trước khi thay đổi bất kỳ đoạn code hoặc giải pháp kiến trúc nào, phải so sánh:
     + Giải pháp hiện tại đang làm gì? Có ưu điểm gì?
     + Giải pháp mới giải quyết được gì? Có rủi ro gì?
   - Nếu giải pháp hiện tại ổn định và tốt hơn, **BẮT BUỘC giữ lại giải pháp hiện tại**.
   - Chỉ áp dụng giải pháp mới khi chứng minh được nó khắc phục được lỗi mà không gây phản tác dụng hoặc phá vỡ các chức năng khác.

---

## 2. Quy Trình 4 Bước Khi Xử Lý Yêu Cầu

### Bước 1: Rà Soát & Đối Chiếu Hiện Trạng (Inspection & Comparison)
- Đọc và hiểu kỹ luồng code hiện hữu đang đảm nhiệm tính năng liên quan.
- Xác định chính xác lỗi hoặc điểm cần tối ưu.
- Lập bảng so sánh phương án cũ vs phương án mới: Đánh giá nguy cơ xung đột với các tính năng khác (đặc biệt là âm thanh, micro, quyền Android, WebRTC transceiver).

### Bước 2: Tối Ưu Hóa Tối Thiểu (Minimal Surgical Fix)
- Chỉ sửa đổi chính xác các dòng code hoặc hàm gây ra vấn đề.
- Giữ nguyên các tham số, callback và cấu trúc mà các màn hình/module khác đang phụ thuộc vào.

### Bước 3: Kiểm Tra Lại Mã Nguồn (Validation)
- Luôn chạy `flutter analyze` để bảo đảm 0 lỗi cú pháp (No issues found).
- Kiểm tra tính tương thích trên Android (quyền manifest, dịch vụ foreground, phiên bản OS Android 14+).

### Bước 4: Đóng Gói & Xuất Bản Đúng Quy Chuẩn
- Tuân thủ nghiêm ngặt quy tắc xuất bản hệ thống:
  + Chỉ build các gói OTA (`latest_ota_package.zip`, `update_vX.X.X.zip`) và file APK Android nếu cần.
  + Cập nhật `version.json` trên nhánh `main`.
  + Tạo GitHub Release tương ứng với tag phiên bản.
  + **Tuyệt đối không build bộ cài đặt EXE** trừ khi người dùng yêu cầu rõ ràng.
