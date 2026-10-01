import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/security_service.dart';
import '../../services/chat_service.dart';
import '../../providers/auth_provider.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _readReceipts = true;
  bool _lastSeen = true;
  final SecurityService _security = SecurityService();
  final ChatService _chatService = ChatService();

  void _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bộ nhớ đệm (Cache)?'),
        content: const Text('Thao tác này sẽ xóa các tệp tin tạm, ảnh thumbnail và giải phóng bộ nhớ trên thiết bị này.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa dữ liệu'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _security.clearLocalCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã dọn dẹp bộ nhớ đệm thành công!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền Riêng Tư & Bảo Mật')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'MÃ HÓA & BẢO VỆ DỮ LIỆU',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline, color: Colors.green),
            title: Text('Mã Hóa Đầu Cuối (E2EE)'),
            subtitle: Text('Tin nhắn được mã hóa phía máy khách bằng AES-256 trước khi gửi đi.'),
            trailing: Icon(Icons.verified, color: Colors.green, size: 20),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'QUYỀN RIÊNG TƯ CÁ NHÂN',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            value: _lastSeen,
            onChanged: (val) => setState(() => _lastSeen = val),
            title: const Text('Trạng Thái Hoạt Động (Last Seen)'),
            subtitle: const Text('Cho phép bạn bè thấy thời điểm bạn online gần nhất'),
          ),
          SwitchListTile(
            value: _readReceipts,
            onChanged: (val) => setState(() => _readReceipts = val),
            title: const Text('Thông Báo Đã Đọc (Đánh dấu tích xanh)'),
            subtitle: const Text('Hiện dấu tích xanh khi bạn đã đọc tin nhắn của người khác'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'TÌM KIẾM & KẾT BẠN',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              if (user == null) return const SizedBox.shrink();

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final allowName = data?['allowSearchByName'] ?? true;
                  final allowEmail = data?['allowSearchByEmail'] ?? true;
                  final allowId = data?['allowSearchById'] ?? true;
                  final blocked = List<String>.from(data?['blockedUsers'] ?? []);

                  return Column(
                    children: [
                      SwitchListTile(
                        value: allowName,
                        title: const Text('Cho phép tìm kiếm bằng Tên'),
                        subtitle: const Text('Người khác có thể tìm thấy bạn khi nhập tên'),
                        onChanged: (val) async {
                          await _chatService.updateSearchPrivacy(
                            currentUserId: user.uid,
                            allowSearchByName: val,
                          );
                        },
                      ),
                      SwitchListTile(
                        value: allowEmail,
                        title: const Text('Cho phép tìm kiếm bằng Gmail'),
                        subtitle: const Text('Người khác có thể tìm thấy bạn qua địa chỉ Gmail'),
                        onChanged: (val) async {
                          await _chatService.updateSearchPrivacy(
                            currentUserId: user.uid,
                            allowSearchByEmail: val,
                          );
                        },
                      ),
                      SwitchListTile(
                        value: allowId,
                        title: const Text('Cho phép tìm kiếm bằng ID cá nhân'),
                        subtitle: const Text('Người khác có thể tìm thấy bạn qua mã ID KINI'),
                        onChanged: (val) async {
                          await _chatService.updateSearchPrivacy(
                            currentUserId: user.uid,
                            allowSearchById: val,
                          );
                        },
                      ),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CHẶN TIN NHẮN & CUỘC GỌI',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.redAccent),
                        title: const Text('Danh sách đã chặn'),
                        subtitle: Text('${blocked.length} người dùng đang bị chặn'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showBlockedUsersDialog(context, user.uid, blocked);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'KIỂM SOÁT DỮ LIỆU THIẾT BỊ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orangeAccent),
            title: const Text('Dọn Dẹp Bộ Nhớ Đệm'),
            subtitle: const Text('Giải phóng dung lượng ổ đĩa và xóa tệp tạm trên máy'),
            onTap: _clearData,
          ),
        ],
      ),
    );
  }

  void _showBlockedUsersDialog(BuildContext context, String currentUserId, List<String> blockedIds) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        if (blockedIds.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('Bạn chưa chặn người dùng nào.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Danh Sách Đang Bị Chặn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: blockedIds.length,
                  itemBuilder: (context, index) {
                    final uid = blockedIds[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text('ID: $uid', style: const TextStyle(fontSize: 13)),
                      trailing: TextButton(
                        onPressed: () async {
                          await _chatService.unblockUser(currentUserId: currentUserId, targetUserId: uid);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã bỏ chặn người dùng')),
                            );
                          }
                        },
                        child: const Text('Bỏ chặn'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
