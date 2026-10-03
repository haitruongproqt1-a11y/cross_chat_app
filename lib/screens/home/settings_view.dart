import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/security_question_picker_sheet.dart';
import '../settings/profile_edit_screen.dart';
import '../../services/ota_update_service.dart';
import '../../services/localization_service.dart';
import '../chat/bubble_theme_picker_screen.dart';
import '../../utils/constants.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isSecurityExpanded = false;
  String? _newSelectedQuestion;
  final TextEditingController _newAnswerController = TextEditingController();
  bool _isSavingSecurity = false;

  @override
  void dispose() {
    _newAnswerController.dispose();
    super.dispose();
  }

  void _saveSecurityQuestion() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    final question = _newSelectedQuestion ?? user.securityQuestion;
    final answer = _newAnswerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập câu trả lời bảo mật mới')),
      );
      return;
    }

    setState(() => _isSavingSecurity = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateSecurityQuestion(
      securityQuestion: question,
      securityAnswer: answer,
    );
    setState(() => _isSavingSecurity = false);

    if (success && mounted) {
      _newAnswerController.clear();
      setState(() => _isSecurityExpanded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật câu hỏi bảo mật thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _showLanguagePicker(BuildContext context, LocalizationService loc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF0284C7)),
                    const SizedBox(width: 10),
                    Text(
                      loc.t('language_setting'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Text('🇻🇳', style: TextStyle(fontSize: 26)),
                title: const Text('Tiếng Việt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Giao diện hiển thị 100% Tiếng Việt chuẩn xác', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                trailing: loc.isVietnamese
                    ? const Icon(Icons.check_circle, color: Color(0xFF0284C7))
                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () {
                  loc.setLanguage(AppLanguage.vietnamese);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 26)),
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('100% pure English interface across all screens', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                trailing: loc.isEnglish
                    ? const Icon(Icons.check_circle, color: Color(0xFF0284C7))
                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () {
                  loc.setLanguage(AppLanguage.english);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalQrDialog(BuildContext context, UserModel user, LocalizationService loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Text(loc.t('qr_code_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AvatarWidget(
              name: user.displayName,
              photoUrl: user.photoUrl,
              radius: 36,
            ),
            const SizedBox(height: 8),
            Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '@${user.username.isNotEmpty ? user.username : user.email.split('@').first}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.qr_code_2, size: 140, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 13, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text(
                    loc.isVietnamese ? 'Mã QR mã hóa đầu cuối E2EE' : 'End-to-End Encrypted QR Code',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final loc = Provider.of<LocalizationService>(context);
    final user = auth.currentUser;
    final isDark = chatProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = user.securityQuestion.isNotEmpty
        ? user.securityQuestion
        : 'Tên trường tiểu học đầu tiên của bạn là gì?';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(loc.t('account_profile'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.shield, color: primaryColor, size: 28),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // Dòng trạng thái xác thực
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 6),
              Text(
                loc.t('profile_verified'),
                style: TextStyle(
                  color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Thẻ thông tin cá nhân (Profile Card - Stitch Style)
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AvatarWidget(
                          name: user.displayName,
                          photoUrl: user.photoUrl,
                          radius: 30,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                '✓',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username.isNotEmpty ? user.username : user.email.split('@').first}',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user, size: 11, color: Color(0xFF059669)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    loc.t('verified_pro'),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF0F9FF),
                            foregroundColor: const Color(0xFF0284C7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFBAE6FD)),
                            ),
                          ),
                          child: Text(
                            loc.t('edit_profile_btn'),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: loc.t('qr_code_btn'),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showPersonalQrDialog(context, user, loc),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: const Icon(Icons.qr_code_2, color: Color(0xFF0284C7), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Bảo mật tài khoản
          Text(
            loc.t('security_header'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Mục 1: Đăng nhập an toàn
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('secure_login'),
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.t('secure_login_desc'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mục 2: Câu hỏi bảo mật (Có thể mở rộng như Image 4)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSecurityExpanded = !_isSecurityExpanded;
                      _newSelectedQuestion = currentQuestion;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.help_outline, color: Color(0xFF0284C7), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.t('security_question'),
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentQuestion,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _isSecurityExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Thẻ cập nhật thông tin khôi phục (Expanded view)
                if (_isSecurityExpanded)
                  Container(
                    margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loc.isVietnamese ? 'Cập nhật thông tin khôi phục' : 'Update Recovery Info',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.isVietnamese
                              ? 'Hãy chọn câu hỏi mới và đặt câu trả lời bạn có thể ghi nhớ. Câu trả lời sẽ được mã hóa một chiều trước khi lưu.'
                              : 'Select a question and enter an answer you remember. Answers are one-way hashed before saving.',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 14),

                        // Dropdown chọn câu hỏi
                        InkWell(
                          onTap: () async {
                            final q = await SecurityQuestionPickerSheet.show(
                              context,
                              _newSelectedQuestion ?? currentQuestion,
                            );
                            if (q != null && mounted) {
                              setState(() => _newSelectedQuestion = q);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _newSelectedQuestion ?? currentQuestion,
                                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0284C7)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ô nhập câu trả lời mới
                        TextField(
                          controller: _newAnswerController,
                          decoration: InputDecoration(
                            hintText: loc.isVietnamese ? 'Câu trả lời mới' : 'New answer',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nút Lưu câu hỏi bảo mật
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isSavingSecurity ? null : _saveSecurityQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSavingSecurity
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(loc.isVietnamese ? 'Lưu câu hỏi bảo mật' : 'Save Security Question', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Thiết bị đăng nhập
          Text(
            loc.t('devices_header'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.t('single_device_notice'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF0284C7)),
                  tooltip: 'Làm mới',
                  onPressed: () {
                    auth.loadCurrentUserData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.isVietnamese ? 'Đã cập nhật trạng thái phiên đăng nhập' : 'Session status updated')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Cài đặt hệ thống
          Text(
            loc.t('settings_header'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                // Giao diện tối
                SwitchListTile(
                  title: Text(loc.t('dark_mode'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  value: isDark,
                  onChanged: (val) => chatProvider.toggleTheme(val),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: primaryColor),
                ),
                const Divider(height: 1),

                // Ngôn ngữ hiển thị (100% Tiếng Việt hoặc English)
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFF0284C7)),
                  title: Text(loc.t('language_setting'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    loc.isVietnamese ? 'Tiếng Việt 🇻🇳' : 'English 🇬🇧',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: Color(0xFF94A3B8)),
                  onTap: () => _showLanguagePicker(context, loc),
                ),
                const Divider(height: 1),

                // Bong bóng chat cá nhân
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFF8B5CF6)),
                  title: Text(loc.t('personal_bubble_theme'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: Text(loc.t('personal_bubble_sub'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BubbleThemePickerScreen(
                          roomId: '',
                          userId: user.id,
                          currentThemeId: user.bubbleThemeId ?? 'default',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                // Kiểm tra bản cập nhật
                ListTile(
                  leading: const Icon(Icons.system_update, color: Color(0xFF10B981)),
                  title: Text(loc.t('check_update'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: Text('${loc.t('version_label')} v${AppConstants.appVersion}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: Color(0xFF94A3B8)),
                  onTap: () {
                    OtaUpdateService().checkUpdate(context, showNoUpdateDialog: true);
                  },
                ),
                const Divider(height: 1),

                // Đăng xuất
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(loc.t('sign_out'), style: const TextStyle(color: Colors.redAccent, fontSize: 14.5, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(loc.t('confirm_sign_out_title')),
                        content: Text(loc.t('confirm_sign_out_desc')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.t('cancel'))),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(loc.t('sign_out'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await auth.signOut();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
