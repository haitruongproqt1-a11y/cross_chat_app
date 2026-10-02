# Quy Tắc Dự Án KINI CHAT (Dành Riêng Cho AI Assistant)

## 1. Nguyên Tắc Bảo Tồn & Nâng Cấp An Toàn (BẮT BUỘC TUÂN THỦ 100%)
- **TUYỆT ĐỐI KHÔNG PHÁ CODE, KHÔNG PHÁ TÍNH NĂNG ĐANG HOẠT ĐỘNG**:
  - Toàn bộ tính năng hiện tại (gọi thoại, gọi video, chia sẻ màn hình, realtime chat, biểu cảm tin nhắn & nhật ký, ghim tin nhắn, trích dẫn reply, tường cá nhân, cập nhật OTA...) đã hoạt động ổn định và là tài sản quan trọng của ứng dụng.
  - Không được tự ý xóa, viết lại (rewrite) hoặc làm thay đổi logic các tính năng đang chạy tốt.
- **CHỈ NÂNG CẤP, SỬA CHỮA NHỮNG GÌ THẬT SỰ CẦN THIẾT**:
  - Chỉ can thiệp đúng điểm nghẽn hoặc lỗi cụ thể mà người dùng yêu cầu (Minimal Targeted Fix).
- **SO SÁNH VÀ GIỮ LẠI CÁI TỐT HƠN**:
  - Trước khi sửa đổi bất kỳ đoạn code nào, phải phân tích và so sánh phương án mới với phương án hiện tại.
  - Nếu phương án hiện tại ổn định hơn, **BẮT BUỘC giữ lại phương án hiện tại**.
  - Chỉ nâng cấp khi phương án mới chứng minh được sự vượt trội mà không làm ảnh hưởng tới các chức năng khác.

## 2. Quy Tắc Phát Hành GitHub
Khi người dùng yêu cầu build hoặc cập nhật lên GitHub:
1. **CHỈ build và tải lên các gói OTA**:
   - `latest_ota_package.zip`
   - `update_vX.X.X.zip`
   - `app-arm64-v8a-release.apk`
   - Đẩy file `version.json` cập nhật lên nhánh `main` của GitHub.
   - Tạo GitHub Release tương ứng với tag `vX.X.X` đính kèm các file trên.
2. **TUYỆT ĐỐI KHÔNG build bộ cài đặt EXE** (`VideoSub-AI-Studio-Setup-v...exe` hoặc tương tự) trừ khi người dùng yêu cầu cụ thể và rõ ràng.
