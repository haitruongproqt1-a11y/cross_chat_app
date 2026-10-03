class AppConstants {
  static const String appName = 'KINI CHAT';
  static const String appVersion = '1.0.23';
  
  // Định dạng ngày giờ thân thiện theo Tiếng Việt
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
      return days[dateTime.weekday - 1];
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month/${dateTime.year}';
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // 15 Câu hỏi bảo mật chuẩn của KINI CHAT
  static const List<String> securityQuestions = [
    'Tên trường tiểu học đầu tiên của bạn là gì?',
    'Biệt danh thời thơ ấu của bạn là gì?',
    'Tên thú cưng đầu tiên của bạn là gì?',
    'Tên giáo viên bạn nhớ nhất là gì?',
    'Địa điểm bạn yêu thích khi còn nhỏ là ở đâu?',
    'Công việc đầu tiên của bạn là gì?',
    'Cuốn sách bạn yêu thích nhất là gì?',
    'Món ăn bạn yêu thích nhất là gì?',
    'Bạn sinh ra ở thành phố hoặc tỉnh nào?',
    'Nghề nghiệp mơ ước khi còn nhỏ của bạn là gì?',
    'Chuyến du lịch đầu tiên bạn nhớ là đến đâu?',
    'Môn thể thao bạn yêu thích là gì?',
    'Tên người bạn thời thơ ấu thân nhất của bạn là gì?',
    'Bài hát bạn yêu thích nhất là gì?',
    'Con số may mắn của bạn là gì?',
  ];

  // Danh sách tình trạng hôn nhân / mối quan hệ
  static const List<String> maritalStatusList = [
    'Độc thân',
    'Đã kết hôn',
    'Đang tìm hiểu',
    'Hẹn hò',
    'Ly hôn / Đơn thân',
    'Khác',
  ];

  // Danh sách tỉnh thành Việt Nam
  static const List<String> vietnamProvinces = [
    'Tất cả',
    'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bạc Liêu',
    'Bắc Ninh', 'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước',
    'Bình Thuận', 'Cà Mau', 'Cao Bằng', 'Đắk Lắk', 'Đắk Nông',
    'Điện Biên', 'Đồng Nai', 'Đồng Tháp', 'Gia Lai', 'Hà Giang',
    'Hà Nam', 'Hà Tĩnh', 'Hải Dương', 'Hậu Giang', 'Hòa Bình',
    'Hưng Yên', 'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu',
    'Lâm Đồng', 'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định',
    'Nghệ An', 'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên',
    'Quảng Bình', 'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị',
    'Sóc Trăng', 'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên',
    'Thanh Hóa', 'Huế', 'Tiền Giang', 'Trà Vinh', 'Tuyên Quang',
    'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái'
  ];
}
