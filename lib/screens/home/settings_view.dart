import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../settings/profile_edit_screen.dart';
import '../settings/privacy_security_screen.dart';
import '../../services/ota_update_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final user = auth.currentUser;
    final isDark = chatProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        children: [
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  AvatarWidget(
                    name: user.displayName,
                    photoUrl: user.photoUrl,
                    radius: 30,
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
                        const SizedBox(height: 4),
                        Text(
                          user.statusMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
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

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text('TÙY CHỈNH GIAO DIỆN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Chế Độ Tối (Dark Mode)'),
            subtitle: const Text('Giao diện tối giúp dịu mắt khi sử dụng ban đêm'),
            value: isDark,
            onChanged: (val) => chatProvider.toggleTheme(val),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Quyền Riêng Tư & Bảo Mật'),
            subtitle: const Text('Mã hóa đầu cuối E2EE & quản lý dữ liệu'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text('PHIÊN BẢN & CẬP NHẬT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt_outlined, color: Colors.teal),
            title: const Text('Kiểm Tra Cập Nhật (OTA)'),
            subtitle: const Text('Kiểm tra bản cập nhật mới nhất từ GitHub'),
            trailing: const Icon(Icons.refresh, size: 20),
            onTap: () {
              OtaUpdateService().checkUpdate(context, showNoUpdateDialog: true);
            },
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text('TÀI KHOẢN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng Xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận đăng xuất?'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản khỏi thiết bị này không?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Đăng Xuất'),
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
    );
  }
}
