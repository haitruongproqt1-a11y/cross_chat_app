import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  vietnamese,
  english,
}

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  AppLanguage _currentLanguage = AppLanguage.vietnamese;
  AppLanguage get currentLanguage => _currentLanguage;
  bool get isVietnamese => _currentLanguage == AppLanguage.vietnamese;
  bool get isEnglish => _currentLanguage == AppLanguage.english;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('app_language') ?? 'vi';
      _currentLanguage = code == 'en' ? AppLanguage.english : AppLanguage.vietnamese;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language == AppLanguage.english ? 'en' : 'vi');
    } catch (_) {}
  }

  String t(String key) {
    if (_currentLanguage == AppLanguage.english) {
      return _en[key] ?? _vi[key] ?? key;
    }
    return _vi[key] ?? key;
  }

  static const Map<String, String> _vi = {
    // Navigation
    'tab_messages': 'Tin Nhắn',
    'tab_contacts': 'Danh Bạ',
    'tab_nearby': 'Quanh Đây',
    'tab_wall': 'Nhật Ký',
    'tab_settings': 'Cài Đặt',

    // Chat List
    'search_chat_hint': 'Tìm kiếm cuộc trò chuyện hoặc tin nhắn...',
    'no_chats': 'Chưa có cuộc trò chuyện nào',
    'start_new_group': 'Bắt Đầu Nhóm Mới',
    'delete_swipe': 'XÓA',
    'delete_chat': 'Xóa cuộc trò chuyện',
    'confirm_delete_title': 'Xóa cuộc trò chuyện?',
    'confirm_delete_desc': 'Toàn bộ nội dung tin nhắn sẽ bị xóa vĩnh viễn và không thể khôi phục.',
    'cancel': 'Hủy',
    'delete': 'Xóa',
    'mark_read': 'Đánh dấu đã đọc',
    'group_settings': 'Cài đặt nhóm',
    'direct_chat': 'Trò chuyện cá nhân',

    // Chat Room
    'active_now': 'Đang hoạt động',
    'members_suffix': 'thành viên',
    'blocked_notice': 'Đã bị chặn',
    'pinned_message_title': 'Tin nhắn đã ghim',
    'unpin': 'Gỡ ghim',
    'type_message_hint': 'Nhập tin nhắn bảo mật...',
    'admin_lock_message_notice': 'Chỉ Trưởng nhóm và Phó nhóm mới có thể gửi tin nhắn trong nhóm này.',
    'unblock_user': 'Bỏ chặn',
    'you_blocked_user': 'Bạn đã chặn người dùng này.',
    'voice_call': 'Gọi thoại',
    'video_call': 'Gọi Video',
    'tiktok_viewer': 'Lướt TikTok & LIVE',
    'bubble_theme': 'Đổi kiểu bong bóng chat',
    'wallpaper': 'Cài đặt hình nền',
    'add_friend': 'Thêm vào danh bạ (Kết bạn)',
    'remove_friend': 'Xóa khỏi danh bạ bạn bè',
    'block_user': 'Chặn người này',
    'unblock_user_action': 'Bỏ chặn người này',

    // Group Settings
    'group_settings_title': 'Cài Đặt Nhóm',
    'edit_group_name': 'Đổi tên nhóm',
    'new_group_name_hint': 'Nhập tên nhóm mới',
    'save': 'Lưu',
    'admin_permissions_header': 'QUYỀN QUẢN TRỊ VIÊN',
    'only_admins_message': 'Chỉ Trưởng/Phó nhóm được gửi tin nhắn',
    'only_admins_message_sub': 'Thành viên thường chỉ được xem, không thể gửi tin nhắn',
    'only_admins_add': 'Chỉ Trưởng/Phó nhóm được thêm người',
    'only_admins_add_sub': 'Ngăn thành viên thường tự ý mời người lạ vào nhóm',
    'members_header': 'THÀNH VIÊN',
    'add_member_btn': 'Thêm thành viên',
    'search_member_hint': 'Tìm kiếm thành viên trong nhóm...',
    'role_owner': 'Trưởng nhóm',
    'role_deputy': 'Phó nhóm',
    'transfer_owner_btn': 'Chuyển giao quyền Trưởng nhóm (Key chính)',
    'revoke_deputy_btn': 'Gỡ quyền Phó nhóm',
    'appoint_deputy_btn': 'Bổ nhiệm làm Phó nhóm',
    'kick_member_btn': 'Mời ra khỏi nhóm',
    'leave_group_btn': 'Rời khỏi nhóm',
    'leave_group_owner_btn': 'Rời nhóm & Trao lại Key',
    'leave_group_title': 'Rời khỏi nhóm?',
    'leave_group_confirm_sub': 'Bạn sẽ không thể tiếp tục nhận hoặc gửi tin nhắn trong nhóm này nữa.',
    'leave_transfer_title': 'Chuyển giao quyền Trưởng nhóm',
    'leave_transfer_sub': 'Bạn đang là Trưởng nhóm. Trước khi rời nhóm, bạn cần chọn người tiếp quản giữ Key Trưởng nhóm, hoặc để hệ thống tự động chọn ngẫu nhiên một thành viên còn lại.',
    'leave_random_choice': 'Rời & Chọn ngẫu nhiên',
    'leave_pick_choice': 'Tự chọn người tiếp quản',
    'pick_successor_title': 'Chọn Trưởng nhóm mới',
    'view_wall': 'Xem trang cá nhân',
    'direct_message': 'Nhắn tin riêng',

    // Settings
    'settings_header': 'Cài đặt hệ thống',
    'account_profile': 'Cá nhân',
    'profile_verified': 'Hồ sơ được xác thực qua tài khoản đăng nhập',
    'security_header': 'Bảo mật tài khoản',
    'secure_login': 'Đăng nhập an toàn',
    'secure_login_desc': 'Mật khẩu KINI được lưu dưới dạng mã băm.',
    'security_question': 'Câu hỏi bảo mật',
    'devices_header': 'Thiết bị đăng nhập',
    'edit_profile_tooltip': 'Chỉnh sửa hồ sơ',
    'single_device_notice': 'KINI chỉ duy trì một thiết bị hoạt động tại một thời điểm.',
    'dark_mode': 'Giao diện tối (Dark Mode)',
    'personal_bubble_theme': 'Bong bóng chat cá nhân',
    'personal_bubble_sub': 'Bộ sưu tập 20 chủ đề bong bóng tin nhắn',
    'language_setting': 'Ngôn ngữ hiển thị (Language)',
    'language_subtitle': 'Chuyển đổi hoàn toàn Tiếng Việt hoặc English',
    'check_update': 'Kiểm tra bản cập nhật KINI',
    'sign_out': 'Đăng xuất tài khoản',
    'confirm_sign_out_title': 'Xác nhận đăng xuất',
    'confirm_sign_out_desc': 'Bạn có chắc chắn muốn đăng xuất khỏi KINI CHAT?',
    'version_label': 'Phiên bản',

    // Auth & Login
    'login_title': 'KINI CHAT',
    'login_subtitle': 'Nhắn tin siêu tốc • Mã hóa đầu cuối E2EE',
    'tab_signin': 'Đăng Nhập',
    'tab_signup': 'Đăng Ký Tài Khoản',
    'identifier_label': 'Tên đăng nhập hoặc Email',
    'identifier_hint': 'tenban@kinichat.vn hoặc username',
    'password_label': 'Mật khẩu bảo mật',
    'password_hint': 'Nhập mật khẩu',
    'forgot_password': 'Quên mật khẩu?',
    'auto_signin': 'Tự động đăng nhập trên thiết bị này',
    'auto_signin_sub': 'Lưu phiên an toàn bằng token sinh trắc học',
    'signin_btn': 'Đăng Nhập Ngay',
    'biometric_btn_tip': 'Xác thực Face ID / Vân tay',
    'two_factor_title': 'Bảo mật 2 lớp KINI',
    'key_recovery': 'Cứu hộ Key',
    'two_factor_desc': 'Khôi phục tài khoản thông qua câu hỏi bảo mật và khóa mã hóa Argon2id.',
    'terms_notice': 'Bằng việc tiếp tục, bạn đồng ý với Điều khoản sử dụng & Chính sách quyền riêng tư KINI CHAT',
    'bank_security': 'Bảo mật cấp Ngân hàng & Viễn thông',

    // Quick Actions & Filters
    'all_filter': 'Tất cả',
    'unread_filter': 'Chưa đọc',
    'groups_filter': 'In Motion / Trường học',
    'add_story': 'Tạo tin',
    'quick_add': 'Thêm',
    'quick_search': 'Tìm kiếm',
    'quick_theme': 'Hình nền',
    'quick_mute': 'Tắt chuông',
    'verified_pro': 'Tài khoản Pro Đã xác thực E2EE',
    'qr_code_btn': 'Mã QR cá nhân',
    'edit_profile_btn': 'Chỉnh sửa hồ sơ',
  };

  static const Map<String, String> _en = {
    // Navigation
    'tab_messages': 'Messages',
    'tab_contacts': 'Contacts',
    'tab_nearby': 'Nearby',
    'tab_wall': 'Wall Feed',
    'tab_settings': 'Settings',

    // Chat List
    'search_chat_hint': 'Search conversations or messages...',
    'no_chats': 'No conversations yet',
    'start_new_group': 'Start New Group',
    'delete_swipe': 'DELETE',
    'delete_chat': 'Delete conversation',
    'confirm_delete_title': 'Delete conversation?',
    'confirm_delete_desc': 'All messages will be permanently deleted and cannot be recovered.',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'mark_read': 'Mark as read',
    'group_settings': 'Group settings',
    'direct_chat': 'Direct message',

    // Chat Room
    'active_now': 'Active now',
    'members_suffix': 'members',
    'blocked_notice': 'Blocked',
    'pinned_message_title': 'Pinned Message',
    'unpin': 'Unpin',
    'type_message_hint': 'Type a secure message...',
    'admin_lock_message_notice': 'Only Group Owner and Deputies can send messages in this group.',
    'unblock_user': 'Unblock',
    'you_blocked_user': 'You have blocked this user.',
    'voice_call': 'Voice Call',
    'video_call': 'Video Call',
    'tiktok_viewer': 'Browse TikTok & LIVE',
    'bubble_theme': 'Change chat bubble theme',
    'wallpaper': 'Set chat wallpaper',
    'add_friend': 'Add to contacts',
    'remove_friend': 'Remove friend',
    'block_user': 'Block this user',
    'unblock_user_action': 'Unblock this user',

    // Group Settings
    'group_settings_title': 'Group Settings',
    'edit_group_name': 'Edit Group Name',
    'new_group_name_hint': 'Enter new group name',
    'save': 'Save',
    'admin_permissions_header': 'ADMIN PERMISSIONS',
    'only_admins_message': 'Only Admins can send messages',
    'only_admins_message_sub': 'Regular members can only read, not send messages',
    'only_admins_add': 'Only Admins can add members',
    'only_admins_add_sub': 'Prevent regular members from adding strangers',
    'members_header': 'MEMBERS',
    'add_member_btn': 'Add Member',
    'search_member_hint': 'Search members in group...',
    'role_owner': 'Owner',
    'role_deputy': 'Deputy',
    'transfer_owner_btn': 'Transfer Owner Role (Master Key)',
    'revoke_deputy_btn': 'Revoke Deputy Role',
    'appoint_deputy_btn': 'Appoint as Deputy',
    'kick_member_btn': 'Remove from group',
    'leave_group_btn': 'Leave group',
    'leave_group_owner_btn': 'Leave Group & Transfer Key',
    'leave_group_title': 'Leave group?',
    'leave_group_confirm_sub': 'You will no longer receive or send messages in this group.',
    'leave_transfer_title': 'Transfer Owner Role',
    'leave_transfer_sub': 'You are the Group Owner. Before leaving, you must choose a successor to hold the Master Key, or let the system randomly assign a remaining member.',
    'leave_random_choice': 'Leave & Random Assign',
    'leave_pick_choice': 'Select Successor',
    'pick_successor_title': 'Select New Owner',
    'view_wall': 'View Profile Wall',
    'direct_message': 'Send Direct Message',

    // Settings
    'settings_header': 'System Settings',
    'account_profile': 'Profile',
    'profile_verified': 'Profile verified with account credentials',
    'security_header': 'Account Security',
    'secure_login': 'Secure Login',
    'secure_login_desc': 'KINI passwords are cryptographically hashed.',
    'security_question': 'Security Recovery Question',
    'devices_header': 'Active Devices',
    'edit_profile_tooltip': 'Edit profile',
    'single_device_notice': 'KINI maintains only one active session at a time.',
    'dark_mode': 'Dark Mode',
    'personal_bubble_theme': 'Personal Bubble Theme',
    'personal_bubble_sub': 'Collection of 20 custom chat bubble styles',
    'language_setting': 'Display Language',
    'language_subtitle': 'Seamlessly switch between Tiếng Việt or English',
    'check_update': 'Check for KINI updates',
    'sign_out': 'Sign out of account',
    'confirm_sign_out_title': 'Confirm Sign Out',
    'confirm_sign_out_desc': 'Are you sure you want to sign out of KINI CHAT?',
    'version_label': 'Version',

    // Auth & Login
    'login_title': 'KINI CHAT',
    'login_subtitle': 'Ultra-fast messaging • E2EE Encrypted',
    'tab_signin': 'Sign In',
    'tab_signup': 'Register',
    'identifier_label': 'Username or Email',
    'identifier_hint': 'yourname@kinichat.vn or username',
    'password_label': 'Security Password',
    'password_hint': 'Enter password',
    'forgot_password': 'Forgot password?',
    'auto_signin': 'Auto sign-in on this device',
    'auto_signin_sub': 'Secured session via biometric token',
    'signin_btn': 'Sign In Now',
    'biometric_btn_tip': 'Biometric authentication (Face ID / Fingerprint)',
    'two_factor_title': 'KINI 2-Factor Security',
    'key_recovery': 'Key Recovery',
    'two_factor_desc': 'Account recovery via security question and Argon2id hash.',
    'terms_notice': 'By continuing, you agree to our Terms of Service & Privacy Policy',
    'bank_security': 'Bank & Telecom Grade Security',

    // Quick Actions & Filters
    'all_filter': 'All',
    'unread_filter': 'Unread',
    'groups_filter': 'In Motion / School',
    'add_story': 'Add story',
    'quick_add': 'Add',
    'quick_search': 'Search',
    'quick_theme': 'Theme',
    'quick_mute': 'Mute',
    'verified_pro': 'Verified Pro E2EE Account',
    'qr_code_btn': 'My QR Code',
    'edit_profile_btn': 'Edit Profile',
  };
}
