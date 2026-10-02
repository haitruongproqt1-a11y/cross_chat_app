import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/security_question_picker_sheet.dart';
import '../settings/profile_edit_screen.dart';
import '../../services/ota_update_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
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
        title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
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
                'Hồ sơ được xác thực qua tài khoản đăng nhập',
                style: TextStyle(
                  color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Thẻ thông tin cá nhân (Profile Card)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE0F2FE),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AvatarWidget(
                  name: user.displayName,
                  photoUrl: user.photoUrl,
                  radius: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${user.username.isNotEmpty ? user.username : user.email.split('@').first}',
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.edit_outlined, color: primaryColor, size: 20),
                  ),
                  tooltip: 'Chỉnh sửa hồ sơ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Bảo mật tài khoản
          const Text(
            'Bảo mật tài khoản',
            style: TextStyle(
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng nhập an toàn',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mật khẩu KINI được lưu dưới dạng mã băm.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                              const Text(
                                'Câu hỏi bảo mật',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
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
                        const Text(
                          'Cập nhật thông tin khôi phục',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hãy chọn câu hỏi mới và đặt câu trả lời bạn có thể ghi nhớ. Câu trả lời sẽ được mã hóa một chiều trước khi lưu.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
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
                            hintText: 'Câu trả lời mới',
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
                                : const Text('Lưu câu hỏi bảo mật', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text(
            'Thiết bị đăng nhập',
            style: TextStyle(
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
                    'KINI chỉ duy trì một thiết bị hoạt động tại một thời điểm.',
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
                      const SnackBar(content: Text('Đã cập nhật trạng thái phiên đăng nhập')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Cài đặt ứng dụng
          const Text(
            'Cài đặt hệ thống',
            style: TextStyle(
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
                SwitchListTile(
                  title: const Text('Giao diện tối (Dark Mode)', style: TextStyle(fontSize: 14.5)),
                  value: isDark,
                  onChanged: (val) => chatProvider.toggleTheme(val),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: primaryColor),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.system_update, color: Color(0xFF10B981)),
                  title: const Text('Kiểm tra bản cập nhật KINI', style: TextStyle(fontSize: 14.5)),
                  subtitle: const Text('Phiên bản v1.0.14', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    OtaUpdateService().checkUpdate(context, showNoUpdateDialog: true);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.redAccent, fontSize: 14.5, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi KINI CHAT?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent))),
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
