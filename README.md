# CrossChat Studio - Ứng Dụng Chat Đa Nền Tảng (Mobile & PC)

Ứng dụng nhắn tin thời gian thực hoàn chỉnh xây dựng bằng **Flutter** và **Firebase**, hỗ trợ một codebase duy nhất cho cả **Mobile (Android, iOS)** và **PC (Windows, macOS, Linux, Web)** với giao diện Responsive thích ứng thông minh.

---

## 🚀 Các Tính Năng Chính Đã Triển Khai

| STT | Nhóm Tính Năng | Mô tả chi tiết & Công nghệ sử dụng |
|:---:|:---|:---|
| 1 | **Đăng nhập & Đăng ký** | Xác thực qua Firebase Auth (Email/Mật khẩu), tự động khởi tạo hồ sơ Firestore, theo dõi trạng thái Online/Offline theo thời gian thực. |
| 2 | **Nhắn tin văn bản** | Nhắn tin 1-1 realtime qua Cloud Firestore streams, hiển thị trạng thái đã đọc (Read receipts), định dạng thời gian thông minh. |
| 3 | **Cài đặt & Cá nhân hóa** | Đổi tên hiển thị, cập nhật tiểu sử/status, tải lên ảnh đại diện Avatar, chuyển đổi giao diện Sáng (Light) / Tối (Dark). |
| 4 | **Chat nhóm (Group Chat)** | Tạo phòng nhóm với tên nhóm và ảnh đại diện, chọn nhiều thành viên từ danh bạ, quản trị danh sách người tham gia. |
| 5 | **Chia sẻ File & Đa phương tiện**| Tích hợp `image_picker` và `file_picker` cho phép gửi ảnh, video, tài liệu (PDF, Word, Zip) lưu trữ an toàn trên Firebase Storage. |
| 6 | **Tin nhắn Đa phương tiện** | Trình phát tin nhắn thoại (Audio voice note player), xem trước ảnh và video clip trực tiếp trong bong bóng chat. |
| 7 | **Thông báo & Push Notification**| Tích hợp Firebase Cloud Messaging (FCM) + `flutter_local_notifications` hiển thị popup thông báo khi có tin nhắn mới cả khi ứng dụng đang chạy nền. |
| 8 | **Định vị & Bản đồ** | Lấy tọa độ GPS tức thời bằng `geolocator`, render card vị trí và liên kết mở trực tiếp trên Google Maps. |
| 9 | **Gọi thoại & Gọi Video** | Tích hợp WebRTC (`flutter_webrtc`) với kiến trúc P2P signaling qua Firestore (Offer/Answer/ICE Candidates), hỗ trợ tắt/bật mic, camera, đổi camera trước/sau. |
| 10| **Bảo mật & Kiểm soát dữ liệu** | Mã hóa văn bản đầu cuối (End-to-End Encryption) bằng thuật toán AES-256, tùy chọn xóa cache lưu trữ trên thiết bị và xóa toàn bộ lịch sử phòng chat. |
| 11| **Giao diện Responsive PC & Mobile** | Trên Mobile: Điều hướng Tab (Chats / Contacts / Settings). Trên PC/Desktop: Giao diện Split-screen (Sidebar danh sách + Khung hội thoại chính bên phải). |

---

## 📂 Cấu Trúc Dự Án (Architecture)

```
cross_chat_app/
├── pubspec.yaml               # Thư viện phụ thuộc (Firebase, WebRTC, Media, Geolocator...)
├── analysis_options.yaml       # Quy chuẩn Lint code
├── lib/
│   ├── main.dart              # Khởi tạo Firebase, MultiProvider, MaterialApp
│   ├── firebase_options.dart   # Cấu hình đa nền tảng Firebase
│   ├── models/                # Thực thể dữ liệu
│   │   ├── user_model.dart
│   │   ├── message_model.dart
│   │   ├── chat_room_model.dart
│   │   └── call_model.dart
│   ├── services/              # Tầng dịch vụ logic & API
│   │   ├── auth_service.dart
│   │   ├── chat_service.dart
│   │   ├── storage_service.dart
│   │   ├── notification_service.dart
│   │   ├── location_service.dart
│   │   ├── webrtc_service.dart
│   │   └── security_service.dart
│   ├── providers/             # Tầng quản lý trạng thái (Provider State Management)
│   │   ├── auth_provider.dart
│   │   └── chat_provider.dart
│   ├── screens/               # Màn hình giao diện
│   │   ├── auth/              # Login, Register
│   │   ├── home/              # HomeScreen (Responsive), ChatList, Contacts, Settings
│   │   ├── chat/              # ChatDetailScreen, CreateGroupScreen
│   │   ├── call/              # CallScreen (WebRTC Audio/Video Call)
│   │   └── settings/          # ProfileEditScreen, PrivacySecurityScreen
│   ├── widgets/               # Các Widget tái sử dụng
│   │   ├── responsive_layout.dart
│   │   ├── message_bubble.dart
│   │   ├── media_attachment_sheet.dart
│   │   └── avatar_widget.dart
│   └── utils/                 # Giao diện & Tiện ích chung
│       ├── app_theme.dart
│       └── constants.dart
```

---

## 🛠️ Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Bước 1: Cài đặt Flutter SDK
Nếu máy tính của bạn chưa có Flutter SDK:
1. Tải bản mới nhất tại: https://docs.flutter.dev/get-started/install/windows/desktop
2. Giải nén vào thư mục `C:\src\flutter`.
3. Thêm `C:\src\flutter\bin` vào biến môi trường hệ thống (`PATH`).
4. Mở PowerShell và kiểm tra:
   ```powershell
   flutter doctor
   ```

### Bước 2: Tải các thư viện phụ thuộc
Di chuyển vào thư mục dự án:
```powershell
cd C:\Users\ADMIN\.gemini\antigravity\scratch\cross_chat_app
flutter pub get
```

### Bước 3: Kết nối Firebase của bạn
1. Cài đặt Firebase CLI:
   ```powershell
   npm install -g firebase-tools
   firebase login
   ```
2. Cài đặt FlutterFire CLI và liên kết dự án:
   ```powershell
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   *Lệnh này sẽ tự động tạo cấu hình chính xác cho Android, iOS, macOS, Web và Windows trong file `lib/firebase_options.dart`.*

3. Bật các dịch vụ trên Firebase Console:
   - **Authentication**: Bật phương thức Email/Password.
   - **Cloud Firestore Database**: Khởi tạo chế độ test hoặc production rules.
   - **Firebase Storage**: Bật dịch vụ để lưu ảnh/file.
   - **Cloud Messaging (FCM)**: Bật để nhận Push Notification.

### Bước 4: Chạy thử nghiệm trên các nền tảng

- **Chạy trên PC (Windows Desktop):**
  ```powershell
  flutter run -d windows
  ```

- **Chạy trên Web (Trình duyệt Chrome/Edge):**
  ```powershell
  flutter run -d chrome
  ```

- **Chạy trên điện thoại Android (kết nối cáp hoặc máy ảo):**
  ```powershell
  flutter run -d android
  ```

- **Chạy trên iOS / macOS (yêu cầu máy Mac):**
  ```bash
  flutter run -d ios
  flutter run -d macos
  ```

---

## 📱 Chiến Lược Phát Hành & Phân Phối (Production Release)

### 1. Phân phối trên Google Play Store (Android)
1. Tạo KeyStore ký ứng dụng (App Signing Keystore):
   ```powershell
   keytool -genkey -v -keystore crosschat-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Cấu hình file `android/key.properties` và `android/app/build.gradle`.
3. Đóng gói file định dạng **Android App Bundle (.aab)**:
   ```powershell
   flutter build appbundle --release
   ```
4. Tải file `.aab` lên Google Play Console theo dõi qua các kênh Internal Testing -> Closed Testing -> Production.

### 2. Phân phối trên Apple App Store (iOS)
1. Đăng ký Apple Developer Account ($99/năm).
2. Tạo App ID và Provisioning Profiles trên Apple Developer Portal.
3. Đóng gói file `.ipa`:
   ```bash
   flutter build ipa --release
   ```
4. Sử dụng Xcode hoặc `xcrun altool` để tải lên TestFlight, thu thập phản hồi beta trước khi gửi xét duyệt lên App Store.

### 3. Phân phối trên Windows PC
- Đóng gói MSIX / AppX để đưa lên Microsoft Store hoặc tạo bộ cài đặt tự giải nén:
  ```powershell
  flutter build windows --release
  ```
  File thực thi `.exe` kèm thư viện runtime sẽ nằm tại `build/windows/x64/runner/Release`.

---

## 🔒 Kiểm Soát Dữ Liệu & Quy Tắc Bảo Mật (Security Rules)

### Firebase Firestore Rules đề xuất (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /chat_rooms/{roomId} {
      allow read, write: if request.auth != null && request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    match /calls/{callId} {
      allow read, write: if request.auth != null;
      match /{allSubcollections=**} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```
